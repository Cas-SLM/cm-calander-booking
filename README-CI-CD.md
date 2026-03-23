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
- **Platform**: Vercel
- **Environment**: Development
- **Auto-deploy**: Yes (on main branch)
- **Environment Variables**: `NODE_ENV=development`

### Test
- **Platform**: Vercel
- **Environment**: Preview
- **Auto-deploy**: Manual approval required
- **Environment Variables**: `NODE_ENV=test`

### Production
- **Platform**: Vercel
- **Environment**: Production
- **Auto-deploy**: Manual approval required
- **Environment Variables**: Production defaults

## Vercel Deployment

The deployment uses Vercel for all environments with the following configuration:

1. **Environment Variables**: Set per environment in Vercel dashboard
2. **Build Settings**: Uses pnpm for package management
3. **Output Directory**: `dist` (NestJS build output)
4. **Runtime**: Node.js 20

### Vercel Dashboard

Monitor deployments and configure environments through the Vercel dashboard:
- View deployment logs and status
- Configure environment variables
- Set up custom domains
- Monitor performance and analytics

### Environment URLs

- **Development**: `https://dev-<project>.vercel.app`
- **Test**: `https://<branch>-<project>.vercel.app`
- **Production**: `https://<project>.vercel.app`

## Security Features

1. **Dependency Scanning**: Automated security checks
2. **Container Scanning**: Trivy vulnerability scanning
3. **Secrets Management**: Encrypted GitHub secrets
4. **Image Signing**: Docker Hub image verification
5. **Vercel Security**: Built-in security features and isolation

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
   - Check Vercel project configuration
   - Verify environment variables in Vercel dashboard
   - Review build logs in Vercel

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

# Check Vercel deployment status
npx vercel --token $VERCEL_TOKEN --scope $VERCEL_ORG_ID
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
2. Review Vercel deployment status
3. Verify all required secrets are configured
4. Check Docker Hub image availability
5. Contact the DevOps team for assistance
