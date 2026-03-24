#!/bin/bash

# Shared utility functions for all scripts
# This file contains common functions and constants used across multiple scripts

# Exit on any error
set -euo pipefail

# ========================================
# COLOR CONSTANTS AND LOGGING FUNCTIONS
# ========================================

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

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

# ========================================
# SCRIPT PATH AND PROJECT ROOT FUNCTIONS
# ========================================

# Get the directory where the current script is located
get_script_dir() {
    local script_source="${BASH_SOURCE[0]}"
    
    # Resolve $script_source until the file is no longer a symlink
    while [[ -h "$script_source" ]]; do
        local script_dir="$(cd "$(dirname "$script_source")" && pwd)"
        script_source="$(readlink "$script_source")"
        
        # If $script_source was a relative symlink, we need to resolve it relative to the path where the symlink file was located
        if [[ "$script_source" != /* ]]; then
            script_source="$script_dir/$script_source"
        fi
    done
    
    local script_dir="$(cd "$(dirname "$script_source")" && pwd)"
    echo "$script_dir"
}

# Get the project root directory (parent of scripts directory)
get_project_root() {
    local script_dir="$(get_script_dir)"
    local project_root="$(dirname "$script_dir")"
    echo "$project_root"
}

# ========================================
# GIT REPOSITORY FUNCTIONS
# ========================================

# Check if we're in a git repository
is_git_repository() {
    git rev-parse --git-dir > /dev/null 2>&1
}

# Get git repository root directory
get_git_root() {
    if ! is_git_repository; then
        log_error "Not in a git repository"
        return 1
    fi
    git rev-parse --show-toplevel
}

# Check if git has a valid context
has_valid_git_context() {
    git cluster-info > /dev/null 2>&1
}

# ========================================
# FILE AND SYSTEM UTILITIES
# ========================================

# Check if a command exists
command_exists() {
    command -v "$1" > /dev/null 2>&1
}

# Check if a file exists and is readable
file_exists() {
    local file="$1"
    [[ -f "$file" && -r "$file" ]]
}

# Check if a directory exists and is readable
dir_exists() {
    local dir="$1"
    [[ -d "$dir" && -r "$dir" ]]
}

# Check if a file is executable
is_executable() {
    local file="$1"
    [[ -x "$file" ]]
}

# Make a file executable
make_executable() {
    local file="$1"
    if ! is_executable "$file"; then
        chmod +x "$file"
        log_success "Made $file executable"
    else
        log_info "$file is already executable"
    fi
}

# ========================================
# PACKAGE.JSON UTILITIES
# ========================================

# Extract version from package.json
extract_version() {
    local package_json="$1"
    
    if ! file_exists "$package_json"; then
        log_error "package.json not found at: $package_json"
        return 1
    fi
    
    local version=""
    
    # Extract version using jq (preferred method)
    if command_exists jq; then
        version=$(jq -r '.version' "$package_json")
    else
        # Fallback to grep/sed if jq is not available
        log_warning "jq not found, using fallback method to extract version"
        version=$(grep -E '"version":' "$package_json" | sed -E 's/.*"version":\s*"([^"]+)".*/\1/')
    fi
    
    # Validate version format
    if [[ -z "$version" || "$version" == "null" ]]; then
        log_error "Could not extract version from package.json"
        return 1
    fi
    
    echo "$version"
}

# ========================================
# DOCKER UTILITIES
# ========================================

# Check if Docker is available
check_docker() {
    if ! command_exists docker; then
        log_error "Docker is not installed or not in PATH"
        return 1
    fi
    return 0
}

# Build Docker image with proper tagging
build_docker_image() {
    local version="$1"
    local image_name="$2"
    local registry="${3:-}"
    
    log_info "Building Docker image with version: $version"
    
    # Check if Docker is available
    if ! check_docker; then
        return 1
    fi
    
    # Build arguments
    local build_args="--build-arg VERSION=$version"
    
    # Image tags
    local image_tags=()
    
    if [[ -n "$registry" ]]; then
        image_tags+=("$registry/$image_name:$version")
        image_tags+=("$registry/$image_name:latest")
    else
        image_tags+=("$image_name:$version")
        image_tags+=("$image_name:latest")
    fi
    
    # Build command
    local docker_build_cmd="docker build $build_args"
    
    # Add all image tags
    for tag in "${image_tags[@]}"; do
        docker_build_cmd="$docker_build_cmd -t $tag"
    done
    
    docker_build_cmd="$docker_build_cmd ."
    
    log_info "Running: $docker_build_cmd"
    
    # Execute build
    if eval $docker_build_cmd; then
        log_success "Docker image built successfully"
        log_info "Image tags created:"
        for tag in "${image_tags[@]}"; do
            log_info "  - $tag"
        done
        return 0
    else
        log_error "Docker build failed"
        return 1
    fi
}

# ========================================
# KUBERNETES UTILITIES
# ========================================

# Check if kubectl is available
check_kubectl() {
    if ! command_exists kubectl; then
        log_error "kubectl is not installed or not in PATH"
        return 1
    fi
    return 0
}

# Check if we have a valid kubectl context
check_kubectl_context() {
    if ! check_kubectl; then
        return 1
    fi
    
    if ! kubectl cluster-info > /dev/null 2>&1; then
        log_error "No valid kubectl context found"
        return 1
    fi
    return 0
}

# Check if namespace exists, create if not
ensure_namespace() {
    local namespace="$1"
    
    if ! kubectl get namespace "$namespace" > /dev/null 2>&1; then
        log_info "Creating namespace: $namespace"
        kubectl create namespace "$namespace"
    fi
}

# ========================================
# COMMIT MESSAGE VALIDATION
# ========================================

# Validate commit message format (conventional commits)
validate_commit_message() {
    local msg="$1"
    
    # Remove leading/trailing whitespace and get first line
    local first_line=$(echo "$msg" | head -n1 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    
    # Skip validation for empty first line or special commits
    if [[ -z "$first_line" ]] || [[ "$first_line" =~ ^WIP:.* ]] || [[ "$first_line" =~ ^squash!.* ]]; then
        log_warning "Skipping commit message validation"
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

# ========================================
# QUALITY CHECK FUNCTIONS
# ========================================

# Run TypeScript type checking
check_typescript() {
    local project_root="$1"
    
    log_info "Running TypeScript type checking..."
    
    cd "$project_root"
    
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

# Run ESLint
check_linting() {
    local project_root="$1"
    
    log_info "Running ESLint..."
    
    cd "$project_root"
    
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

# Check Prettier formatting
check_formatting() {
    local project_root="$1"
    
    log_info "Checking code formatting with Prettier..."
    
    cd "$project_root"
    
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

# Run tests
run_tests() {
    local project_root="$1"
    
    log_info "Running tests..."
    
    cd "$project_root"
    
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

# Check if files have changed
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

# ========================================
# ARGUMENT PARSING HELPERS
# ========================================

# Show usage message for docker-build script
show_docker_build_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Build Docker image with version extracted from package.json"
    echo ""
    echo "OPTIONS:"
    echo "  -n, --name IMAGE_NAME    Docker image name (default: cm-hello-ts)"
    echo "  -r, --registry REGISTRY  Docker registry (e.g., docker.io/username)"
    echo "  -h, --help              Show this help message"
    echo ""
    echo "EXAMPLES:"
    echo "  $0                                    # Build with default name"
    echo "  $0 -n my-app                         # Build with custom name"
    echo "  $0 -n my-app -r docker.io/username   # Build with registry"
    echo ""
}

# Show usage message for setup-hooks script
show_setup_hooks_usage() {
    echo "Usage: $0 [install|uninstall|verify]"
    echo ""
    echo "Commands:"
    echo "  install    Install git hooks (default)"
    echo "  uninstall  Remove git hooks"
    echo "  verify     Verify hook installation"
    echo ""
}

# Show usage message for deploy script
show_deploy_usage() {
    echo "Usage: $0 <environment> <version>"
    echo "Environments: dev, test, prod"
    echo ""
    echo "Examples:"
    echo "  $0 dev latest"
    echo "  $0 prod 1.0.0"
    echo ""
}

# ========================================
# VALIDATION FUNCTIONS
# ========================================

# Validate environment parameter
validate_environment() {
    local env="$1"
    if [[ ! "$env" =~ ^(dev|test|prod)$ ]]; then
        log_error "Invalid environment: $env"
        log_error "Valid environments: dev, test, prod"
        return 1
    fi
    return 0
}

# Validate that a parameter is not empty
validate_required_param() {
    local param_name="$1"
    local param_value="$2"
    
    if [[ -z "$param_value" ]]; then
        log_error "$param_name is required"
        return 1
    fi
    return 0
}

# ========================================
# INSTALLATION AND SETUP FUNCTIONS
# ========================================

# Install pre-commit hook
install_pre_commit_hook() {
    local pre_commit_script="$1"
    local pre_commit_hook="$2"
    
    log_info "Installing pre-commit hook..."
    
    # Check if hook already exists
    if [[ -f "$pre_commit_hook" ]]; then
        log_warning "Pre-commit hook already exists"
        
        # Check if it's our hook
        if grep -q "Pre-commit hook script for NestJS application" "$pre_commit_hook" 2>/dev/null; then
            log_info "Existing hook is already our pre-commit script"
            return 0
        else
            log_warning "Existing hook will be replaced"
            read -p "Do you want to backup the existing hook? (y/n): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                cp "$pre_commit_hook" "$pre_commit_hook.backup"
                log_success "Existing hook backed up to $pre_commit_hook.backup"
            fi
        fi
    fi
    
    # Create symlink to our pre-commit script
    ln -sf "$pre_commit_script" "$pre_commit_hook"
    
    if [[ -L "$pre_commit_hook" ]]; then
        log_success "Pre-commit hook installed successfully"
        log_info "Hook points to: $pre_commit_script"
        return 0
    else
        log_error "Failed to install pre-commit hook"
        return 1
    fi
}

# Create commit message template
create_commit_template() {
    local project_root="$1"
    local template_file="$project_root/.gitmessage"
    
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
    return 0
}

# Verify installation
verify_installation() {
    local pre_commit_script="$1"
    local pre_commit_hook="$2"
    
    log_info "Verifying installation..."
    
    # Check if pre-commit script exists and is executable
    if ! file_exists "$pre_commit_script"; then
        log_error "Pre-commit script not found: $pre_commit_script"
        return 1
    fi
    
    if ! is_executable "$pre_commit_script"; then
        log_error "Pre-commit script is not executable"
        return 1
    fi
    
    # Check if hook exists and points to our script
    if [[ ! -L "$pre_commit_hook" ]]; then
        log_error "Pre-commit hook not found or not a symlink"
        return 1
    fi
    
    local hook_target=$(readlink "$pre_commit_hook")
    if [[ "$hook_target" != "$pre_commit_script" ]]; then
        log_error "Pre-commit hook points to wrong target: $hook_target"
        return 1
    fi
    
    # Check if commit template is configured
    local template_config=$(git config commit.template)
    if [[ -z "$template_config" ]]; then
        log_warning "Commit template not configured in git config"
    else
        log_info "Commit template configured: $template_config"
    fi
    
    log_success "Installation verification passed"
    return 0
}

# Show setup usage information
show_setup_usage() {
    echo ""
    log_info "Pre-commit hook installation complete!"
    echo ""
    log_info "What was installed:"
    echo "  ✓ Pre-commit script: $1"
    echo "  ✓ Git hook: $2"
    echo "  ✓ Commit template: $3/.gitmessage"
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

# Uninstall hooks
uninstall_hooks() {
    local pre_commit_hook="$1"
    
    log_info "Uninstalling git hooks..."
    
    if [[ -L "$pre_commit_hook" ]]; then
        rm "$pre_commit_hook"
        log_success "Pre-commit hook removed"
    else
        log_info "No pre-commit hook found to remove"
    fi
    
    # Remove commit template configuration
    git config --unset commit.template 2>/dev/null || true
    log_info "Commit template configuration removed"
    
    log_success "Hooks uninstalled successfully"
    return 0
}

# ========================================
# MAIN EXECUTION HELPERS
# ========================================

# Print script header
print_script_header() {
    local script_name="$1"
    echo "$script_name"
    echo "$(printf '=%.0s' $(seq 1 ${#script_name}))"
    echo ""
}

# Exit with error and message
exit_with_error() {
    local message="$1"
    local exit_code="${2:-1}"
    log_error "$message"
    exit "$exit_code"
}

# Exit with success message
exit_with_success() {
    local message="$1"
    log_success "$message"
    exit 0
}

# ========================================
# END OF UTILITIES
# ========================================