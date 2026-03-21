# CI/CD Pipeline Documentation

This document describes the GitHub Actions CI/CD pipeline for the NestJS application.

## Overview

The pipeline provides a complete DevOps workflow including:
- Code quality checks (ESLint, Prettier)
- Automated testing with coverage
- Docker image building and security scanning
- Multi-environment Kubernetes deployments
- Version management and artifact handling

## Pipeline Structure

### Stage 1: Code Quality & Testing (Parallel)

1. **Install Dependencies** (`install-deps`)
   - Sets up Node.js and pnpm
   - Caches dependencies for performance
   - Installs project dependencies

2. **Code Quality** (`lint-format`)
   - Runs Prettier formatting check
   - Executes ESLint with error reporting
   - Fails fast on code quality issues

3. **Test with Coverage** (`test-coverage`)
   - Runs Jest tests with coverage reporting
   - Uploads coverage to Codecov (optional)
   - Provides detailed test results

### Stage 2: Build & Security

4. **Build Application** (`build`)
   - Compiles TypeScript to JavaScript
   - Generates build artifacts
   - Creates version information

5. **Docker Build** (`docker-build`)
   - Builds multi-platform Docker images
   - Uses build caching for performance
   - Creates image artifacts for testing

6. **Security Scan** (`security-scan`)
   - Runs Trivy vulnerability scanner
   - Reports security issues to GitHub Security tab
   - Provides SARIF format reports

### Stage 3: Deploy (Sequential)

7. **Version Management** (`version-bump`)
   - Bumps patch version automatically
   - Creates Git tags for releases
   - Commits version changes

8. **Docker Push** (`docker-push`)
   - Pushes images to Docker Hub
   - Tags with version and latest
   - Uses multi-platform support

9. **Deploy to Development** (`deploy-dev`)
   - Deploys to development environment
   - Creates Kubernetes resources
   - Monitors deployment status

10. **Deploy to Test** (`deploy-test`)
    - Deploys to test environment
    - Requires manual approval
    - Validates deployment

11. **Deploy to Production** (`deploy-prod`)
    - Deploys to production environment
    - Requires manual approval
    - Final deployment stage

## Triggers

- **Push to main**: Full pipeline execution
- **Push to release/***: Build and deploy (no version bump)
- **Pull Request**: Code quality and testing only

## Environment Configuration

### Required Secrets

Add these secrets to your GitHub repository:

```bash
# Docker Hub credentials
DOCKERHUB_USERNAME=your_dockerhub_username
DOCKERHUB_TOKEN=your_dockerhub_access_token

# Optional: Codecov for coverage reporting
CODECOV_TOKEN=your_codecov_token

# Kubernetes configuration
KUBE_CONFIG=base64_encoded_kubeconfig
```

### Environment Variables

The pipeline uses these environment variables:

```bash
REGISTRY=docker.io                    # Container registry
IMAGE_NAME=${{ github.repository }}   # Image name
NODE_VERSION=20                       # Node.js version
```

## Deployment Environments

### Development
- **Namespace**: `cm-hello-ts-dev`
- **Replicas**: 1
- **Resources**: 128Mi memory, 100m CPU
- **Auto-deploy**: Yes (on main branch)

### Test
- **Namespace**: `cm-hello-ts-test`
- **Replicas**: 1
- **Resources**: 128Mi memory, 100m CPU
- **Auto-deploy**: Manual approval required

### Production
- **Namespace**: `cm-hello-ts-prod`
- **Replicas**: 3 (with HPA up to 10)
- **Resources**: 512Mi memory, 500m CPU
- **Auto-deploy**: Manual approval required
- **Autoscaling**: CPU 70%, Memory 80%

## Kubernetes Resources

The deployment creates:

1. **Namespace**: Environment-specific namespace
2. **ConfigMap**: Application configuration
3. **Secret**: Docker registry credentials
4. **Deployment**: Application pods
5. **Service**: ClusterIP service
6. **HPA**: Horizontal Pod Autoscaler (production only)

## Monitoring and Logs

### Deployment Status
```bash
# Check deployment status
kubectl get deployment cm-hello-ts-dev -n cm-hello-ts-dev

# View pod logs
kubectl logs -f deployment/cm-hello-ts-dev -n cm-hello-ts-dev

# Check rollout history
kubectl rollout history deployment/cm-hello-ts-dev -n cm-hello-ts-dev
```

### Local Access
```bash
# Port forward to access service locally
kubectl port-forward service/cm-hello-ts-service -n cm-hello-ts-dev 8080:80

# Access application
curl http://localhost:8080
```

## Security Features

1. **Dependency Scanning**: Automated security checks
2. **Container Scanning**: Trivy vulnerability scanning
3. **Secrets Management**: Encrypted GitHub secrets
4. **Image Signing**: Docker Hub image verification
5. **RBAC**: Kubernetes role-based access control

## Troubleshooting

### Common Issues

1. **Build Failures**
   - Check Node.js version compatibility
   - Verify pnpm lockfile is up to date
   - Review TypeScript compilation errors

2. **Test Failures**
   - Check Jest configuration
   - Verify test coverage thresholds
   - Review test environment setup

3. **Deployment Failures**
   - Check Kubernetes cluster connectivity
   - Verify Docker image availability
   - Review resource limits and requests

4. **Security Scan Failures**
   - Review vulnerability reports in GitHub Security tab
   - Update base images to latest versions
   - Address critical and high severity issues

### Debug Commands

```bash
# Check workflow run status
gh api repos/foo/bar/actions/runs

# Download workflow logs
gh api repos/foo/bar/actions/runs/123456789/logs

# Check Kubernetes events
kubectl get events -n cm-hello-ts-dev --sort-by=.metadata.creationTimestamp
```

## Best Practices

1. **Branch Strategy**: Use feature branches and pull requests
2. **Commit Messages**: Use conventional commits for version bumping
3. **Environment Parity**: Keep environments consistent
4. **Monitoring**: Set up alerts for deployment failures
5. **Security**: Regularly update dependencies and base images
6. **Documentation**: Keep this documentation up to date

## Support

For issues with the CI/CD pipeline:

1. Check the GitHub Actions workflow logs
2. Review Kubernetes deployment status
3. Verify all required secrets are configured
4. Check Docker Hub image availability
5. Contact the DevOps team for assistance