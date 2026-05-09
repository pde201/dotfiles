#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────
#  Dotfiles installer
#
#  - Uses standard Homebrew when sudo is available
#    (/opt/homebrew on Apple Silicon, /usr/local on Intel)
#  - Falls back to userland Homebrew at ~/homebrew when sudo is unavailable
#  - Runs `brew bundle install --no-upgrade` against Brewfile
#  - Installs AI coding CLIs: Claude Code and Codex (pi comes from Homebrew)
#  - Symlinks configs into ~/.config, ~/.zshrc, ~/.gitconfig, etc.
#  - Idempotent — safe to re-run
# ──────────────────────────────────────────────────────────────────────
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ "$(uname -m)" = "arm64" ]; then
  STANDARD_BREW_PREFIX="/opt/homebrew"
else
  STANDARD_BREW_PREFIX="/usr/local"
fi

USERLAND_BREW_PREFIX="$HOME/homebrew"
BREW_MODE="${DOTFILES_BREW_MODE:-auto}" # auto | standard | userland
CLEAN_USERLAND_BREW="${DOTFILES_CLEAN_USERLAND_BREW:-0}" # 1 removes old ~/homebrew after standard brew succeeds
UPDATE_NPM_GLOBALS="${DOTFILES_UPDATE_NPM_GLOBALS:-0}" # 1 updates Claude Code and Codex
BREW_PREFIX="$STANDARD_BREW_PREFIX"
CLEANED_USERLAND_BREW=0
BACKUP="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"

say() { printf "\033[1;34m▸\033[0m %s\n" "$*"; }
ok()  { printf "  \033[32m✓\033[0m %s\n" "$*"; }
warn(){ printf "  \033[33m!\033[0m %s\n" "$*"; }

# ── 1. Homebrew ──────────────────────────────────────────────────────
can_sudo() {
  sudo -n true 2>/dev/null && return 0
  [ -t 0 ] || return 1
  say "Checking sudo access (may prompt once)"
  sudo -v
}

install_standard_brew() {
  say "Installing Homebrew → $STANDARD_BREW_PREFIX"
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  BREW_PREFIX="$STANDARD_BREW_PREFIX"
  ok "brew installed"
}

install_userland_brew() {
  BREW_PREFIX="$USERLAND_BREW_PREFIX"
  say "Installing userland Homebrew → $BREW_PREFIX"
  mkdir -p "$BREW_PREFIX"
  curl -fsSL https://github.com/Homebrew/brew/tarball/main \
    | tar xz --strip 1 -C "$BREW_PREFIX"
  ok "brew installed"
}

case "$BREW_MODE" in
  auto|standard|userland) ;;
  *) warn "invalid DOTFILES_BREW_MODE=$BREW_MODE (use auto, standard, or userland)"; exit 1 ;;
esac

case "$CLEAN_USERLAND_BREW" in
  0|1) ;;
  *) warn "invalid DOTFILES_CLEAN_USERLAND_BREW=$CLEAN_USERLAND_BREW (use 0 or 1)"; exit 1 ;;
esac

case "$UPDATE_NPM_GLOBALS" in
  0|1) ;;
  *) warn "invalid DOTFILES_UPDATE_NPM_GLOBALS=$UPDATE_NPM_GLOBALS (use 0 or 1)"; exit 1 ;;
esac

SUDO_AVAILABLE=0
if [ "$BREW_MODE" != "userland" ] && can_sudo; then
  SUDO_AVAILABLE=1
fi

if [ "$BREW_MODE" = "userland" ]; then
  if [ -x "$USERLAND_BREW_PREFIX/bin/brew" ]; then
    BREW_PREFIX="$USERLAND_BREW_PREFIX"
    ok "brew already present at $BREW_PREFIX"
  else
    install_userland_brew
  fi
elif [ "$BREW_MODE" = "standard" ]; then
  if [ "$SUDO_AVAILABLE" != "1" ]; then
    warn "standard Homebrew requested but sudo is unavailable"
    exit 1
  elif [ -x "$STANDARD_BREW_PREFIX/bin/brew" ]; then
    BREW_PREFIX="$STANDARD_BREW_PREFIX"
    ok "brew already present at $BREW_PREFIX"
  else
    install_standard_brew
  fi
elif [ "$SUDO_AVAILABLE" = "1" ]; then
  if [ -x "$STANDARD_BREW_PREFIX/bin/brew" ]; then
    BREW_PREFIX="$STANDARD_BREW_PREFIX"
    ok "brew already present at $BREW_PREFIX"
  else
    install_standard_brew
  fi
elif [ -x "$USERLAND_BREW_PREFIX/bin/brew" ]; then
  BREW_PREFIX="$USERLAND_BREW_PREFIX"
  ok "brew already present at $BREW_PREFIX"
else
  warn "sudo unavailable; falling back to userland Homebrew"
  install_userland_brew
fi

eval "$("$BREW_PREFIX/bin/brew" shellenv)"
mkdir -p "$HOME/.config/dotfiles"
printf 'DOTFILES_ACTIVE_BREW_PREFIX=%q\n' "$BREW_PREFIX" > "$HOME/.config/dotfiles/brew.zsh"
export HOMEBREW_NO_ANALYTICS=1
export HOMEBREW_NO_AUTO_UPDATE=1
if [ "$BREW_PREFIX" = "$USERLAND_BREW_PREFIX" ]; then
  export HOMEBREW_CASK_OPTS="--appdir=$HOME/Applications"
  mkdir -p "$HOME/Applications"
else
  unset HOMEBREW_CASK_OPTS
fi

brew_bundle_install() {
  "$BREW_PREFIX/bin/brew" bundle install --no-upgrade --file="$DOTFILES/Brewfile"
}

