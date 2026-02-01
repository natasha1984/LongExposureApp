# Long Exposure App

An iOS app that extracts frames from videos, aligns them to handle camera shake, and creates stunning long-exposure effects.

## Features

- 🎥 Video import from Photos library
- 📁 Load built-in example videos
- 🧪 Generate test videos on-device
- 🖼️ Frame extraction with configurable interval
- 🔧 Automatic image alignment for shaky footage
- ✨ Average blending mode for long-exposure effects
- 💾 Save and share your creations

## Requirements

- iOS 16.0+
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

### Option 1: Choose from Photos
1. Tap "Choose Video" to select a video from your Photos
2. Wait for frame extraction and alignment
3. Watch as your long-exposure image is created
4. Save or share your result

### Option 2: Load Example Videos
1. Tap "Load Example Video"
2. Choose from built-in test videos:
   - **test.mov** - Water droplets video
   - **Water Droplets** - Generated falling water effect
   - **Light Trails** - Generated moving light trails
   - **Fireworks** - Generated burst effect
   - **Moving Clouds** - Generated drifting clouds

### Option 3: Generate Test Videos
1. Tap "Load Example Video"
2. Scroll to "Generate Test Videos"
3. Choose a type (Water Droplets, Light Trails, or Moving Clouds)
4. Watch the video generate and process automatically

## How It Works

1. **Frame Extraction**: Uses `AVAssetImageGenerator` to extract frames at regular intervals
2. **Image Alignment**: Centers all frames to handle camera shake
3. **Long Exposure**: Averages pixel values across all frames to create light trail/water effects

## Project Structure

```
LongExposureApp/
├── project.yml              # XcodeGen configuration
├── setup.sh                 # Setup script
├── README.md
├── LongExposureApp.xcodeproj/
└── LongExposureApp/
    ├── Sources/
    │   ├── App/
    │   │   └── LongExposureApp.swift
    │   ├── Models/
    │   │   └── AppState.swift
    │   ├── Services/
    │   │   ├── VideoFrameExtractor.swift
    │   │   ├── ImageAlignmentService.swift
    │   │   └── ImageBlendingService.swift
    │   └── Views/
    │       ├── ContentView.swift
    │       └── ProcessingView.swift
    └── Resources/
        ├── Assets.xcassets/
        ├── Info.plist
        └── SampleVideos/
            └── test.mov
```

## Testing the App

### Quick Test
1. Run the app on simulator
2. Tap "Load Example Video"
3. Select "Test Video (Water)"
4. Wait for processing (~10-20 seconds)
5. View and save the result

### Generate Custom Videos
1. Tap "Load Example Video"
2. Select "Generate Test Videos"
3. Choose "Water Droplets Effect" or "Light Trails Effect"
4. Watch the video generate (3 seconds at 30fps = 90 frames)
5. See the long-exposure result

### Expected Results

- **Water Droplets**: Creates smooth, flowing water effect with trails
- **Light Trails**: Creates colorful light streak effects
- **Moving Clouds**: Creates soft, dreamy cloud blur effect

## Tips

- Longer videos = smoother results but longer processing time
- Videos with moving light sources create the best long-exposure effects
- Use "Load Example Video" to test the app quickly

## License

MIT License
