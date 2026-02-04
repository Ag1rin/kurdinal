# Release Guide

This guide explains how to create releases for Kurdinal.

## Automated Release (Recommended)

### Prerequisites
- GitHub repository with Actions enabled
- Write access to the repository

### Steps

1. **Update Version:**
   - Edit `pubspec.yaml` and update the version:
     ```yaml
     version: 1.0.1
     ```

2. **Update CHANGELOG.md:**
   - Add new version entry with changes

3. **Commit and Push:**
   ```bash
   git add .
   git commit -m "Release v1.0.1"
   git push
   ```

4. **Create and Push Tag:**
   ```bash
   git tag v1.0.1
   git push origin v1.0.1
   ```

5. **GitHub Actions will automatically:**
   - Build for Windows, macOS, and Linux
   - Create a GitHub Release
   - Upload all binaries

## Manual Release

If you prefer to build manually:

### Windows

```powershell
.\scripts\build-windows.ps1 -Version "1.0.1"
```

The archive will be created as `kurdinal-windows-1.0.1.zip`

### macOS

```bash
chmod +x scripts/build-macos.sh
./scripts/build-macos.sh 1.0.1
```

The archive will be created as `kurdinal-macos-1.0.1.tar.gz`

### Linux

```bash
chmod +x scripts/build-linux.sh
./scripts/build-linux.sh 1.0.1
```

The archive will be created as `kurdinal-linux-1.0.1.tar.gz`

### Create GitHub Release

1. Go to GitHub Releases
2. Click "Draft a new release"
3. Choose tag (e.g., `v1.0.1`)
4. Fill in release notes
5. Upload the three archives
6. Publish release

## Version Numbering

Follow [Semantic Versioning](https://semver.org/):
- **MAJOR**: Breaking changes
- **MINOR**: New features (backward compatible)
- **PATCH**: Bug fixes

Example: `1.2.3` = Major 1, Minor 2, Patch 3

## Release Checklist

- [ ] Update version in `pubspec.yaml`
- [ ] Update `CHANGELOG.md`
- [ ] Run tests: `flutter test`
- [ ] Run analysis: `flutter analyze`
- [ ] Build and test on all platforms
- [ ] Create tag and push
- [ ] Verify GitHub Actions completed successfully
- [ ] Test downloaded binaries
- [ ] Announce release

