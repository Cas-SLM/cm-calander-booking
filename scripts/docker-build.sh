#!/bin/bash

# Docker Build Script with Version Extraction
# This script extracts the version from package.json and builds a Docker image with proper tagging

# Source shared utilities
source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"


# Script parameters
SCRIPT_DIR="$(get_script_dir)"
PROJECT_ROOT="$(get_project_root)"
IMAGE_NAME="cm-hello-ts"
REGISTRY=""

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -n|--name)
            IMAGE_NAME="$2"
            shift 2
            ;;
        -r|--registry)
            REGISTRY="$2"
            shift 2
            ;;
        -h|--help)
            show_docker_build_usage
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            show_docker_build_usage
            exit 1
            ;;
    esac
done

# Main execution
main() {
    log_info "Starting Docker build process..."
    log_info "Project root: $PROJECT_ROOT"
    
    # Change to project root
    cd "$PROJECT_ROOT"
    
    # Extract version from package.json
    log_info "Extracting version from package.json..."
    VERSION=$(extract_version "package.json")
    log_success "Version extracted: $VERSION"
    
    # Build Docker image
    build_docker_image "$VERSION" "$IMAGE_NAME" "$REGISTRY"
    
    log_success "Docker build completed successfully!"
    log_info "Image is ready for deployment"
}

# Run main function
main "$@"