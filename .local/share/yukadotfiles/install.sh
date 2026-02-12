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
    show_info
}

main "$@"
