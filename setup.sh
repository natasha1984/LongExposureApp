#!/bin/bash

set -e

echo "🔧 Long Exposure App Setup"
echo "=========================="

# Check for XcodeGen
if ! command -v xcodegen &> /dev/null; then
    echo "📦 Installing XcodeGen..."
    brew install xcodegen
fi

# Navigate to project directory
cd "$(dirname "$0")"

# Generate Xcode project
echo "📝 Generating Xcode project..."
xcodegen generate

echo "✅ Setup complete!"
echo ""
echo "Open LongExposureApp.xcodeproj in Xcode to build and run."
