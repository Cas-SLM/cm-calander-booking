#!/bin/bash

# Deployment script for NestJS application
# Usage: ./scripts/deploy.sh <environment> <version>

set -euo pipefail

# Configuration
ENVIRONMENT=${1:-dev}
VERSION=${2:-latest}
IMAGE_NAME="cm-hello-ts"
REGISTRY="docker.io"
NAMESPACE="cm-hello-ts-${ENVIRONMENT}"

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

# Validate inputs
if [[ -z "$ENVIRONMENT" ]]; then
    log_error "Environment is required"
    echo "Usage: $0 <environment> <version>"
    echo "Environments: dev, test, prod"
    exit 1
fi

if [[ -z "$VERSION" ]]; then
    log_error "Version is required"
    echo "Usage: $0 <environment> <version>"
    exit 1
fi

# Validate environment
case "$ENVIRONMENT" in
    dev|test|prod)
        log_info "Deploying to environment: $ENVIRONMENT"
        ;;
    *)
        log_error "Invalid environment: $ENVIRONMENT"
        echo "Valid environments: dev, test, prod"
        exit 1
        ;;
esac

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

# Create namespace if it doesn't exist
log_info "Ensuring namespace exists: $NAMESPACE"
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

# Build image tag
IMAGE_TAG="${REGISTRY}/${IMAGE_NAME}:${VERSION}"
LATEST_TAG="${REGISTRY}/${IMAGE_NAME}:latest"

log_info "Using image: $IMAGE_TAG"

# Create or update Docker registry secret
log_info "Setting up Docker registry secret"
kubectl create secret docker-registry dockerhub-credentials \
    --docker-server="$REGISTRY" \
    --docker-username="${DOCKERHUB_USERNAME:-}" \
    --docker-password="${DOCKERHUB_TOKEN:-}" \
    --docker-email="${DOCKERHUB_EMAIL:-noreply@example.com}" \
    --namespace="$NAMESPACE" \
    --dry-run=client -o yaml | kubectl apply -f -

# Create ConfigMap for application configuration
log_info "Creating ConfigMap for $ENVIRONMENT environment"
kubectl create configmap app-config \
    --from-literal=NODE_ENV="$ENVIRONMENT" \
    --from-literal=PORT="3000" \
    --from-literal=LOG_LEVEL="info" \
    --namespace="$NAMESPACE" \
    --dry-run=client -o yaml | kubectl apply -f -

# Create or update deployment
log_info "Creating/updating deployment for $ENVIRONMENT"
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cm-hello-ts-${ENVIRONMENT}
  namespace: ${NAMESPACE}
  labels:
    app: cm-hello-ts
    environment: ${ENVIRONMENT}
spec:
  replicas: ${ENVIRONMENT == "prod" && 3 || 1}
  selector:
    matchLabels:
      app: cm-hello-ts
      environment: ${ENVIRONMENT}
  template:
    metadata:
      labels:
        app: cm-hello-ts
        environment: ${ENVIRONMENT}
    spec:
      containers:
      - name: app
        image: ${IMAGE_TAG}
        ports:
        - containerPort: 3000
        envFrom:
        - configMapRef:
            name: app-config
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: ${ENVIRONMENT == "prod" && "512Mi" || "256Mi"}
            cpu: ${ENVIRONMENT == "prod" && "500m" || "250m"}
        livenessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 3000
          initialDelaySeconds: 5
          periodSeconds: 5
      imagePullSecrets:
      - name: dockerhub-credentials
---
apiVersion: v1
kind: Service
metadata:
  name: cm-hello-ts-service
  namespace: ${NAMESPACE}
  labels:
    app: cm-hello-ts
    environment: ${ENVIRONMENT}
spec:
  selector:
    app: cm-hello-ts
    environment: ${ENVIRONMENT}
  ports:
  - protocol: TCP
    port: 80
    targetPort: 3000
  type: ClusterIP
EOF

# Create Horizontal Pod Autoscaler for production
if [[ "$ENVIRONMENT" == "prod" ]]; then
    log_info "Creating Horizontal Pod Autoscaler for production"
    kubectl apply -f - <<EOF
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: cm-hello-ts-hpa
  namespace: ${NAMESPACE}
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: cm-hello-ts-${ENVIRONMENT}
  minReplicas: 3
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
EOF
fi

# Wait for deployment to be ready
log_info "Waiting for deployment to be ready..."
kubectl rollout status deployment/cm-hello-ts-${ENVIRONMENT} --namespace="$NAMESPACE" --timeout=300s

# Get deployment status
log_info "Deployment status:"
kubectl get deployment cm-hello-ts-${ENVIRONMENT} --namespace="$NAMESPACE"

# Get pod status
log_info "Pod status:"
kubectl get pods --namespace="$NAMESPACE" -l app=cm-hello-ts,environment=${ENVIRONMENT}

# Display service information
log_info "Service information:"
kubectl get service cm-hello-ts-service --namespace="$NAMESPACE"

# Display rollout history
log_info "Rollout history:"
kubectl rollout history deployment/cm-hello-ts-${ENVIRONMENT} --namespace="$NAMESPACE"

log_success "Deployment completed successfully for environment: $ENVIRONMENT"
log_info "Image: $IMAGE_TAG"
log_info "Namespace: $NAMESPACE"
log_info "Service: cm-hello-ts-service"

# Show how to access the service (if using port-forward)
log_info "To access the service locally, run:"
log_info "kubectl port-forward service/cm-hello-ts-service -n $NAMESPACE 8080:80"
log_info "Then visit: http://localhost:8080"