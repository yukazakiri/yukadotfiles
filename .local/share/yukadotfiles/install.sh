#!/bin/bash

set -e

REPO_URL="https://github.com/yukazakiri/yukadotfiles.git"
YADM_URL="https://github.com/TheLocehiliosan/yadm/raw/master/yadm"
YADM_BIN="$HOME/.local/bin/yadm"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

command_exists() { command -v "$1" >/dev/null 2>&1; }

detect_package_manager() {
    if command_exists pacman; then
        echo "pacman"
    elif command_exists apt-get; then
        echo "apt"
    elif command_exists dnf; then
        echo "dnf"
    elif command_exists zypper; then
        echo "zypper"
    elif command_exists brew; then
        echo "brew"
    else
        echo "unknown"
    fi
}

install_yadm() {
    log_info "Installing yadm..."
    mkdir -p "$HOME/.local/bin"
    
    if command_exists curl; then
        curl -fsSL "$YADM_URL" -o "$YADM_BIN"
    elif command_exists wget; then
        wget -q "$YADM_URL" -O "$YADM_BIN"
    else
        log_error "Neither curl nor wget found. Please install one of them."
        exit 1
    fi
    
    chmod +x "$YADM_BIN"
    export PATH="$HOME/.local/bin:$PATH"
    log_success "yadm installed to $YADM_BIN"
}

install_fish() {
    if command_exists fish; then
        log_info "fish is already installed"
        return 0
    fi
    
    log_info "Installing fish shell..."
    local pm
    pm=$(detect_package_manager)
    
    case "$pm" in
        pacman)
            sudo pacman -S --noconfirm fish
            ;;
        apt)
            sudo apt-get update
            sudo apt-get install -y fish
            ;;
        dnf)
            sudo dnf install -y fish
            ;;
        zypper)
            sudo zypper install -y fish
            ;;
        brew)
            brew install fish
            ;;
        *)
            log_warn "Unknown package manager. Please install fish manually."
            return 1
            ;;
    esac
    
    log_success "fish installed successfully"
}

install_kitty() {
    if command_exists kitty; then
        log_info "kitty is already installed"
        return 0
    fi
    
    log_info "Installing kitty terminal..."
    local pm
    pm=$(detect_package_manager)
    
    case "$pm" in
        pacman)
            sudo pacman -S --noconfirm kitty
            ;;
        apt)
            sudo apt-get update
            sudo apt-get install -y kitty
            ;;
        dnf)
            sudo dnf install -y kitty
            ;;
        zypper)
            sudo zypper install -y kitty
            ;;
        brew)
            brew install --cask kitty
            ;;
        *)
            log_info "Installing kitty via official installer..."
            curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin
            mkdir -p ~/.local/bin
            ln -sf ~/.local/kitty.app/bin/kitty ~/.local/bin/kitty
            ;;
    esac
    
    log_success "kitty installed successfully"
}

set_default_shell() {
    if ! command_exists fish; then
        log_warn "fish not installed, skipping shell change"
        return 0
    fi
    
    local fish_path
    fish_path=$(command -v fish)
    
    if [ "$SHELL" = "$fish_path" ]; then
        log_info "fish is already the default shell"
        return 0
    fi
    
    log_info "Setting fish as default shell..."
    
    if ! grep -q "$fish_path" /etc/shells 2>/dev/null; then
        log_info "Adding fish to /etc/shells..."
        echo "$fish_path" | sudo tee -a /etc/shells > /dev/null
    fi
    
    sudo chsh -s "$fish_path" "$USER"
    log_success "fish set as default shell (will take effect after next login)"
}

check_yadm() {
    if command_exists yadm; then
        YADM_BIN=$(command -v yadm)
        log_info "yadm found at: $YADM_BIN"
        return 0
    elif [ -x "$YADM_BIN" ]; then
        export PATH="$HOME/.local/bin:$PATH"
        log_info "yadm found at: $YADM_BIN"
        return 0
    fi
    return 1
}

check_existing_repo() {
    [ -d "$HOME/.local/share/yadm/repo.git" ]
}

clone_dotfiles() {
    log_info "Cloning dotfiles from $REPO_URL..."
    yadm clone "$REPO_URL"
    log_success "Dotfiles cloned successfully!"
}

update_dotfiles() {
    log_info "Updating existing dotfiles..."
    yadm fetch origin
    
    local stashed=0
    if ! yadm diff --quiet HEAD 2>/dev/null; then
        log_warn "You have local changes. Stashing them..."
        yadm stash push -m "Auto-stash before update"
        stashed=1
    fi
    
    yadm pull origin main || yadm pull origin master
    
    if [ "$stashed" -eq 1 ]; then
        log_info "Restoring your local changes..."
        yadm stash pop || log_warn "Could not restore stashed changes automatically"
    fi
    
    log_success "Dotfiles updated successfully!"
}

run_bootstrap() {
    if [ -x "$HOME/.config/yadm/bootstrap" ]; then
        log_info "Running bootstrap script..."
        "$HOME/.config/yadm/bootstrap"
    fi
}

add_to_path() {
    local shell_rc="$HOME/.bashrc"
    [ -n "$ZSH_VERSION" ] && shell_rc="$HOME/.zshrc"
    
    if ! grep -q "\.local/bin" "$shell_rc" 2>/dev/null; then
        log_info "Adding ~/.local/bin to PATH in $shell_rc..."
        printf '\n# Add local bin to PATH\nexport PATH="$HOME/.local/bin:$PATH"\n' >> "$shell_rc"
        log_success "Updated $shell_rc"
    fi
}

show_info() {
    echo ""
    echo "========================================"
    log_success "Dotfiles setup complete!"
    echo "========================================"
    echo ""
    echo "Tracked files:"
    yadm list | head -20
    local total
    total=$(yadm list | wc -l)
    [ "$total" -gt 20 ] && echo "... and more ($total total files)"
    echo ""
    echo "Next steps:"
    echo "  - Run 'yadm status' to check status"
    echo "  - Run 'yadm add <file>' to add new files"
    echo "  - Run 'yadm commit -m \"msg\" && yadm push' to save changes"
    echo ""
    echo "Shell: $(command_exists fish && echo 'fish (default after login)' || echo 'bash')"
    echo "Terminal: $(command_exists kitty && echo 'kitty' || echo 'system default')"
    echo ""
    echo "Repository: $REPO_URL"
    echo ""
    log_info "Please restart your terminal or run:"
    echo "  source ~/.bashrc  # or ~/.zshrc"
}

main() {
    echo "========================================"
    echo "  Yukadotfiles Installer"
    echo "========================================"
    echo ""
    
    if ! check_yadm; then
        install_yadm
    fi
    
    install_fish
    install_kitty
    
    if check_existing_repo; then
        log_info "Existing yadm repository found!"
        read -p "Do you want to update? [Y/n]: " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            update_dotfiles
        else
            log_info "Skipping update. Your dotfiles are unchanged."
        fi
    else
        log_info "No existing dotfiles found. Setting up fresh..."
        clone_dotfiles
    fi
    
    run_bootstrap
    add_to_path
    set_default_shell
    show_info
}

main "$@"
