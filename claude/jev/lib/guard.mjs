// ──────────────────────────────────────────────────────────────────────
//  Catch tool calls that are about to go wrong, before they run.
//
//  Two layers, in this order:
//
//    1. Code, for everything that is knowable. Does the file exist? Is the
//       string being replaced actually in it? Is this `rm -rf /`? These are
//       lookups and rules, not judgments, and a model should never be asked
//       a question that `existsSync` already answers.
//
//    2. Jev, for the rest. Whether a command matches what was actually
//       asked for, whether it is the same thing that just failed, whether
//       it destroys something nobody asked to destroy — these need semantic
//       understanding of the session, and no amount of pattern matching
//       gets there.
//
//  Fails open: no key, no network, bad response — the call proceeds.
// ──────────────────────────────────────────────────────────────────────

import { existsSync, readFileSync, statSync } from "node:fs";
import { systemOne, noul, score, nouls, pickScore, costUsd, haveKey } from "./client.mjs";
import config from "./config.mjs";

export const ALLOW = "allow";
export const ASK = "ask";
export const DENY = "deny";

// Precedence when several signals fire at once: the strictest wins.
const PRECEDENCE = [DENY, ASK, ALLOW];
const strictest = (decisions) => PRECEDENCE.find((d) => decisions.includes(d)) ?? ALLOW;

// ── Layer 1: deterministic ───────────────────────────────────────────

