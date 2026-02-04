# Build script for Windows
param(
    [string]$Version = "1.0.0"
)

Write-Host "Building Kurdinal for Windows..." -ForegroundColor Green

# Clean previous builds
Write-Host "Cleaning previous builds..." -ForegroundColor Yellow
flutter clean

# Get dependencies
Write-Host "Getting dependencies..." -ForegroundColor Yellow
flutter pub get

# Generate localization
Write-Host "Generating localization files..." -ForegroundColor Yellow
flutter gen-l10n

# Generate code
Write-Host "Generating code..." -ForegroundColor Yellow
flutter pub run build_runner build --delete-conflicting-outputs

# Build Windows release
Write-Host "Building Windows release..." -ForegroundColor Yellow
flutter build windows --release

# Create archive
Write-Host "Creating archive..." -ForegroundColor Yellow
$archiveName = "kurdinal-windows-$Version.zip"
$buildPath = "build\windows\x64\runner\Release"

if (Test-Path $archiveName) {
    Remove-Item $archiveName
}

Compress-Archive -Path "$buildPath\*" -DestinationPath $archiveName -Force

Write-Host "Build complete! Archive: $archiveName" -ForegroundColor Green
Write-Host "Archive location: $(Resolve-Path $archiveName)" -ForegroundColor Cyan

