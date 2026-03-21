#!/bin/bash
# Deploy script for Kubernetes deployments
# Usage: ./scripts/deploy.sh <environment> <version>

set -euo pipefail

ENVIRONMENT="${1:-dev}"
VERSION="${2:-latest}"
IMAGE_TAG="${IMAGE_NAME}:${VERSION}"
REGISTRY="docker.io"
NAMESPACE="${3:-cas-central}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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
echo_usage() {
    echo "Usage: $0 <environment> <version>"
    echo "Environments: dev, test, prod"
}

if [[ ! "$ENVIRONMENT" =~ ^(dev|test|prod)$ ]]; then
    log_error "Environment is required"
    log_error "Invalid environment: $ENVIRONMENT"
    echo_usage
    exit 1
fi

if [[ -z "$VERSION" ]]; then
    log_error "Version is required"
    echo_usage
    exit 1
fi

log_info "
==========================================
Deploying to ${ENVIRONMENT}
Version: ${VERSION}
Namespace: ${NAMESPACE}
Image: ${IMAGE_TAG}
=========================================="

# Validate environment

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    log_error "kubectl is not installed or not in PATH"
    exit 1
fi

# Check if we have a valid kubectl context
if ! kubectl cluster-info &> /dev/null; then
    log_error "No valid kubectl context found"
    exit 1
fi

# Check if namespace exists, create if not
if ! kubectl get namespace "$NAMESPACE" &>/dev/null; then
    log_info "Creating namespace: $NAMESPACE"
    kubectl create namespace "$NAMESPACE"
fi

# Apply Kubernetes manifests with environment-specific values
echo "Applying Kubernetes manifests..."
kubectl apply -n "$NAMESPACE" -f k8s/base/

# Set the image tag
echo "Updating image tag to: ${IMAGE_TAG}"
kubectl set image deployment/app \
    app="${IMAGE_TAG}" \
    -n "$NAMESPACE"

# Wait for rollout to complete
echo "Waiting for rollout to complete..."
kubectl rollout status deployment/app \
    -n "$NAMESPACE" \
    --timeout=300s

# Verify deployment
echo "Verifying deployment..."
kubectl get pods -n "$NAMESPACE" -l app=app

echo "=========================================="
echo "Deployment to ${ENVIRONMENT} completed successfully!"
echo "=========================================="