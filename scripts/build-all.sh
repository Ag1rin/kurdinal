#!/bin/bash
# Build script for all platforms (macOS/Linux)

VERSION=${1:-"1.0.0"}

echo "Building Kurdinal for all platforms..."
echo "Version: $VERSION"

# Detect OS
OS="$(uname -s)"
case "${OS}" in
    Linux*)
        echo "Detected Linux"
        ./scripts/build-linux.sh "$VERSION"
        ;;
    Darwin*)
        echo "Detected macOS"
        ./scripts/build-macos.sh "$VERSION"
        ;;
    *)
        echo "Unsupported OS: ${OS}"
        exit 1
        ;;
esac

