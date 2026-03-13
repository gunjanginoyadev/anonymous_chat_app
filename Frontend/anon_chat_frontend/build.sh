#!/bin/bash

# Fail on error
set -e

echo "🔥 Installing Flutter"
git clone https://github.com/flutter/flutter.git -b stable --depth 1
export PATH="$PATH:`pwd`/flutter/bin"

echo "📦 Getting dependencies"
flutter pub get

echo "🌐 Building Flutter Web"
flutter build web --release

echo "✅ Build finished"