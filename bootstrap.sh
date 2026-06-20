#!/usr/bin/env bash
set -euo pipefail

# Bootstrap script: creates a proper Flutter project and merges our source code.
# Requires Flutter SDK with Linux desktop support.
# Run: chmod +x bootstrap.sh && ./bootstrap.sh

PROJECT_NAME="screen_share"
SOURCE_DIR="$(cd "$(dirname "$0")" && pwd)"
TEMP_DIR=$(mktemp -d)

echo "==> Creating temporary Flutter project in $TEMP_DIR"
cd "$TEMP_DIR"
flutter create --org com.screenshare --platforms=linux "$PROJECT_NAME"
cd "$PROJECT_NAME"

echo "==> Removing auto-generated lib/ content"
rm -rf lib/*
rm -rf test/*

echo "==> Copying source files from $SOURCE_DIR"
cp -r "$SOURCE_DIR/lib/" lib/
cp -r "$SOURCE_DIR/test/" test/
cp "$SOURCE_DIR/pubspec.yaml" pubspec.yaml
cp "$SOURCE_DIR/analysis_options.yaml" analysis_options.yaml

echo "==> Running pub get"
flutter pub get

echo "==> Running flutter analyze"
flutter analyze

echo "==> Build complete! Project ready at: $TEMP_DIR/$PROJECT_NAME"
echo ""
echo "To run:"
echo "  cd $TEMP_DIR/$PROJECT_NAME"
echo "  flutter run -d linux"
echo ""
echo "Note: Set environment variables before running:"
echo "  export LIVEKIT_URL=ws://localhost:7880"
echo "  export LIVEKIT_API_KEY=devkey"
echo "  export LIVEKIT_API_SECRET=secret"
echo ""
echo "Or use the --dart-define approach:"
echo "  flutter run -d linux --dart-define=LIVEKIT_URL=ws://... --dart-define=LIVEKIT_API_KEY=devkey --dart-define=LIVEKIT_API_SECRET=secret"