# ── 2. Brew bundle ───────────────────────────────────────────────────
say "Installing missing formulas & casks from Brewfile"
brew_bundle_install

# ── 3. AI coding CLIs ────────────────────────────────────────────────
install_npm_global_clis() {
  if ! command -v npm >/dev/null 2>&1; then
    warn "npm not found; skipping AI coding CLIs"
    return 0
  fi

  local specs spec pkg bin bin_path
  specs=(
    "@anthropic-ai/claude-code:claude"
    "@openai/codex:codex"
  )

  for spec in "${specs[@]}"; do
    pkg="${spec%:*}"
    bin="${spec##*:}"

    if npm list -g --depth=0 "$pkg" >/dev/null 2>&1; then
      if [ "$UPDATE_NPM_GLOBALS" = "1" ]; then
        say "Updating $bin ($pkg)"
        npm_config_audit=false npm_config_fund=false npm install -g "$pkg"
      else
        ok "$bin already installed"
      fi
      continue
    fi

    if bin_path="$(command -v "$bin" 2>/dev/null)"; then
      warn "$bin already exists at $bin_path; skipping npm install for $pkg"
      continue
    fi

    say "Installing $bin ($pkg)"
    npm_config_audit=false npm_config_fund=false npm install -g "$pkg"
  done
}

install_npm_global_clis

# ── 4. Optional userland cleanup ─────────────────────────────────────
userland_brew() {
  env -u HOMEBREW_PREFIX -u HOMEBREW_CELLAR -u HOMEBREW_REPOSITORY \
    HOMEBREW_CASK_OPTS="--appdir=$HOME/Applications" \
    "$USERLAND_BREW_PREFIX/bin/brew" "$@"
}

cleanup_userland_brew() {
  [ "$CLEAN_USERLAND_BREW" = "1" ] || return 0

  if [ "$BREW_PREFIX" = "$USERLAND_BREW_PREFIX" ]; then
    warn "skipping userland cleanup because userland brew is active"
    return 0
  fi

  if [ ! -e "$USERLAND_BREW_PREFIX" ]; then
    ok "no userland Homebrew found"
    return 0
  fi

  say "Removing old userland Homebrew → $USERLAND_BREW_PREFIX"
  if [ -x "$USERLAND_BREW_PREFIX/bin/brew" ]; then
    local casks cask
    casks="$(userland_brew list --cask 2>/dev/null || true)"
    while IFS= read -r cask; do
      [ -n "$cask" ] || continue
      userland_brew uninstall --cask --force "$cask" || warn "failed to uninstall userland cask: $cask"
    done <<< "$casks"
  fi

  rm -rf "$USERLAND_BREW_PREFIX"
  rmdir "$HOME/Applications" 2>/dev/null || true
  CLEANED_USERLAND_BREW=1
  ok "removed old userland Homebrew"
}

cleanup_userland_brew
if [ "$CLEANED_USERLAND_BREW" = "1" ]; then
  say "Re-applying Brewfile after cleanup"
  brew_bundle_install
elif [ "$BREW_PREFIX" != "$USERLAND_BREW_PREFIX" ] && [ -e "$USERLAND_BREW_PREFIX" ]; then
  warn "old userland Homebrew still exists; remove it with DOTFILES_CLEAN_USERLAND_BREW=1"
fi

# ── 5. Symlink dotfiles ──────────────────────────────────────────────
link() {
  local src="$1" dst="$2"
  if [ -e "$dst" ] && [ ! -L "$dst" ]; then
    mkdir -p "$BACKUP"
    mv "$dst" "$BACKUP/$(basename "$dst")"
    warn "backed up existing $dst → $BACKUP/"
  fi
  mkdir -p "$(dirname "$dst")"
  ln -sfn "$src" "$dst"
  ok "linked $dst"
}

say "Symlinking dotfiles"
link "$DOTFILES/zsh/.zshrc"            "$HOME/.zshrc"
link "$DOTFILES/git/.gitconfig"        "$HOME/.gitconfig"
link "$DOTFILES/git/.gitignore_global" "$HOME/.gitignore_global"
link "$DOTFILES/config/starship.toml"  "$HOME/.config/starship.toml"
link "$DOTFILES/config/bat"            "$HOME/.config/bat"
link "$DOTFILES/config/atuin"          "$HOME/.config/atuin"
link "$DOTFILES/config/mise"           "$HOME/.config/mise"

# ── 6. FZF shell integration ─────────────────────────────────────────
if command -v fzf >/dev/null 2>&1; then
  say "Installing fzf keybindings & completion"
  "$BREW_PREFIX/opt/fzf/install" --key-bindings --completion --no-update-rc --no-bash --no-fish >/dev/null
  ok "fzf ready (Ctrl-R, Ctrl-T, Alt-C)"
fi

# ── 7. Atuin import ──────────────────────────────────────────────────
if command -v atuin >/dev/null 2>&1 && [ ! -d "$HOME/.local/share/atuin" ]; then
  say "Importing shell history into atuin"
  atuin import auto || warn "atuin import skipped (no prior history)"
fi

# ── 8. Next steps ────────────────────────────────────────────────────
cat <<EOF

────────────────────────────────────────────────────────────────────
  ✅ Dotfiles installed.

  Next:
    1. Restart your shell or run:   exec zsh -l
    2. In Ghostty/Warp/Kitty, set font to one of:
         CaskaydiaCove Nerd Font
         JetBrainsMono Nerd Font
         MesloLGS Nerd Font
    3. Optional: atuin register -u <you>   # enable encrypted history sync
    4. Sign in/configure AI tools as needed: claude, codex, pi, Codex.app

  Backups (if any):   $BACKUP
────────────────────────────────────────────────────────────────────
EOF