// Patterns that are catastrophic regardless of intent. Short, and every
// entry earns its place — this is not a general-purpose linter.
const CATASTROPHIC = [
  { re: /\brm\s+(-[a-zA-Z]*\s+)*-?[a-zA-Z]*[rf][a-zA-Z]*\s+\/(\s|$)/, why: "recursive delete of /" },
  { re: /\brm\s+-[a-zA-Z]*r[a-zA-Z]*f?\s+(~|\$HOME)(\/\s*)?(\s|$)/, why: "recursive delete of the home directory" },
  { re: /\bgit\s+push\b[^|;&]*--force(?!-with-lease)/, why: "force push without --force-with-lease" },
  { re: /\bgit\s+(reset\s+--hard|clean\s+-[a-zA-Z]*f)/, why: "discards uncommitted work irreversibly" },
  { re: /\b(mkfs|dd\s+if=[^\s]+\s+of=\/dev\/)/, why: "writes directly to a device" },
  { re: /\bchmod\s+-R\s+777\s+\//, why: "recursive permission change from the filesystem root" },
  { re: /:\s*\(\s*\)\s*\{\s*:\s*\|\s*:/, why: "fork bomb" },
  { re: /\bDROP\s+(TABLE|DATABASE|SCHEMA)\b/i, why: "destructive SQL" },
  { re: /\bcurl\b[^|]*\|\s*(sudo\s+)?(ba)?sh\b/, why: "pipes a downloaded script straight into a shell" },
];

/**
 * Checks that need no judgment at all. Returns a decision, or null to hand
 * the call on to Jev.
 */
export function deterministicCheck(toolName, input, cwd) {
  if (toolName === "Edit") {
    const path = input?.file_path;
    if (typeof path === "string" && typeof input?.old_string === "string") {
      if (!existsSync(path)) {
        return { decision: DENY, reason: `${path} does not exist, so there is nothing to edit.`, by: "code" };
      }
      let body;
      try {
        body = readFileSync(path, "utf8");
      } catch (err) {
        return { decision: ASK, reason: `${path} could not be read: ${err.code ?? err.message}`, by: "code" };
      }
      if (input.old_string && !body.includes(input.old_string)) {
        return {
          decision: DENY,
          reason: `The text to replace does not appear in ${path}. Re-read the file and match its current contents exactly.`,
          by: "code",
        };
      }
      if (input.old_string && !input.replace_all) {
        const count = body.split(input.old_string).length - 1;
        if (count > 1) {
          return {
            decision: DENY,
            reason: `That text appears ${count} times in ${path}. Include more surrounding context to make it unique, or set replace_all.`,
            by: "code",
          };
        }
      }
    }
  }

  if (toolName === "Read" && typeof input?.file_path === "string") {
    const path = input.file_path;
    if (!existsSync(path)) {
      return { decision: DENY, reason: `${path} does not exist.`, by: "code" };
    }
    try {
      if (statSync(path).isDirectory()) {
        return { decision: DENY, reason: `${path} is a directory, not a file. Use a listing or glob instead.`, by: "code" };
      }
    } catch {
      // Raced with something else; let it through and let the tool report.
    }
  }

  if (toolName === "Bash" && typeof input?.command === "string") {
    for (const { re, why } of CATASTROPHIC) {
      if (re.test(input.command)) {
        return { decision: ASK, reason: `This ${why}. Confirm before it runs.`, by: "code" };
      }
    }
  }

  return null;
}

// ── Layer 2: judgment ────────────────────────────────────────────────

const HAZARDS = {
  intent_mismatch: {
    action: ASK,
    question: noul(
      "Does the tool call in `call` do something materially different from what `task` asked for? Judge the substance, not the wording: an intermediate step that plainly serves the task is not a mismatch.",
      {
        true: "It would do something the task neither asked for nor needs",
        false: "It is the task itself, or a reasonable step toward it",
      },
    ),
  },
  repeat_failure: {
    action: ASK,
    question: noul(
      "Is the tool call in `call` essentially the same as one in `recent_calls` that already failed, without addressing why it failed?",
      {
        true: "It repeats a call that just failed, with no change that would fix the cause",
        false: "It is a different call, or a corrected version of the failed one",
      },
    ),
  },
  destructive_unrequested: {
    action: DENY,
    question: noul(
      "Would the tool call in `call` irreversibly delete, overwrite or discard something that `task` did not ask to be changed?",
      {
        true: "It destroys work or data that nobody asked to remove, and it cannot be undone",
        false: "It changes nothing irreversibly, or it destroys exactly what was asked for",
      },
    ),
  },
  secret_exposure: {
    action: DENY,
    question: noul(
      "Would the tool call in `call` print, copy or transmit a credential, token, private key or password?",
      {
        true: "It would expose secret material, for example by printing a key file or posting a token",
        false: "It touches no secret material, or only references a variable name without revealing its value",
      },
    ),
  },
  wrong_scope: {
    action: ASK,
    question: noul(
      "Does the tool call in `call` reach outside the working directory in `cwd` to change something, when `task` gave no reason to?",
      {
        true: "It writes to or alters something outside the project, unprompted",
        false: "It stays within the project, only reads outside it, or was asked to reach outside",
      },
    ),
  },
  invented_target: {
    action: ASK,
    question: noul(
      "Does the tool call in `call` name a file or directory that has not been seen in this session and was not named in `task`?",
      {
        true: "It refers to a path that has not been observed to exist and nobody mentioned",
        false: "The path was observed, was named by the user, or is being created deliberately",
      },
    ),
  },
};

const BLAST_RADIUS = [
  "Reads or inspects only; nothing is changed",
  "Changes one file or a small set of files inside the project",
  "Changes the project broadly: many files, dependencies, or version control history",
  "Changes something outside the project on this machine, or sends data to a network service",
  "Changes shared or production state that other people depend on",
];

export function guardQuestions() {
  const questions = { blast_radius: score("How far do the effects of the tool call in `call` reach?", BLAST_RADIUS) };
  for (const [id, { question }] of Object.entries(HAZARDS)) questions[id] = question;
  return questions;
}

/**
 * @returns {Promise<{decision: string, reason: string, by: string, signals?: object, cost?: number}>}
 */
export async function guard({ toolName, input, cwd, task, recentCalls, observed, model } = {}) {
  const pass = (reason) => ({ decision: ALLOW, reason, by: "code" });

  const deterministic = deterministicCheck(toolName, input, cwd);
  if (deterministic) return deterministic;

  if (!config.guard) return pass("guard disabled");
  if (!haveKey()) return pass("no api key");

  let res;
  try {
    res = await systemOne({
      model: model ?? config.model,
      state: {
        task: task || "(not stated)",
        cwd: cwd || process.cwd(),
        call: { tool: toolName, input },
        recent_calls: recentCalls ?? [],
        paths_seen_this_session: observed ?? [],
      },
      questions: guardQuestions(),
    });
  } catch (err) {
    return pass(`jev unavailable: ${err.message}`);
  }

  const probabilities = nouls(res, Object.keys(HAZARDS));
  const radius = pickScore(res, "blast_radius");
  const triggered = [];
  const fired = {};

  for (const [hazard, probability] of Object.entries(probabilities)) {
    const intended = HAZARDS[hazard].action;
    if (probability >= config.guardDenyAt) {
      triggered.push(intended);
      fired[hazard] = probability;
    } else if (probability >= config.guardAskAt) {
      triggered.push(ASK);
      fired[hazard] = probability;
    }
  }

  // Reach is a multiplier, not a hazard of its own: something already
  // suspicious that also touches shared state is not a question to wave
  // through, but a wide-reaching call that trips nothing is just a deploy.
  const wideReaching = (radius?.score ?? 0) >= config.guardBlastRadiusBlock;
  const decision = wideReaching && triggered.length
    ? strictest(triggered.map((d) => (d === ASK ? DENY : d)))
    : strictest(triggered);

  return {
    decision,
    reason: explain(fired, radius, decision),
    by: "jev",
    signals: { ...fired, blast_radius: radius?.score, blast_radius_label: radius?.legend?.[String(Math.round(radius?.score ?? 0))] },
    usage: res.usage,
    cost: costUsd(res.usage),
  };
}

const PHRASING = {
  intent_mismatch: "does not match what was asked for",
  repeat_failure: "repeats a call that just failed, unchanged",
  destructive_unrequested: "irreversibly destroys something nobody asked to change",
  secret_exposure: "would expose credentials",
  wrong_scope: "reaches outside the project unprompted",
  invented_target: "names a path that has not been seen in this session",
};

function explain(fired, radius, decision) {
  if (decision === ALLOW) return "";
  const parts = Object.entries(fired)
    .sort((a, b) => b[1] - a[1])
    .map(([hazard, p]) => `${PHRASING[hazard]} (${p.toFixed(2)})`);
  const reach = radius?.legend?.[String(Math.round(radius.score))];
  const tail = reach ? ` Reach: ${reach.toLowerCase()}.` : "";
  return `This call ${parts.join("; ")}.${tail}`;
}
