# Contributing to Kurdinal

Thank you for your interest in contributing to Kurdinal! This document provides guidelines and instructions for contributing.

## Getting Started

1. Fork the repository
2. Clone your fork: `git clone https://github.com/YOUR_USERNAME/kurdinal.git`
3. Create a branch: `git checkout -b feature/your-feature-name`
4. Make your changes
5. Test your changes
6. Submit a pull request

## Development Setup

1. **Install Flutter:**
   - Follow the [Flutter installation guide](https://flutter.dev/docs/get-started/install)
   - Ensure Flutter 3.24.0 or higher is installed

2. **Get dependencies:**
   ```bash
   flutter pub get
   ```

3. **Generate code:**
   ```bash
   flutter gen-l10n
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

4. **Run the app:**
   ```bash
   flutter run
   ```

## Code Style

- Follow [Dart style guide](https://dart.dev/guides/language/effective-dart/style)
- Run `flutter analyze` before committing
- Use meaningful commit messages

## Testing

- Write tests for new features
- Run tests: `flutter test`
- Ensure all tests pass before submitting PR

## Pull Request Process

1. Update CHANGELOG.md with your changes
2. Ensure all tests pass
3. Run `flutter analyze` and fix any issues
4. Update documentation if needed
5. Submit PR with clear description

## Reporting Issues

When reporting issues, please include:
- OS and version
- Flutter version
- Steps to reproduce
- Expected vs actual behavior
- Screenshots if applicable

## Feature Requests

Feature requests are welcome! Please open an issue with:
- Clear description
- Use case
- Proposed solution (if any)

## Questions?

Feel free to open an issue for questions or discussions.

