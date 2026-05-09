# dotfiles — developer defaults

Opinionated dev environment for macOS engineers. Uses the standard Homebrew install (`/opt/homebrew` on Apple Silicon, `/usr/local` on Intel) when sudo/admin access is available, falling back to userland Homebrew at `~/homebrew` only when sudo is unavailable.

## What you get

**Tools:** `mise`, `node`, `pi`, `starship`, `zoxide`, `atuin`, `fzf`, `tealdeer`, `eza`, `bat`, `fd`, `ripgrep`, `sd`, `git-delta`, `difftastic`, `just`, `ast-grep`, `tokei`, `typos-cli`, `taplo`, `watchexec`, `ouch`, `tailspin`, `oha`, `bottom`, `hyperfine`, `dust`, `procs`, `gping`, `gh`, `gitui`, `git-absorb`, `jq`, `yq`, `sqlite`, `httpie`, `xh`, `mkcert`, `awscli`.

**Apps:** Minimal dev/product baseline: Ghostty, Warp, cmux, 1Password CLI, Rectangle, Maccy, Chrome, Firefox Developer Edition, Figma, Slack, Zoom, TablePlus, Redis Insight, Yaak, Requestly, Claude Desktop, and Codex (`/Applications` with standard Homebrew, `~/Applications` for no-sudo fallback).

**AI coding tools:** pi (`pi`) via Homebrew, Claude Code (`claude`) and OpenAI Codex (`codex`) via npm globals, plus Claude Desktop and Codex desktop apps.

**Fonts (Nerd-Font patched):** JetBrains Mono, MesloLGS, Cascadia Code, Cascadia Mono.

**Configs:** zshrc with sensible history + aliases, Starship prompt with project-aware runtime context, Git with delta pager + rerere + safer defaults, bat/atuin/mise dialed in.

## Install

```bash
git clone <this-repo> ~/dotfiles
cd ~/dotfiles
./install.sh
exec zsh -l
```

The installer is idempotent — safe to re-run after you edit anything here.

Optional Homebrew mode override:

```bash
DOTFILES_BREW_MODE=standard ./install.sh      # require official Homebrew; fail without sudo
DOTFILES_BREW_MODE=userland ./install.sh      # force ~/homebrew
DOTFILES_CLEAN_USERLAND_BREW=1 ./install.sh  # after standard brew succeeds, remove old ~/homebrew
DOTFILES_UPDATE_NPM_GLOBALS=1 ./install.sh   # update Claude Code and Codex CLIs
```

Default is `DOTFILES_BREW_MODE=auto`: standard Homebrew first, userland only when sudo is unavailable. Auto mode may prompt once to check sudo access; if sudo is unavailable/non-interactive, it falls back to userland. Cleanup is opt-in and only runs when standard Homebrew is active; it uninstalls casks tracked by the old userland brew, removes `~/homebrew`, removes `~/Applications` only if empty, then re-applies the Brewfile to restore any shared cask artifacts such as fonts. If cleanup is not enabled, the installer leaves old userland brew in place and prints a warning. AI CLIs are installed if missing; set `DOTFILES_UPDATE_NPM_GLOBALS=1` to update npm-managed CLIs.

## What it does

1. Uses standard Homebrew (`/opt/homebrew` or `/usr/local`) when sudo is available; otherwise falls back to `~/homebrew`
2. Writes the active brew prefix to `~/.config/dotfiles/brew.zsh` so shell startup uses the same choice
3. Runs `brew bundle install --no-upgrade` against [`Brewfile`](Brewfile) to install missing items without surprise upgrades
4. Installs missing npm-managed AI coding CLIs: Claude Code and Codex
5. Optionally removes old userland Homebrew when `DOTFILES_CLEAN_USERLAND_BREW=1`
6. Symlinks:
   - `zsh/.zshrc` → `~/.zshrc`
   - `git/.gitconfig` → `~/.gitconfig`
   - `git/.gitignore_global` → `~/.gitignore_global`
   - `config/starship.toml` → `~/.config/starship.toml`
   - `config/bat` → `~/.config/bat`
   - `config/atuin` → `~/.config/atuin`
   - `config/mise` → `~/.config/mise`
7. Installs fzf keybindings (Ctrl-R for history, Ctrl-T for files, Alt-C for dirs)
8. Imports your existing shell history into atuin

Existing files are backed up to `~/.dotfiles-backup-<timestamp>/` before symlinks are placed.

## Per-machine customization

Keep machine-specific settings out of the repo:

- `~/.zshrc.local` — auto-sourced at end of zshrc (work laptop vs personal, extra PATH, private aliases)
- `~/.gitconfig.local` — auto-included by gitconfig (different `user.email` per machine, work signing key, etc.)

## After install

```bash
# Configure your terminal's font to one of:
#   CaskaydiaCove Nerd Font
#   JetBrainsMono Nerd Font
#   MesloLGS Nerd Font

# Enable atuin history sync (optional, encrypted):
atuin register -u <username>
```

## Design principles

- **Standard Homebrew first.** Uses official macOS Homebrew locations and `/Applications` when admin access is available; falls back to `~/homebrew` only without sudo.
- **Self-contained, non-magical.** Plain bash + symlinks. No stow, chezmoi, or Nix — you can read every line.
- **Overridable.** Every layer has a `.local` escape hatch.
- **Safe to re-run.** All steps idempotent; existing files backed up, never clobbered.

## Uninstall

```bash
# Remove everything brew installed
brew bundle cleanup --file=~/dotfiles/Brewfile --force

# Remove Homebrew itself (optional)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)"

# If you previously used the old userland install and no longer need it:
rm -rf ~/homebrew
```

## Extending

- **Add a tool:** append to `Brewfile`, re-run `./install.sh`.
- **Add a config:** drop file in `config/<app>/`, add a `link` line to `install.sh`.
- **Share with a teammate:** they clone the repo and run `./install.sh`. Done.
