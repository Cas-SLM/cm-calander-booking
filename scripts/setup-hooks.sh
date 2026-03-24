#!/bin/bash

# Setup script for git hooks
# Installs pre-commit hook for the repository

# Source shared utilities
source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"

# Configuration
SCRIPT_DIR="$(get_script_dir)"
PROJECT_ROOT="$(get_project_root)"
PRE_COMMIT_SCRIPT="$SCRIPT_DIR/pre-commit.sh"
GIT_HOOKS_DIR="$PROJECT_ROOT/.git/hooks"
PRE_COMMIT_HOOK="$GIT_HOOKS_DIR/pre-commit"

# Main execution
main() {
    print_script_header "Git Hooks Setup Script"
    
    # Check command line arguments
    case "${1:-install}" in
        "install"|"")
            if ! is_git_repository; then
                log_error "Not in a git repository"
                echo "Please run this script from the root of your git repository"
                exit 1
            fi
            
            make_executable "$PRE_COMMIT_SCRIPT"
            install_pre_commit_hook "$PRE_COMMIT_SCRIPT" "$PRE_COMMIT_HOOK"
            create_commit_template "$PROJECT_ROOT"
            verify_installation "$PRE_COMMIT_SCRIPT" "$PRE_COMMIT_HOOK"
            show_setup_usage "$PRE_COMMIT_SCRIPT" "$PRE_COMMIT_HOOK" "$PROJECT_ROOT"
            ;;
        "uninstall")
            uninstall_hooks "$PRE_COMMIT_HOOK"
            ;;
        "verify")
            verify_installation "$PRE_COMMIT_SCRIPT" "$PRE_COMMIT_HOOK"
            ;;
        *)
            show_setup_hooks_usage
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
