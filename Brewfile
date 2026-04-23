# ──────────────────────────────────────────────────────────────────────
#  Developer-first Brewfile
#  Usage: brew bundle --file=Brewfile
#  Works with userland brew (~/homebrew) or /opt/homebrew.
# ──────────────────────────────────────────────────────────────────────

# ── Runtime / language management ────────────────────────────────────
brew "mise"                  # the one tool that replaces nvm/pyenv/sdkman/rbenv

# ── Shell / prompt / history / launcher ──────────────────────────────
brew "starship"              # cross-shell prompt with project context
brew "zoxide"                # smarter `cd` — jumps to frecent dirs
brew "atuin"                 # encrypted, searchable shell history
brew "fzf"                   # fuzzy finder (Ctrl-R, Ctrl-T, Alt-C)
brew "tealdeer"              # fast `tldr` pages

# ── Rust-powered file & text utilities ───────────────────────────────
brew "eza"                   # modern `ls` with git + icon support
brew "bat"                   # `cat` with syntax highlighting & paging
brew "fd"                    # modern `find`
brew "ripgrep"               # modern `grep`
brew "sd"                    # modern `sed`
brew "git-delta"             # beautiful git diff pager
brew "difftastic"            # structural (AST-aware) diffs
brew "just"                  # command runner (saner `make`)

# ── Observability ────────────────────────────────────────────────────
brew "bottom"                # `btm` — system monitor
brew "hyperfine"             # CLI benchmarking
brew "dust"                  # `du` replacement — visual disk usage
brew "procs"                 # `ps` replacement
brew "gping"                 # ping with a graph

# ── Git / GitHub ─────────────────────────────────────────────────────
brew "gh"                    # GitHub CLI
brew "gitui"                 # fast terminal UI for git
brew "git-absorb"            # auto-fixup commits by blame

# ── Data / JSON / YAML ───────────────────────────────────────────────
brew "jq"                    # JSON processor
brew "yq"                    # YAML/XML/TOML processor
brew "sqlite"

# ── HTTP / network / TLS ─────────────────────────────────────────────
brew "httpie"                # human-friendly curl
brew "xh"                    # httpie in Rust (faster, same UX)
brew "mkcert"                # local HTTPS CA (no sudo for certs in user trust store)

# ── Cloud / infra ────────────────────────────────────────────────────
brew "awscli"

# ── Security / signing ───────────────────────────────────────────────
brew "gnupg"                 # commit signing, secret decryption

# ── Fonts (Nerd-Font patched for prompt glyphs) ──────────────────────
cask "font-jetbrains-mono-nerd-font"
cask "font-meslo-lg-nerd-font"
cask "font-caskaydia-cove-nerd-font"   # Cascadia Code NF
cask "font-caskaydia-mono-nerd-font"   # Cascadia Mono NF

# ── Dev apps (GUI casks) ─────────────────────────────────────────────
# HOMEBREW_CASK_OPTS="--appdir=$HOME/Applications" in .zshrc puts these
# in ~/Applications so no sudo is required.
cask "ghostty"               # primary terminal
cask "1password-cli"         # `op` CLI for secrets + SSH agent
cask "claude"                # Claude Desktop
cask "bruno"                 # open-source Postman alternative
