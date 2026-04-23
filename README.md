# dotfiles — developer defaults

Opinionated, userland-friendly dev environment for macOS engineers. Installs Homebrew into `~/homebrew` (no sudo), pulls a curated set of CLI tools, and wires them up with good defaults.

## What you get

**Tools:** `mise`, `starship`, `zoxide`, `atuin`, `fzf`, `tealdeer`, `eza`, `bat`, `fd`, `ripgrep`, `sd`, `git-delta`, `difftastic`, `just`, `bottom`, `hyperfine`, `dust`, `procs`, `gping`, `gh`, `gitui`, `git-absorb`, `jq`, `yq`, `sqlite`, `httpie`, `xh`, `mkcert`, `awscli`, `gnupg`.

**Apps (casks → `~/Applications`, no sudo):** Ghostty, 1Password CLI, Claude, Bruno.

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

## What it does

1. Installs Homebrew to `~/homebrew` (no admin rights needed) if missing
2. Runs `brew bundle` against [`Brewfile`](Brewfile)
3. Symlinks:
   - `zsh/.zshrc` → `~/.zshrc`
   - `git/.gitconfig` → `~/.gitconfig`
   - `git/.gitignore_global` → `~/.gitignore_global`
   - `config/starship.toml` → `~/.config/starship.toml`
   - `config/bat` → `~/.config/bat`
   - `config/atuin` → `~/.config/atuin`
   - `config/mise` → `~/.config/mise`
4. Installs fzf keybindings (Ctrl-R for history, Ctrl-T for files, Alt-C for dirs)
5. Imports your existing shell history into atuin

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

- **Userland-first.** Zero sudo required for the base install. Casks ship to `~/Applications`.
- **Self-contained, non-magical.** Plain bash + symlinks. No stow, chezmoi, or Nix — you can read every line.
- **Overridable.** Every layer has a `.local` escape hatch.
- **Safe to re-run.** All steps idempotent; existing files backed up, never clobbered.

## Uninstall

```bash
# Remove everything brew installed
brew bundle cleanup --file=~/dotfiles/Brewfile --force

# Nuke brew itself (userland path — no sudo)
rm -rf ~/homebrew/{Cellar,Caskroom,Homebrew,bin,sbin,etc,opt,share,var,Library,lib,include}
# (or)  rm -rf ~/homebrew/*
```

## Extending

- **Add a tool:** append to `Brewfile`, re-run `./install.sh`.
- **Add a config:** drop file in `config/<app>/`, add a `link` line to `install.sh`.
- **Share with a teammate:** they clone the repo and run `./install.sh`. Done.
