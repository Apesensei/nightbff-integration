# Local Development Setup

This document explains how to set up your local development environment to match the project's Node.js version requirements.

## Node.js Version Management

This project requires **Node.js 20** for consistency across all environments (local, CI, and production).

### Version Files

The repository includes two files to help manage Node.js versions:

- **`.nvmrc`** - For nvm (Node Version Manager) users
- **`.tool-versions`** - For asdf users

### Setup Instructions

#### Option 1: Using nvm (Recommended for macOS/Linux)

1. **Install nvm** (if not already installed):

   ```bash
   curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
   # Restart your terminal or run: source ~/.bashrc
   ```

2. **Use the project's Node version**:

   ```bash
   # Install and use Node 20 (automatically reads .nvmrc)
   nvm use

   # Or explicitly install if not present
   nvm install 20
   nvm use 20
   ```

3. **Set as default** (optional):
   ```bash
   nvm alias default 20
   ```

#### Option 2: Using asdf (Cross-platform)

1. **Install asdf** (if not already installed):

   ```bash
   # macOS
   brew install asdf

   # Linux
   git clone https://github.com/asdf-vm/asdf.git ~/.asdf
   echo '. ~/.asdf/asdf.sh' >> ~/.bashrc
   ```

2. **Add Node.js plugin**:

   ```bash
   asdf plugin add nodejs
   ```

3. **Install and use the project's Node version**:

   ```bash
   # Install Node 20 (automatically reads .tool-versions)
   asdf install

   # Set local version for this project
   asdf local nodejs 20.18.0
   ```

#### Option 3: Manual Installation

1. Download Node.js 20 from [nodejs.org](https://nodejs.org/)
2. Install following the official instructions
3. Verify version: `node --version` (should show v20.x.x)

## Verification

### Pre-commit Hook Verification

The pre-commit hook will automatically check your Node.js version and provide helpful guidance:

```bash
# This runs automatically on git commit
🔧 Verifying Node version alignment...
   .nvmrc specifies: Node 20
   .tool-versions specifies: Node 20
   Current local version: Node 20
✅ Local Node version is compatible
```

### Manual Verification

You can also run the Node alignment validator manually:

```bash
./scripts/validate-node-alignment.sh
```

## Troubleshooting

### "Command not found" errors

If you get errors about nvm or asdf not being found:

1. **For nvm**: Make sure your shell profile (`.bashrc`, `.zshrc`) sources nvm
2. **For asdf**: Ensure asdf is properly installed and sourced in your shell

### Version mismatch warnings

If the pre-commit hook warns about version mismatches:

1. **Using nvm**: Run `nvm use` in the project directory
2. **Using asdf**: Run `asdf local nodejs 20.18.0`
3. **Manual**: Install Node.js 20 from nodejs.org

### npm/Node.js compatibility

The project specifies minimum versions in `package.json`:

- Node.js: `>=20.0.0`
- npm: `>=9.0.0`

Modern Node.js 20 installations include compatible npm versions automatically.

## IDE Integration

### VS Code

Add to your workspace settings (`.vscode/settings.json`):

```json
{
  "typescript.preferences.includePackageJsonAutoImports": "on",
  "typescript.suggest.autoImports": true,
  "npm.packageManager": "npm"
}
```

### Other IDEs

Most modern IDEs will automatically detect the Node.js version from:

1. The `engines` field in `package.json`
2. The `.nvmrc` file
3. The local Node.js installation

## Why Node.js 20?

- **LTS (Long Term Support)**: Stable and supported until April 2026
- **Performance**: Significant improvements in V8 engine
- **Security**: Latest security patches and features
- **Ecosystem**: Compatible with latest npm packages
- **CI/CD**: Matches our GitHub Actions and Docker configurations

## Getting Help

If you encounter issues with Node.js version management:

1. Check the [Node.js documentation](https://nodejs.org/docs/)
2. Check the [nvm documentation](https://github.com/nvm-sh/nvm#readme)
3. Check the [asdf documentation](https://asdf-vm.com/guide/getting-started.html)
4. Ask for help in the team chat
