# Multi-Workflow CI/CD Architecture

This repository implements a secure, multi-workflow CI/CD pipeline that addresses supply chain integrity, security concerns, and architectural best practices.

## 🏗️ Architecture Overview

The pipeline is split into three specialized workflows:

### 1. **CI Workflow** (`.github/workflows/ci.yml`)
**Triggers:** Push to `main`/`release` branches, Pull Requests
**Purpose:** Continuous Integration - Build, test, scan, and push images

**Jobs:**
- **Code Quality** (Parallel): Lint, test, dependency scan
- **Build & Security**: Build application, create Docker image, security scan
- **Push Scanned Image**: Push the exact scanned image to registry

### 2. **Release Workflow** (`.github/workflows/release.yml`)
**Triggers:** Push to `release` branch
**Purpose:** Semantic release and main branch synchronization

**Jobs:**
- **Deploy to Development**: Deploy to dev environment
- **Semantic Release**: Version bump and GitHub release creation
- **Push Release Image**: Build and push release-tagged Docker image
- **Safe Merge**: Merge release to main using GitHub API

### 3. **Deploy Workflow** (`.github/workflows/deploy.yml`)
**Triggers:** GitHub releases, manual dispatch
**Purpose:** Environment deployments with manual control

**Jobs:**
- **Validate Deployment**: Input validation and environment selection
- **Deploy to Test**: Deploy to test environment
- **Deploy to Production**: Deploy to production (requires test success)
- **Post-Deployment**: Verification and summary

## 🔐 Security Improvements

### Supply Chain Integrity
- **Single Build, Multiple Uses**: Build once, scan, then push the exact same image
- **No Rebuilds**: Eliminates the risk of different images between scan and deployment
- **Artifact Preservation**: Build artifacts are reused across jobs

### Git Security
- **Full History**: `fetch-depth: 0` ensures semantic-release has complete history
- **Safe Merging**: Uses GitHub API for conflict-safe merges
- **Concurrency Control**: Prevents race conditions during releases

### Container Security
- **Fixed Action References**: Uses specific versions instead of `@master`
- **OIDC Integration**: Ready for OIDC-based cloud authentication
- **Multi-platform Builds**: Supports both AMD64 and ARM64

## 🚀 Deployment Flow

### Development Deployment
```bash
# Push to release branch
git push origin release

# Automatic flow:
1. CI: Build, test, scan
2. Release: Deploy to dev, semantic release, push release image
3. Safe merge: Release → Main
```

### Production Deployment
```bash
# Option 1: Via GitHub Release
1. Create GitHub release (automatically triggered by semantic-release)
2. Deploy workflow triggers automatically

# Option 2: Manual deployment
1. Go to Actions → Deploy Pipeline → Run workflow
2. Select environment (test/production)
3. Specify image tag if needed
```

## 📋 Environment Configuration

### Required Secrets
```bash
# Docker Hub
DOCKERHUB_USERNAME
DOCKERHUB_TOKEN

# Vercel
VERCEL_TOKEN
VERCEL_ORG_ID
VERCEL_PROJECT_ID

# GitHub
GITHUB_TOKEN (automatically available)
```

### Required Variables
```bash
# Docker Hub username
DOCKERHUB_USERNAME
```

### Environment URLs
- **Development**: `https://<project>-release.vercel.app`
- **Test**: `https://<project>-test.vercel.app`
- **Production**: `https://<project>.vercel.app`
- **Registry**: `https://hub.docker.com/r/<username>/<repository>`

## 🔧 Manual Operations

### Manual Test Deployment
```bash
# Run deploy workflow manually
gh workflow run deploy.yml -f environment=test -f image_tag=latest
```

### Manual Production Deployment
```bash
# Run deploy workflow manually
gh workflow run deploy.yml -f environment=production -f image_tag=v1.2.3
```

### Emergency Rollback
```bash
# Deploy previous version
gh workflow run deploy.yml -f environment=production -f image_tag=v1.2.2
```

## 📊 Monitoring & Observability

### GitHub Actions
- **Job Status**: Real-time status in Actions tab
- **Environment Protection**: Manual approval gates
- **Concurrency Control**: Prevents overlapping deployments

### Security Scanning
- **Trivy**: Vulnerability scanning with SARIF upload
- **SBOM Generation**: Software Bill of Materials
- **CodeQL**: Static analysis integration

### Deployment Tracking
- **Version Tags**: Semantic versioning with Git tags
- **Release Notes**: Auto-generated from commit messages
- **Deployment History**: Trackable through GitHub releases

## 🛠️ Troubleshooting

### Common Issues

#### 1. Merge Conflicts
```bash
# If automatic merge fails, a PR is created for manual review
# Check the "Auto-merge release to main" pull request
```

#### 2. Docker Build Failures
```bash
# Check CI workflow logs
# Verify Dockerfile syntax
# Check build context
```

#### 3. Vercel Deployment Issues
```bash
# Check Vercel dashboard for deployment logs
# Verify environment variables
# Check Vercel project configuration
```

#### 4. Semantic Release Failures
```bash
# Check commit message format (Conventional Commits)
# Verify git history depth
# Check semantic-release configuration
```

### Debug Commands
```bash
# Check workflow status
gh api repos/foo/bar/actions/runs

# Download workflow logs
gh api repos/foo/bar/actions/runs/123456789/logs

# Check deployment status
gh api repos/foo/bar/deployments
```

## 📈 Performance Optimizations

### Caching
- **Docker Build Cache**: GitHub Actions cache for faster builds
- **Node.js Cache**: pnpm cache for faster dependency installation
- **Build Artifacts**: Reused across jobs to avoid rebuilds

### Parallel Execution
- **Code Quality Jobs**: Run in parallel for faster feedback
- **Security Scans**: Independent of build process
- **Environment Deployments**: Can run concurrently when safe

### Resource Management
- **Concurrency Control**: Prevents resource conflicts
- **Job Dependencies**: Minimal dependencies for faster execution
- **Artifact Retention**: Configured retention policies

## 🔮 Future Enhancements

### Planned Improvements
- **Canary Deployments**: Gradual rollout to production
- **Blue-Green Deployments**: Zero-downtime deployments
- **Health Checks**: Post-deployment validation
- **Rollback Automation**: Automatic rollback on failure
- **Metrics Integration**: Performance monitoring integration

### Security Enhancements
- **SBOM Signing**: Cryptographic signing of SBOMs
- **Image Signing**: Container image signing with cosign
- **Policy Enforcement**: OPA/Gatekeeper integration
- **Secret Scanning**: Enhanced secret detection

## 📚 Additional Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Docker Buildx Documentation](https://docs.docker.com/build/)
- [Semantic Release Documentation](https://semantic-release.gitbook.io/semantic-release/)
- [Vercel Deployment Documentation](https://vercel.com/docs/deployments)
- [Trivy Scanner Documentation](https://aquasecurity.github.io/trivy/)

## 🤝 Contributing

When making changes to the CI/CD pipeline:

1. **Test Locally**: Use `act` or similar tools to test workflows locally
2. **Update Documentation**: Keep this README updated with any changes
3. **Security Review**: Ensure all security practices are maintained
4. **Performance Testing**: Verify no performance regressions
5. **Backward Compatibility**: Maintain compatibility with existing processes

## 📞 Support

For issues related to the CI/CD pipeline:

1. **Check Logs**: Review GitHub Actions logs first
2. **Search Issues**: Check existing issues for similar problems
3. **Create Issue**: Provide detailed reproduction steps
4. **Contact Team**: Reach out to the DevOps team for complex issues