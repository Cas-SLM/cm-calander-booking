# Pre-Commit Hook Documentation

This document describes the pre-commit hook setup for the NestJS application that validates commit messages and runs quality checks.

## Overview

The pre-commit hook ensures code quality by automatically running checks before each commit:

1. **Commit Message Validation** - Enforces conventional commit format
2. **TypeScript Type Checking** - Validates TypeScript compilation
3. **ESLint** - Runs linting with your project configuration
4. **Prettier Formatting** - Checks code formatting (no auto-fix)
5. **Jest Tests** - Runs unit tests

## Installation

### Quick Setup

Run the setup script to install all hooks:

```bash
./scripts/setup-hooks.sh
```

### Manual Installation

1. Make the pre-commit script executable:
   ```bash
   chmod +x scripts/pre-commit.sh
   ```

2. Create symlink to git hooks directory:
   ```bash
   ln -sf "$(pwd)/scripts/pre-commit.sh" .git/hooks/pre-commit
   ```

3. Set up commit message template:
   ```bash
   git config commit.template .gitmessage
   ```

## Usage

### Automatic Operation

Once installed, the pre-commit hook runs automatically when you execute:

```bash
git commit -m "your commit message"
```

The hook will:
1. Validate your commit message format
2. Run all quality checks
3. Allow or block the commit based on results

### Manual Testing

Test the pre-commit script manually:

```bash
# Test with a valid commit message
echo "feat: add new feature" | ./scripts/pre-commit.sh /dev/stdin

# Test with an invalid commit message
echo "invalid commit message" | ./scripts/pre-commit.sh /dev/stdin
```

### Bypassing the Hook (Emergency Only)

In emergency situations, you can bypass the pre-commit hook:

```bash
git commit --no-verify -m "emergency commit"
```

**⚠️ Warning:** Only use this for genuine emergencies. Bypassing checks can introduce issues.

## Commit Message Format

### Conventional Commits

The hook enforces the [Conventional Commits](https://www.conventionalcommits.org/) specification:

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

### Valid Types

- `feat` - New feature
- `fix` - Bug fix
- `docs` - Documentation changes
- `style` - Code formatting (no logic changes)
- `refactor` - Code refactoring
- `test` - Adding or updating tests
- `chore` - Maintenance tasks
- `ci` - CI/CD changes
- `build` - Build system changes
- `perf` - Performance improvements

### Scope (Optional)

Scope is optional and describes the affected component:

```
feat(api): add user authentication
fix(database): resolve connection timeout
docs(readme): update installation instructions
```

### Description Rules

- Start with lowercase letter
- No trailing period
- Keep it concise but descriptive
- Use imperative mood ("add" not "added")

### Examples

✅ **Valid:**
```
feat: add user authentication system
fix(api): resolve CORS issues in login endpoint
docs: update API documentation for v2.0
style: format code according to Prettier rules
refactor: simplify database connection logic
test: add unit tests for auth service
chore: update dependencies to latest versions
ci: add Docker build step to pipeline
build: update webpack configuration
perf: optimize database queries for better performance
```

❌ **Invalid:**
```
Add new feature                    # Missing type
feat: Add new feature              # Should start with lowercase
fix: resolve bug.                  # Should not end with period
invalid: this is not a valid type  # Invalid type
```

### Special Cases

The hook skips validation for:
- Merge commits
- Empty commits
- WIP commits (starting with "WIP:")
- Squash commits (starting with "squash!")

## Quality Checks

### 1. TypeScript Type Checking

Runs `pnpm run build` to ensure:
- No TypeScript compilation errors
- All type definitions are correct
- Import/export statements are valid

### 2. ESLint

Executes `pnpm run lint` to check:
- Code style violations
- Potential bugs and errors
- Best practices adherence
- Your custom ESLint configuration

### 3. Prettier Formatting

Runs `pnpm run format --check` to verify:
- Code follows Prettier formatting rules
- No formatting inconsistencies
- Your custom Prettier configuration

**Note:** The hook only checks formatting, it doesn't auto-fix. Use `pnpm run format` to fix formatting issues.

### 4. Jest Tests

Executes `pnpm run test` to ensure:
- All unit tests pass
- No test failures or errors
- Test coverage requirements are met

## Configuration

### Package.json Scripts

The following scripts are available:

```json
{
  "scripts": {
    "pre-commit": "./scripts/pre-commit.sh",
    "setup-hooks": "./scripts/setup-hooks.sh install",
    "verify-hooks": "./scripts/setup-hooks.sh verify",
    "uninstall-hooks": "./scripts/setup-hooks.sh uninstall"
  }
}
```

### Running Individual Checks

You can run individual checks manually:

```bash
# TypeScript type checking
pnpm run build

# ESLint
pnpm run lint

# Prettier check
pnpm run format:check

# Tests
pnpm run test
```

## Troubleshooting

### Hook Not Running

1. Check if the hook file exists:
   ```bash
   ls -la .git/hooks/pre-commit
   ```

2. Verify it's a symlink to your script:
   ```bash
   readlink .git/hooks/pre-commit
   ```

3. Ensure the script is executable:
   ```bash
   chmod +x scripts/pre-commit.sh
   ```

### Commit Message Validation Errors

If you get commit message format errors:

1. Check the error message for specific format requirements
2. Use the commit template: `git config commit.template .gitmessage`
3. Follow the conventional commit format examples above

### Quality Check Failures

If quality checks fail:

1. **TypeScript errors**: Fix compilation issues in your code
2. **ESLint errors**: Address linting violations
3. **Prettier errors**: Run `pnpm run format` to fix formatting
4. **Test failures**: Fix failing tests

### Performance Issues

If the hook is slow:

1. Ensure you have dependency caching enabled
2. Check if tests are running efficiently
3. Consider using `--no-verify` for quick commits during development (not recommended for main branch)

## Maintenance

### Updating the Hook

To update the pre-commit script:

1. Edit `scripts/pre-commit.sh`
2. The changes take effect immediately for new commits

### Uninstalling Hooks

Remove all hooks:

```bash
./scripts/setup-hooks.sh uninstall
```

Or manually:

```bash
rm .git/hooks/pre-commit
git config --unset commit.template
```

### Verifying Installation

Check if hooks are properly installed:

```bash
./scripts/setup-hooks.sh verify
```

## Integration with CI/CD

The pre-commit hook complements your CI/CD pipeline by:

1. **Early Detection**: Catches issues before they reach the repository
2. **Faster Feedback**: Immediate feedback during development
3. **Consistency**: Ensures all commits meet quality standards
4. **Reduced CI Load**: Prevents broken commits from triggering CI builds

## Best Practices

1. **Write Good Commit Messages**: Use descriptive, conventional commit messages
2. **Test Before Committing**: Run checks locally before pushing
3. **Keep Commits Small**: Make focused, atomic commits
4. **Use Hooks Consistently**: Don't bypass hooks unless absolutely necessary
5. **Update Dependencies**: Keep your tooling up to date

## Support

For issues with the pre-commit hook:

1. Check the troubleshooting section above
2. Verify your project configuration
3. Ensure all dependencies are installed
4. Contact the development team for assistance