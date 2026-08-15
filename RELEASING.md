# Release Process

This document outlines the steps to create and publish a new release for Tide.

## 1. Versioning

Tide follows [Semantic Versioning](https://semver.org/).
Version information is tracked in [pubspec.yaml](file:///Users/dariocastellano/Workspaces/Others/tide-notes/pubspec.yaml):

```yaml
version: x.y.z+build
```

- `x.y.z`: Public release version (e.g. `1.3.0`)
- `+build`: Incremental build number (e.g. `+8`)

## 2. Pre-release Checks

Before creating a release tag, make sure all local checks pass:

```bash
# Check code formatting
dart format --output=none --set-exit-if-changed lib test integration_test

# Design token check
bash tool/design_token_lint.sh

# Static analysis
flutter analyze

# Automated test suite
flutter test
```

## 3. Creating a Release

### Automated via Tag Push (Recommended)

1. Make sure you are on `main` and your working tree is clean:
   ```bash
   git checkout main
   git pull origin main
   ```

2. Create an annotated Git tag with the version prefix `v`:
   ```bash
   git tag -a v1.3.0 -m "Release v1.3.0"
   ```

3. Push the tag to GitHub:
   ```bash
   git push origin v1.3.0
   ```

The [Release workflow](file:///Users/dariocastellano/Workspaces/Others/tide-notes/.github/workflows/release.yml) will trigger automatically, build:
- **Android APKs**: Universal APK and split per-ABI APKs (`arm64-v8a`, `armeabi-v7a`, `x86_64`)
- **macOS App**: `.zip` archive containing `Tide.app`
- **SHA256 Checksums**: `SHA256SUMS.txt`

It will then publish a new **GitHub Release** with the binaries attached and auto-generated release notes.

---

### Manual Trigger via GitHub Actions

You can also trigger a release manually:
1. Navigate to **Actions** > **Release** in your GitHub repository.
2. Click **Run workflow**.
3. (Optional) Provide a `tag_name` (e.g., `v1.3.0`).
4. Click **Run workflow**.
