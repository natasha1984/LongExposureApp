# Long Exposure App

An iOS app that extracts frames from videos, aligns them to handle camera shake, and creates stunning long-exposure effects.

## Features

- 🎥 Video import from Photos library
- 🖼️ Frame extraction with configurable interval
- 🔧 Automatic image alignment for shaky footage
- ✨ Multiple blending modes for long-exposure effects
- 💾 Save and share your creations

## Requirements

- iOS 15.0+
- Xcode 15.0+
- XcodeGen (`brew install xcodegen`)

## Setup

1. Install XcodeGen:
   ```bash
   brew install xcodegen
   ```

2. Generate Xcode project:
   ```bash
   ./setup.sh
   ```

3. Open `LongExposureApp.xcodeproj` in Xcode

4. Build and run on a device or simulator

## Usage

1. Tap "Choose Video" to select a video from your Photos
2. Wait for frame extraction and alignment
3. Watch as your long-exposure image is created
4. Save or share your result

## License

MIT License
