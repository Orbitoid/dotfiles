#!/usr/bin/env bash
# Install (or refresh) these dotfiles. Safe to re-run.
#
#   ./install.sh                 install packages, then link configs
#   ./install.sh --no-packages   only link configs and fetch plugins
#
# Supports macOS (Homebrew), Arch/CachyOS (pacman), Debian/Ubuntu/Mint (apt),
# Fedora (dnf), and immutable distros like SteamOS and Bazzite (Homebrew).
# Existing files that would be replaced are renamed to *.bak.<timestamp>.

set -euo pipefail

DOT="$(cd "$(dirname "$0")" && pwd)"
STAMP="$(date +%Y%m%d%H%M%S)"
CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}"
LOCAL_BIN="$HOME/.local/bin"
MIN_NVIM="0.11.0"

say()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*" >&2; }
have() { command -v "$1" >/dev/null 2>&1; }

sudo_() { if [ "$(id -u)" -eq 0 ]; then "$@"; else sudo "$@"; fi; }

# ver_ge A B: is version A >= B?
ver_ge() { [ "$(printf '%s\n%s\n' "$2" "$1" | sort -V | head -n1)" = "$2" ]; }

# --- Packages -----------------------------------------------------------------

ensure_brew() {
    have brew && return
    for b in /opt/homebrew/bin/brew /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do
        if [ -x "$b" ]; then eval "$("$b" shellenv)"; return; fi
    done
    say "Installing Homebrew"
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    for b in /opt/homebrew/bin/brew /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do
        if [ -x "$b" ]; then eval "$("$b" shellenv)"; return; fi
    done
}

install_brew() {
    ensure_brew
    local pkgs="git tmux fish neovim ripgrep fd node gitleaks"
    [ "$(uname -s)" = Linux ] && pkgs="$pkgs gcc make unzip"
    say "brew install $pkgs"
    # shellcheck disable=SC2086
    brew install $pkgs
    brew install tree-sitter-cli || warn "tree-sitter-cli not installed via brew; will try the release binary"
}

install_packages() {
    if [ "$(uname -s)" = Darwin ]; then
        xcode-select -p >/dev/null 2>&1 || xcode-select --install || true
        install_brew
        return
    fi

    local id=""
    # shellcheck disable=SC1091
    [ -r /etc/os-release ] && id="$(. /etc/os-release && echo "${ID:-}")"

    # Immutable systems: the root filesystem is read-only or reset on update.
    case "$id" in
        steamos|bazzite|bluefin|aurora) install_brew; return ;;
    esac
    if have rpm-ostree; then install_brew; return; fi

    # Leave an existing Node alone (e.g. Arch's nodejs-lts-* conflicts with nodejs).
    local node="nodejs npm"
    have node && node=""

    # shellcheck disable=SC2086
    if have pacman; then
        say "pacman: installing packages"
        sudo_ pacman -S --needed --noconfirm git curl tmux fish neovim ripgrep fd unzip gcc make \
            tree-sitter-cli gitleaks $node wl-clipboard
    elif have apt-get; then
        say "apt: installing packages"
        sudo_ apt-get update
        sudo_ apt-get install -y git curl tmux fish ripgrep fd-find unzip build-essential \
            $node xclip wl-clipboard
        # Debian/Ubuntu name the fd binary fdfind.
        if have fdfind && ! have fd; then mkdir -p "$LOCAL_BIN"; ln -sf "$(command -v fdfind)" "$LOCAL_BIN/fd"; fi
    elif have dnf; then
        say "dnf: installing packages"
        sudo_ dnf install -y git curl tmux fish neovim ripgrep fd-find unzip gcc make $node wl-clipboard
    else
        warn "Unknown package manager. Install these yourself: git curl tmux fish neovim ripgrep fd unzip gcc make"
    fi
}

# Distro Neovim is often too old (Debian/Ubuntu/Mint); use the official build.
ensure_nvim() {
    if have nvim && ver_ge "$(nvim --version | head -n1 | sed 's/^NVIM v//; s/-.*//')" "$MIN_NVIM"; then
        return
    fi
    [ "$(uname -s)" = Linux ] || { warn "Neovim >= $MIN_NVIM not found"; return; }
    local arch
    case "$(uname -m)" in
        x86_64|amd64) arch=x86_64 ;;
        aarch64|arm64) arch=arm64 ;;
        *) warn "No Neovim release for $(uname -m)"; return ;;
    esac
    say "Installing the latest Neovim release to ~/.local/opt"
    mkdir -p "$HOME/.local/opt" "$LOCAL_BIN"
    rm -rf "$HOME/.local/opt/nvim-linux-$arch"
    curl -fsSL "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-$arch.tar.gz" |
        tar -xz -C "$HOME/.local/opt"
    ln -sfn "$HOME/.local/opt/nvim-linux-$arch/bin/nvim" "$LOCAL_BIN/nvim"
}

# nvim-treesitter needs the tree-sitter CLI to build parsers.
ensure_tree_sitter() {
    have tree-sitter && return
    local os arch
    case "$(uname -s)" in Linux) os=linux ;; Darwin) os=macos ;; *) return ;; esac
    case "$(uname -m)" in
        x86_64|amd64) arch=x64 ;;
        aarch64|arm64) arch=arm64 ;;
        *) warn "No tree-sitter release for $(uname -m)"; return ;;
    esac
    say "Installing the tree-sitter CLI to ~/.local/bin"
    mkdir -p "$LOCAL_BIN"
    curl -fsSL "https://github.com/tree-sitter/tree-sitter/releases/latest/download/tree-sitter-$os-$arch.gz" |
        gunzip > "$LOCAL_BIN/tree-sitter"
    chmod +x "$LOCAL_BIN/tree-sitter"
}

