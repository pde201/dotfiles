# ──────────────────────────────────────────────────────────────────────
#  Developer-first Brewfile
#  Usage: brew bundle install --no-upgrade --file=Brewfile
#  Uses standard Homebrew prefixes, with ~/homebrew as no-sudo fallback.
# ──────────────────────────────────────────────────────────────────────

# ── Runtime / language management ────────────────────────────────────
brew "mise"                  # the one tool that replaces nvm/pyenv/sdkman/rbenv
brew "node"                  # npm runtime for AI coding CLIs (Claude Code, Codex)
brew "pi-coding-agent"       # pi CLI / TUI coding agent

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
brew "ast-grep"              # structural code search / rewrites
brew "tokei"                 # fast code statistics
brew "typos-cli"             # source-code spell checker
brew "taplo"                 # TOML formatter / language server
brew "watchexec"             # run commands when files change
brew "ouch"                  # one CLI for archives: zip/tar/gz/etc.
brew "tailspin"              # log highlighter (`tspin`)
brew "oha"                   # HTTP load testing

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
# brew "gnupg"               # removed — SSH signing / 1Password SSH agent covers our needs
#                              re-add if you need PGP commit signing or encrypted email

# ── Fonts (Nerd-Font patched for prompt glyphs) ──────────────────────
cask "font-jetbrains-mono-nerd-font"
cask "font-meslo-lg-nerd-font"
cask "font-caskaydia-cove-nerd-font"   # Cascadia Code NF
cask "font-caskaydia-mono-nerd-font"   # Cascadia Mono NF

# ── Apps (minimal dev + product-manager baseline) ───────────────────
# Standard brew installs to /Applications; userland fallback uses ~/Applications.

# Terminal / security
cask "ghostty"               # fast terminal
cask "warp"                  # AI-enabled terminal
cask "cmux"                  # terminal workspace for AI coding agents
cask "1password-cli"         # `op` CLI for secrets + SSH agent

# macOS workflow
cask "rectangle"             # keyboard-driven window management
cask "maccy"                 # lightweight clipboard history

# Collaboration / product work
cask "google-chrome"         # browser + web testing baseline
cask "firefox@developer-edition" # frontend debugging / cross-browser testing
cask "figma"                 # design and product collaboration
cask "slack"                 # team comms
cask "zoom"                  # meetings

# Backend / API work
cask "tableplus"             # fast database GUI
cask "redis-insight"         # Redis GUI / profiler
cask "yaak"                  # lightweight API client
cask "requestly"             # HTTP interceptor / API testing proxy

# AI work
cask "claude"                # Claude Desktop
cask "codex-app"             # OpenAI Codex desktop app
