#!/bin/bash
# Build script for Linux

VERSION=${1:-"1.0.0"}

echo "Building Kurdinal for Linux..."

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

# Build Linux release
echo "Building Linux release..."
flutter build linux --release

# Create archive
echo "Creating archive..."
ARCHIVE_NAME="kurdinal-linux-$VERSION.tar.gz"
BUILD_PATH="build/linux/x64/release/bundle"

cd "$BUILD_PATH"
tar -czf "../../../../../../$ARCHIVE_NAME" *
cd ../../../../../../..

echo "Build complete! Archive: $ARCHIVE_NAME"
echo "Archive location: $(pwd)/$ARCHIVE_NAME"

