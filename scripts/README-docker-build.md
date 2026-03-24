# Docker Build Script

A comprehensive shell script that extracts version information from `package.json` and builds Docker images with proper tagging.

## Features

- ✅ **Automatic Version Extraction**: Reads version from `package.json`
- ✅ **Multiple Tagging**: Creates both version-specific and `latest` tags
- ✅ **Registry Support**: Supports custom Docker registries
- ✅ **Error Handling**: Comprehensive error checking and logging
- ✅ **Colorful Output**: Easy-to-read colored logging
- ✅ **Command Line Arguments**: Flexible configuration options
- ✅ **Fallback Methods**: Works with or without `jq` installed

## Usage

### Basic Usage

```bash
# Build with default image name (cm-hello-ts)
./scripts/docker-build.sh
```

### Custom Image Name

```bash
# Build with custom image name
./scripts/docker-build.sh -n my-app
./scripts/docker-build.sh --name my-app
```

### With Docker Registry

```bash
# Build and tag for a specific registry
./scripts/docker-build.sh -n my-app -r docker.io/username
./scripts/docker-build.sh --name my-app --registry docker.io/username
```

### Help

```bash
# Show help and usage information
./scripts/docker-build.sh -h
./scripts/docker-build.sh --help
```

## Command Line Options

| Option | Long Form | Description | Default |
|--------|-----------|-------------|---------|
| `-n` | `--name` | Docker image name | `cm-hello-ts` |
| `-r` | `--registry` | Docker registry URL | (none) |
| `-h` | `--help` | Show help message | - |

## Output Tags

The script creates the following Docker image tags:

### Without Registry
```
cm-hello-ts:0.0.1
cm-hello-ts:latest
```

### With Registry
```
docker.io/username/cm-hello-ts:0.0.1
docker.io/username/cm-hello-ts:latest
```

## Version Extraction

The script extracts the version from `package.json` using two methods:

1. **Primary Method**: Uses `jq` if available
   ```bash
   jq -r '.version' package.json
   ```

2. **Fallback Method**: Uses `grep` and `sed` if `jq` is not installed
   ```bash
   grep -E '"version":' package.json | sed -E 's/.*"version":\s*"([^"]+)".*/\1/'
   ```

## Build Arguments

The script passes the extracted version as a build argument to Docker:

```bash
docker build --build-arg VERSION=0.0.1 -t image:0.0.1 -t image:latest .
```

This allows you to use the version in your `Dockerfile`:

```dockerfile
ARG VERSION
LABEL version=$VERSION
```

## Error Handling

The script includes comprehensive error handling for:

- Missing `package.json` file
- Invalid version format
- Docker not being installed
- Docker build failures

## Logging Levels

- **[INFO]**: Blue text for general information
- **[SUCCESS]**: Green text for successful operations
- **[WARNING]**: Yellow text for non-critical issues
- **[ERROR]**: Red text for critical errors

## Examples

### Example 1: Basic Build
```bash
$ ./scripts/docker-build.sh
[INFO] Starting Docker build process...
[INFO] Project root: /home/user/project
[INFO] Extracting version from package.json...
[SUCCESS] Version extracted: 1.2.3
[INFO] Building Docker image with version: 1.2.3
[INFO] Running: docker build --build-arg VERSION=1.2.3 -t cm-hello-ts:1.2.3 -t cm-hello-ts:latest .
[SUCCESS] Docker image built successfully
[INFO] Image tags created:
[INFO]   - cm-hello-ts:1.2.3
[INFO]   - cm-hello-ts:latest
[SUCCESS] Docker build completed successfully!
[INFO] Image is ready for deployment
```

### Example 2: With Registry
```bash
$ ./scripts/docker-build.sh -n my-app -r docker.io/myuser
[INFO] Starting Docker build process...
[INFO] Project root: /home/user/project
[INFO] Extracting version from package.json...
[SUCCESS] Version extracted: 2.1.0
[INFO] Building Docker image with version: 2.1.0
[INFO] Running: docker build --build-arg VERSION=2.1.0 -t docker.io/myuser/my-app:2.1.0 -t docker.io/myuser/my-app:latest .
[SUCCESS] Docker image built successfully
[INFO] Image tags created:
[INFO]   - docker.io/myuser/my-app:2.1.0
[INFO]   - docker.io/myuser/my-app:latest
[SUCCESS] Docker build completed successfully!
[INFO] Image is ready for deployment
```

## Integration with CI/CD

This script can be easily integrated into your CI/CD pipeline:

```yaml
# Example GitHub Actions step
- name: Build Docker Image
  run: ./scripts/docker-build.sh -n ${{ github.repository }} -r ${{ env.REGISTRY }}
```

## Requirements

- **Docker**: Must be installed and accessible
- **Node.js Project**: Must have a `package.json` file with a `version` field
- **Optional**: `jq` for better JSON parsing (falls back to grep/sed if not available)

## Troubleshooting

### Common Issues

1. **"package.json not found"**
   - Ensure you're running the script from the correct directory
   - Check that `package.json` exists in the project root

2. **"Could not extract version"**
   - Verify that `package.json` has a valid `version` field
   - Check that the version format is valid (e.g., "1.0.0")

3. **"Docker is not installed"**
   - Install Docker and ensure it's in your PATH
   - Verify Docker is running

4. **"Docker build failed"**
   - Check that your `Dockerfile` is valid
   - Ensure you have the necessary permissions
   - Check Docker daemon status

### Debug Mode

For debugging, you can run the script with bash tracing:

```bash
bash -x ./scripts/docker-build.sh
```

## Security Notes

- The script uses `set -e` to exit on any error
- All external commands are properly quoted
- Input validation is performed on all user inputs
- The script runs with the permissions of the user executing it

## Contributing

To contribute to this script:

1. Test your changes thoroughly
2. Ensure backward compatibility
3. Update this README if needed
4. Follow the existing code style and conventions