#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────
#  Dotfiles installer
#
#  - Installs userland Homebrew at ~/homebrew if missing
#  - Runs `brew bundle` against Brewfile
#  - Symlinks configs into ~/.config, ~/.zshrc, ~/.gitconfig, etc.
#  - Idempotent — safe to re-run
# ──────────────────────────────────────────────────────────────────────
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BREW_PREFIX="${HOMEBREW_PREFIX:-$HOME/homebrew}"
BACKUP="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"

say() { printf "\033[1;34m▸\033[0m %s\n" "$*"; }
ok()  { printf "  \033[32m✓\033[0m %s\n" "$*"; }
warn(){ printf "  \033[33m!\033[0m %s\n" "$*"; }

# ── 1. Userland Homebrew ─────────────────────────────────────────────
if [ ! -x "$BREW_PREFIX/bin/brew" ]; then
  say "Installing userland Homebrew → $BREW_PREFIX"
  mkdir -p "$BREW_PREFIX"
  curl -fsSL https://github.com/Homebrew/brew/tarball/main \
    | tar xz --strip 1 -C "$BREW_PREFIX"
  ok "brew installed"
else
  ok "brew already present at $BREW_PREFIX"
fi

eval "$("$BREW_PREFIX/bin/brew" shellenv)"
export HOMEBREW_NO_ANALYTICS=1
export HOMEBREW_NO_AUTO_UPDATE=1
export HOMEBREW_CASK_OPTS="--appdir=$HOME/Applications"
mkdir -p "$HOME/Applications"

# ── 2. Brew bundle ───────────────────────────────────────────────────
say "Installing formulas & casks from Brewfile"
"$BREW_PREFIX/bin/brew" bundle --file="$DOTFILES/Brewfile" --no-lock

# ── 3. Symlink dotfiles ──────────────────────────────────────────────
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

# ── 4. FZF shell integration ─────────────────────────────────────────
if command -v fzf >/dev/null 2>&1; then
  say "Installing fzf keybindings & completion"
  "$BREW_PREFIX/opt/fzf/install" --key-bindings --completion --no-update-rc --no-bash --no-fish >/dev/null
  ok "fzf ready (Ctrl-R, Ctrl-T, Alt-C)"
fi

# ── 5. Atuin import ──────────────────────────────────────────────────
if command -v atuin >/dev/null 2>&1 && [ ! -d "$HOME/.local/share/atuin" ]; then
  say "Importing shell history into atuin"
  atuin import auto || warn "atuin import skipped (no prior history)"
fi

# ── 6. Next steps ────────────────────────────────────────────────────
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

  Backups (if any):   $BACKUP
────────────────────────────────────────────────────────────────────
EOF
