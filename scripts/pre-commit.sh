#!/bin/bash

# Pre-commit hook script for NestJS application
# Validates commit messages and runs quality checks
# Usage: This script is automatically called by git during commit

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

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
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    log_error "Not in a git repository"
    exit 1
fi

# Get commit message
if [[ -n "${1:-}" ]]; then
    COMMIT_MSG_FILE="$1"
    COMMIT_MSG=$(cat "$COMMIT_MSG_FILE")
else
    # Fallback: try to get commit message from git config or use a default
    COMMIT_MSG="test: fallback commit message"
fi

# Skip validation for merge commits and empty commits
if [[ "$COMMIT_MSG" =~ ^Merge\ .* ]] || [[ -z "$COMMIT_MSG" ]]; then
    log_info "Skipping pre-commit checks for merge or empty commit"
    exit 0
fi

# Function to validate commit message format
validate_commit_message() {
    local msg="$1"
    
    # Remove leading/trailing whitespace and get first line
    local first_line=$(echo "$msg" | head -n1 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    
    # Skip validation for empty first line or special commits
    if [[ -z "$first_line" ]] || [[ "$first_line" =~ ^WIP:.* ]] || [[ "$first_line" =~ ^squash!.* ]]; then
        log_info "Skipping commit message validation"
        return 0
    fi
    
    # Conventional commit regex pattern
    # Format: type(scope): description
    # - type: feat, fix, docs, style, refactor, test, chore, ci, build, perf
    # - scope: optional, alphanumeric with hyphens
    # - description: required, starts with lowercase, no period
    local pattern='^(feat|fix|docs|style|refactor|test|chore|ci|build|perf)(\([a-zA-Z0-9-]+\))?: [a-z].*[^.]$'
    
    if [[ ! "$first_line" =~ $pattern ]]; then
        log_error "Commit message format is invalid"
        echo ""
        log_info "Expected format: <type>(<scope>): <description>"
        echo ""
        log_info "Valid types: feat, fix, docs, style, refactor, test, chore, ci, build, perf"
        echo ""
        log_info "Examples:"
        echo "  feat: add user authentication system"
        echo "  fix(api): resolve CORS issues in login endpoint"
        echo "  docs: update API documentation for v2.0"
        echo "  style: format code according to Prettier rules"
        echo "  refactor: simplify database connection logic"
        echo "  test: add unit tests for auth service"
        echo "  chore: update dependencies to latest versions"
        echo "  ci: add Docker build step to pipeline"
        echo "  build: update webpack configuration"
        echo "  perf: optimize database queries for better performance"
        echo ""
        log_info "Current message: $first_line"
        echo ""
        log_error "Please fix your commit message and try again"
        return 1
    fi
    
    log_success "Commit message format is valid"
    return 0
}

# Function to run TypeScript type checking
check_typescript() {
    log_info "Running TypeScript type checking..."
    
    cd "$PROJECT_ROOT"
    
    # Run build without output to check for type errors
    if pnpm run build > /dev/null 2>&1; then
        log_success "TypeScript compilation successful"
        return 0
    else
        log_error "TypeScript compilation failed"
        echo ""
        log_info "Running build with output to show errors..."
        pnpm run build
        return 1
    fi
}

# Function to run ESLint
check_linting() {
    log_info "Running ESLint..."
    
    cd "$PROJECT_ROOT"
    
    if pnpm run lint > /dev/null 2>&1; then
        log_success "ESLint checks passed"
        return 0
    else
        log_error "ESLint checks failed"
        echo ""
        log_info "Running ESLint with output to show errors..."
        pnpm run lint
        return 1
    fi
}

# Function to check Prettier formatting
check_formatting() {
    log_info "Checking code formatting with Prettier..."
    
    cd "$PROJECT_ROOT"
    
    if pnpm run format --check > /dev/null 2>&1; then
        log_success "Code formatting is correct"
        return 0
    else
        log_error "Code formatting issues found"
        echo ""
        log_info "Files that need formatting:"
        pnpm run format --check
        echo ""
        log_warning "Run 'pnpm run format' to fix formatting issues"
        return 1
    fi
}

# Function to run tests
run_tests() {
    log_info "Running tests..."
    
    cd "$PROJECT_ROOT"
    
    if pnpm run test > /dev/null 2>&1; then
        log_success "All tests passed"
        return 0
    else
        log_error "Tests failed"
        echo ""
        log_info "Running tests with output to show failures..."
        pnpm run test
        return 1
    fi
}

# Function to check if files have changed
check_for_changes() {
    # Check if there are any changes to commit
    if ! git diff --cached --quiet --exit-code; then
        log_info "Files have changes, proceeding with checks..."
        return 0
    else
        log_info "No changes to commit"
        return 0
    fi
}

# Main execution
main() {
    log_info "Starting pre-commit checks..."
    echo ""
    
    # 1. Validate commit message
    if ! validate_commit_message "$COMMIT_MSG"; then
        exit 1
    fi
    echo ""
    
    # 2. Check for changes
    check_for_changes
    echo ""
    
    # 3. Run TypeScript type checking
    if ! check_typescript; then
        exit 1
    fi
    echo ""
    
    # 4. Run ESLint
    if ! check_linting; then
        exit 1
    fi
    echo ""
    
    # 5. Check Prettier formatting
    if ! check_formatting; then
        exit 1
    fi
    echo ""
    
    # 6. Run tests
    if ! run_tests; then
        exit 1
    fi
    echo ""
    
    log_success "All pre-commit checks passed! ✅"
    log_info "Commit will proceed..."
}

# Run main function
main "$@"