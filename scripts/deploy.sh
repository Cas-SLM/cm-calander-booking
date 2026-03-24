#!/bin/bash
# Deploy script for Kubernetes deployments
# Usage: ./scripts/deploy.sh <environment> <version>

# Source shared utilities
source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"

# Script parameters
ENVIRONMENT="${1:-dev}"
VERSION="${2:-latest}"
IMAGE_NAME="${IMAGE_NAME:-cm-hello-ts}"
IMAGE_TAG="${IMAGE_NAME}:${VERSION}"
REGISTRY="docker.io"
NAMESPACE="${3:-cas-central}"

# Validate parameters
if ! validate_environment "$ENVIRONMENT"; then
    show_deploy_usage
    exit 1
fi

if ! validate_required_param "Version" "$VERSION"; then
    show_deploy_usage
    exit 1
fi

log_info "
==========================================
Deploying to ${ENVIRONMENT}
Version: ${VERSION}
Namespace: ${NAMESPACE}
Image: ${IMAGE_TAG}
=========================================="

# Validate environment and tools
if ! check_kubectl; then
    exit 1
fi

if ! check_kubectl_context; then
    exit 1
fi

# Ensure namespace exists
ensure_namespace "$NAMESPACE"

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