#!/bin/bash
# Build script for macOS

VERSION=${1:-"1.0.0"}

echo "Building Kurdinal for macOS..."

# Clean previous builds
echo "Cleaning previous builds..."
flutter clean

# Get dependencies
echo "Getting dependencies..."
flutter pub get

# Generate localization
echo "Generating localization files..."
flutter gen-l10n

# Generate code
echo "Generating code..."
flutter pub run build_runner build --delete-conflicting-outputs

# Build macOS release
echo "Building macOS release..."
flutter build macos --release

# Create archive
echo "Creating archive..."
ARCHIVE_NAME="kurdinal-macos-$VERSION.tar.gz"
BUILD_PATH="build/macos/Build/Products/Release"

cd "$BUILD_PATH"
tar -czf "../../../../$ARCHIVE_NAME" kurdinal.app
cd ../../../../..

echo "Build complete! Archive: $ARCHIVE_NAME"
echo "Archive location: $(pwd)/$ARCHIVE_NAME"

