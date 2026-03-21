#!/bin/bash

# Setup script for git hooks
# Installs pre-commit hook for the repository

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
PRE_COMMIT_SCRIPT="$SCRIPT_DIR/pre-commit.sh"
GIT_HOOKS_DIR="$PROJECT_ROOT/.git/hooks"
PRE_COMMIT_HOOK="$GIT_HOOKS_DIR/pre-commit"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if we're in a git repository
check_git_repository() {
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        log_error "Not in a git repository"
        echo "Please run this script from the root of your git repository"
        exit 1
    fi
}

# Make pre-commit script executable
make_script_executable() {
    if [[ ! -x "$PRE_COMMIT_SCRIPT" ]]; then
        log_info "Making pre-commit script executable..."
        chmod +x "$PRE_COMMIT_SCRIPT"
        log_success "Pre-commit script is now executable"
    else
        log_info "Pre-commit script is already executable"
    fi
}

# Install pre-commit hook
install_pre_commit_hook() {
    log_info "Installing pre-commit hook..."
    
    # Check if hook already exists
    if [[ -f "$PRE_COMMIT_HOOK" ]]; then
        log_warning "Pre-commit hook already exists"
        
        # Check if it's our hook
        if grep -q "Pre-commit hook script for NestJS application" "$PRE_COMMIT_HOOK" 2>/dev/null; then
            log_info "Existing hook is already our pre-commit script"
            return 0
        else
            log_warning "Existing hook will be replaced"
            read -p "Do you want to backup the existing hook? (y/n): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                cp "$PRE_COMMIT_HOOK" "$PRE_COMMIT_HOOK.backup"
                log_success "Existing hook backed up to $PRE_COMMIT_HOOK.backup"
            fi
        fi
    fi
    
    # Create symlink to our pre-commit script
    ln -sf "$PRE_COMMIT_SCRIPT" "$PRE_COMMIT_HOOK"
    
    if [[ -L "$PRE_COMMIT_HOOK" ]]; then
        log_success "Pre-commit hook installed successfully"
        log_info "Hook points to: $PRE_COMMIT_SCRIPT"
    else
        log_error "Failed to install pre-commit hook"
        exit 1
    fi
}

# Create commit message template
create_commit_template() {
    local template_file="$PROJECT_ROOT/.gitmessage"
    
    log_info "Creating commit message template..."
    
    cat > "$template_file" << 'EOF'
# <type>(<scope>): <subject>
#
# <body>
#
# <footer>
#
# Types: feat, fix, docs, style, refactor, test, chore, ci, build, perf
# Scope: optional, e.g., api, auth, database
# Subject: lowercase, no period
#
# Example:
# feat(auth): add OAuth2 integration
#
# Add support for OAuth2 authentication flow
# including token refresh and error handling
#
# Closes #123
EOF

    # Configure git to use the template
    git config commit.template "$template_file"
    
    log_success "Commit message template created and configured"
    log_info "Template file: $template_file"
}

# Verify installation
verify_installation() {
    log_info "Verifying installation..."
    
    # Check if pre-commit script exists and is executable
    if [[ ! -f "$PRE_COMMIT_SCRIPT" ]]; then
        log_error "Pre-commit script not found: $PRE_COMMIT_SCRIPT"
        exit 1
    fi
    
    if [[ ! -x "$PRE_COMMIT_SCRIPT" ]]; then
        log_error "Pre-commit script is not executable"
        exit 1
    fi
    
    # Check if hook exists and points to our script
    if [[ ! -L "$PRE_COMMIT_HOOK" ]]; then
        log_error "Pre-commit hook not found or not a symlink"
        exit 1
    fi
    
    local hook_target=$(readlink "$PRE_COMMIT_HOOK")
    if [[ "$hook_target" != "$PRE_COMMIT_SCRIPT" ]]; then
        log_error "Pre-commit hook points to wrong target: $hook_target"
        exit 1
    fi
    
    # Check if commit template is configured
    local template_config=$(git config commit.template)
    if [[ -z "$template_config" ]]; then
        log_warning "Commit template not configured in git config"
    else
        log_info "Commit template configured: $template_config"
    fi
    
    log_success "Installation verification passed"
}

# Show usage information
show_usage() {
    echo ""
    log_info "Pre-commit hook installation complete!"
    echo ""
    log_info "What was installed:"
    echo "  ✓ Pre-commit script: $PRE_COMMIT_SCRIPT"
    echo "  ✓ Git hook: $PRE_COMMIT_HOOK"
    echo "  ✓ Commit template: $PROJECT_ROOT/.gitmessage"
    echo ""
    log_info "How it works:"
    echo "  • Pre-commit hook runs automatically on 'git commit'"
    echo "  • Validates commit message format (conventional commits)"
    echo "  • Runs TypeScript type checking"
    echo "  • Runs ESLint with your configuration"
    echo "  • Checks Prettier formatting (no auto-fix)"
    echo "  • Runs Jest tests"
    echo ""
    log_info "Commit message format:"
    echo "  <type>(<scope>): <description>"
    echo "  Types: feat, fix, docs, style, refactor, test, chore, ci, build, perf"
    echo ""
    log_info "Examples:"
    echo "  feat: add user authentication system"
    echo "  fix(api): resolve CORS issues in login endpoint"
    echo "  docs: update API documentation for v2.0"
    echo ""
    log_info "To test the hook:"
    echo "  1. Make some changes to your code"
    echo "  2. Run: git add ."
    echo "  3. Run: git commit -m 'test: this should fail'"
    echo "  4. The hook should validate and run checks"
    echo ""
    log_info "To bypass the hook (emergency only):"
    echo "  git commit --no-verify -m 'emergency commit'"
    echo ""
}

# Uninstall function
uninstall_hooks() {
    log_info "Uninstalling git hooks..."
    
    if [[ -L "$PRE_COMMIT_HOOK" ]]; then
        rm "$PRE_COMMIT_HOOK"
        log_success "Pre-commit hook removed"
    else
        log_info "No pre-commit hook found to remove"
    fi
    
    # Remove commit template configuration
    git config --unset commit.template 2>/dev/null || true
    log_info "Commit template configuration removed"
    
    log_success "Hooks uninstalled successfully"
}

# Main execution
main() {
    echo "Git Hooks Setup Script"
    echo "======================"
    echo ""
    
    # Check command line arguments
    case "${1:-install}" in
        "install"|"")
            check_git_repository
            make_script_executable
            install_pre_commit_hook
            create_commit_template
            verify_installation
            show_usage
            ;;
        "uninstall")
            uninstall_hooks
            ;;
        "verify")
            verify_installation
            ;;
        *)
            log_error "Usage: $0 [install|uninstall|verify]"
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"