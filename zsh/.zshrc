# ──────────────────────────────────────────────────────────────────────
#  ~/.zshrc — developer defaults
#  Managed by: ~/dotfiles/zsh/.zshrc (symlinked)
# ──────────────────────────────────────────────────────────────────────

# ── Homebrew (installer-selected prefix, with sensible fallback) ────
unset HOMEBREW_CASK_OPTS
[ -r "$HOME/.config/dotfiles/brew.zsh" ] && source "$HOME/.config/dotfiles/brew.zsh"

if [ -n "${DOTFILES_ACTIVE_BREW_PREFIX:-}" ] && [ -x "$DOTFILES_ACTIVE_BREW_PREFIX/bin/brew" ]; then
  eval "$("$DOTFILES_ACTIVE_BREW_PREFIX/bin/brew" shellenv)"
  [ "$DOTFILES_ACTIVE_BREW_PREFIX" = "$HOME/homebrew" ] && export HOMEBREW_CASK_OPTS="--appdir=$HOME/Applications"
elif [ -x "/opt/homebrew/bin/brew" ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x "/usr/local/bin/brew" ]; then
  eval "$(/usr/local/bin/brew shellenv)"
elif [ -x "$HOME/homebrew/bin/brew" ]; then
  eval "$($HOME/homebrew/bin/brew shellenv)"
  export HOMEBREW_CASK_OPTS="--appdir=$HOME/Applications"
fi

export HOMEBREW_NO_ANALYTICS=1
export HOMEBREW_NO_AUTO_UPDATE=1
export HOMEBREW_NO_ENV_HINTS=1

# ── PATH additions ───────────────────────────────────────────────────
typeset -U path
path=(
  "$HOME/.local/bin"
  "$HOME/.cargo/bin"
  "$HOME/.bun/bin"
  "$HOME/Library/pnpm"
  "$HOME/.npm-global/bin"
  "$HOME/.local/share/mise/shims"
  $path
)

# ── History (bigger, deduped, shared across sessions) ────────────────
HISTFILE="$HOME/.zsh_history"
HISTSIZE=100000
SAVEHIST=100000
setopt EXTENDED_HISTORY       # timestamps
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE      # don't record commands starting with space
setopt HIST_REDUCE_BLANKS
setopt HIST_VERIFY            # don't run recalled command immediately
setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY

# ── Completion ───────────────────────────────────────────────────────
autoload -Uz compinit && compinit -C
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'  # case-insensitive

# ── Keybindings ──────────────────────────────────────────────────────
bindkey -e                              # emacs mode — Ctrl-R invokes atuin

# ── Aliases: modern tool replacements ────────────────────────────────
if command -v eza >/dev/null; then
  alias ls='eza --group-directories-first --icons=auto'
  alias ll='eza -lh --git --group-directories-first --icons=auto'
  alias la='eza -lah --git --group-directories-first --icons=auto'
  alias tree='eza --tree --icons=auto'
fi

command -v bat >/dev/null && alias cat='bat --paging=never'
command -v fd  >/dev/null && alias find='fd'
command -v rg  >/dev/null && alias grep='rg'
command -v dust >/dev/null && alias du='dust'
command -v procs >/dev/null && alias ps='procs'
command -v btm >/dev/null && alias top='btm'
command -v delta >/dev/null && export GIT_PAGER='delta'

alias g='git'
alias gs='git status'
alias gd='git diff'
alias gl='git log --oneline --graph --decorate -20'
alias gc='git commit'
alias gca='git commit --amend --no-edit'
alias gp='git push'
alias gpl='git pull --rebase'
alias gco='git checkout'

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# ── Tool init (order matters — starship last) ────────────────────────
command -v mise     >/dev/null && eval "$(mise activate zsh)"
command -v zoxide   >/dev/null && eval "$(zoxide init zsh)"  # `z <dir>` fuzzy-jump, `zi` interactive, `cd` unchanged
command -v atuin    >/dev/null && eval "$(atuin init zsh)"  # ↑ and Ctrl-R both open atuin

# fzf keybindings (installed by install.sh via $(brew --prefix fzf)/install)
[ -f "$HOME/.fzf.zsh" ] && source "$HOME/.fzf.zsh"
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border --preview-window=right:60%:wrap'
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'

# Prompt last
command -v starship >/dev/null && eval "$(starship init zsh)"

# ── Local overrides (not tracked) ────────────────────────────────────
[ -f "$HOME/.zshrc.local" ] && source "$HOME/.zshrc.local"

if [ -n "${HOMEBREW_PREFIX:-}" ] && [ -f "$HOMEBREW_PREFIX/etc/ca-certificates/cert.pem" ]; then
  export NODE_EXTRA_CA_CERTS="$HOMEBREW_PREFIX/etc/ca-certificates/cert.pem"
fi