# Secret scanner used by the repo's git hooks (.githooks/check-private).
ensure_gitleaks() {
    have gitleaks && return
    local os arch tag
    case "$(uname -s)" in Linux) os=linux ;; Darwin) os=darwin ;; *) return ;; esac
    case "$(uname -m)" in
        x86_64|amd64) arch=x64 ;;
        aarch64|arm64) arch=arm64 ;;
        *) warn "No gitleaks release for $(uname -m)"; return ;;
    esac
    tag="$(curl -fsSL https://api.github.com/repos/gitleaks/gitleaks/releases/latest |
        sed -n 's/.*"tag_name": *"v\([^"]*\)".*/\1/p')"
    [ -n "$tag" ] || { warn "Couldn't look up the latest gitleaks release"; return; }
    say "Installing gitleaks $tag to ~/.local/bin"
    mkdir -p "$LOCAL_BIN"
    curl -fsSL "https://github.com/gitleaks/gitleaks/releases/download/v$tag/gitleaks_${tag}_${os}_${arch}.tar.gz" |
        tar -xz -C "$LOCAL_BIN" gitleaks
}

# --- Linking ------------------------------------------------------------------

backup() {
    if [ -e "$1" ] || [ -L "$1" ]; then
        mv "$1" "$1.bak.$STAMP"
        warn "Moved existing $1 to $1.bak.$STAMP"
    fi
}

# link SRC (relative to the repo) DEST
link() {
    local src="$DOT/$1" dest="$2"
    [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ] && return
    mkdir -p "$(dirname "$dest")"
    backup "$dest"
    ln -s "$src" "$dest"
    say "Linked $dest"
}

# add_line FILE LINE: append LINE to FILE unless it's already there.
add_line() {
    touch "$1"
    grep -qxF "$2" "$1" || { printf '\n%s\n' "$2" >> "$1"; say "Added a line to $1"; }
}

link_configs() {
    link tmux/tmux.conf "$CONFIG/tmux/tmux.conf"
    link nvim "$CONFIG/nvim"
    link bin/tm "$LOCAL_BIN/tm"
    link fish/conf.d/dotfiles.fish "$CONFIG/fish/conf.d/dotfiles.fish"
    link fish/completions/tm.fish "$CONFIG/fish/completions/tm.fish"
    # An older fish-function version of tm would shadow bin/tm.
    [ -e "$CONFIG/fish/functions/tm.fish" ] && backup "$CONFIG/fish/functions/tm.fish"

    add_line "$HOME/.bashrc" "[ -f \"$DOT/shell/tm.bash\" ] && . \"$DOT/shell/tm.bash\""
    if have zsh || [ -e "$HOME/.zshrc" ]; then
        add_line "$HOME/.zshrc" "[ -f \"$DOT/shell/tm.zsh\" ] && . \"$DOT/shell/tm.zsh\""
    fi
}

# Block commits/pushes of this repo that contain secrets or personal info.
setup_hooks() {
    git -C "$DOT" config core.hooksPath .githooks
    local list="$CONFIG/dotfiles/private-strings"
    if [ ! -e "$list" ]; then
        mkdir -p "$(dirname "$list")"
        cat > "$list" <<'LIST'
# Personal strings that must never be committed to the public dotfiles repo.
# One per line, case-insensitive. Lines starting with # are ignored.
# This file is NOT part of the repo. Examples: your full name, home address,
# phone number, personal email addresses, work/company names, device names.
LIST
        say "Created $list (add your name, address, etc.)"
    fi
}

fetch_tmux_plugins() {
    local dir="$CONFIG/tmux/plugins" p
    mkdir -p "$dir"
    for p in tpm tmux-resurrect tmux-continuum; do
        if [ ! -d "$dir/$p" ]; then
            say "Cloning $p"
            git clone -q --depth 1 "https://github.com/tmux-plugins/$p" "$dir/$p"
        fi
    done
}

fetch_nvim_plugins() {
    have nvim || return 0
    say "Installing Neovim plugins (lazy.nvim)"
    nvim --headless "+Lazy! restore" +qa >/dev/null 2>&1 || warn "Neovim plugin install failed; run :Lazy inside nvim"
    # mason-lspconfig skips ensure_installed in headless mode, so do it here.
    nvim --headless "+MasonInstall lua-language-server" +qa >/dev/null 2>&1 || true
}

# --- Main ---------------------------------------------------------------------

main() {
    local packages=1
    case "${1:-}" in
        --no-packages) packages=0 ;;
        -h|--help) sed -n '2,10s/^# \{0,1\}//p' "$0"; exit 0 ;;
        "") ;;
        *) warn "Unknown option: $1"; exit 1 ;;
    esac

    export PATH="$LOCAL_BIN:$PATH"
    if [ "$packages" -eq 1 ]; then
        install_packages
        ensure_nvim
        ensure_tree_sitter
    fi
    ensure_gitleaks

    link_configs
    setup_hooks
    fetch_tmux_plugins
    fetch_nvim_plugins

    say "Done. Open a new terminal, then try: tm <Tab>"
    if have fish && [ "$(basename "${SHELL:-}")" != fish ]; then
        echo "    Your login shell isn't fish. To switch:  chsh -s \"$(command -v fish)\""
        echo "    (if that fails, add $(command -v fish) to /etc/shells first)"
    fi
}

main "$@"
