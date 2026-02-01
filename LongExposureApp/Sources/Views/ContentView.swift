import SwiftUI
import PhotosUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedItem: PhotosPickerItem?
    @State private var showExamplePicker = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if appState.generatedImage != nil {
                    ResultView()
                } else if appState.selectedVideoURL != nil {
                    ProcessingView()
                } else {
                    SelectionView(
                        selectedItem: $selectedItem,
                        showExamplePicker: $showExamplePicker
                    )
                }
            }
            .navigationTitle("Long Exposure")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if appState.selectedVideoURL != nil {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Reset") {
                            appState.reset()
                        }
                    }
                }
            }
            .sheet(isPresented: $showExamplePicker) {
                ExampleVideoPicker()
            }
        }
    }
}

struct SelectionView: View {
    @EnvironmentObject var appState: AppState
    @Binding var selectedItem: PhotosPickerItem?
    @Binding var showExamplePicker: Bool

    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "video.fill")
                .font(.system(size: 80))
                .foregroundStyle(.secondary)

            Text("Create Long Exposure from Video")
                .font(.title2)
                .fontWeight(.medium)

            Text("Select a video to extract frames, align them, and create a stunning long-exposure effect")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            PhotosPicker(selection: $selectedItem, matching: .videos) {
                Label("Choose Video", systemImage: "film")
                    .font(.headline)
                    .frame(maxWidth: 200)
            }
            .buttonStyle(.borderedProminent)
            .padding(.top)

            Divider()
                .padding(.horizontal, 40)

            Button {
                showExamplePicker = true
            } label: {
                Label("Load Example Video", systemImage: "square.stack.3d.up")
                    .font(.headline)
                    .frame(maxWidth: 200)
            }
            .buttonStyle(.bordered)

            Spacer()
        }
        .padding()
        .onChange(of: selectedItem) { newValue in
            Task {
                if let newValue {
                    await loadVideo(from: newValue)
                }
            }
        }
    }

    private func loadVideo(from item: PhotosPickerItem) async {
        do {
            if let movie = try await item.loadTransferable(type: VideoTransferable.self) {
                await MainActor.run {
                    appState.selectedVideoURL = movie.url
                    Task {
                        await processVideo()
                    }
                }
            }
        } catch {
            await MainActor.run {
                appState.errorMessage = "Failed to load video: \(error.localizedDescription)"
            }
        }
    }

    private func processVideo() async {
        guard let videoURL = appState.selectedVideoURL else { return }

        appState.isProcessing = true
        appState.processingProgress = 0.0

        do {
            let frames = try await appState.videoService.extractFrames(from: videoURL)

            await MainActor.run {
                appState.extractedFrames = frames
                appState.processingProgress = 1.0
            }

            await MainActor.run {
                appState.processingProgress = 0.0
                appState.isAligned = false
            }

            let alignedFrames = await appState.alignmentService.alignFrames(frames)

            await MainActor.run {
                appState.extractedFrames = alignedFrames
                appState.isAligned = true
                appState.processingProgress = 1.0
            }

            await MainActor.run {
                appState.processingProgress = 0.0
            }

            let result = await appState.blendingService.createLongExposure(from: alignedFrames)

            await MainActor.run {
                appState.generatedImage = result
                appState.isProcessing = false
            }
        } catch {
            await MainActor.run {
                appState.errorMessage = error.localizedDescription
                appState.isProcessing = false
            }
        }
    }
}

struct ExampleVideoPicker: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    @State private var isGeneratingVideo = false

    let exampleVideos = [
        ("test.mov", "Test Video (Water)", "video.fill"),
        ("water_droplets.mov", "Water Droplets", "drop.fill"),
        ("light_trails.mov", "Light Trails", "bolt.fill"),
        ("fireworks.mov", "Fireworks", "sparkles"),
        ("clouds.mov", "Moving Clouds", "cloud.fill")
    ]

    var body: some View {
        NavigationStack {
            List {
                Section("Built-in Test Videos") {
                    ForEach(exampleVideos, id: \.0) { _, name, icon in
                        Button {
                            loadExampleVideo(named: name)
                        } label: {
                            HStack {
                                Image(systemName: icon)
                                    .foregroundStyle(.blue)
                                    .frame(width: 30)
                                Text(name)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .foregroundStyle(.primary)
                    }
                }

                Section("Generate Test Videos") {
                    Button {
                        Task {
                            isGeneratingVideo = true
                            await generateTestVideo(type: .waterDroplets)
                            isGeneratingVideo = false
                        }
                    } label: {
                        HStack {
                            Image(systemName: "drop.fill")
                                .foregroundStyle(.blue)
                                .frame(width: 30)
                            Text("Water Droplets Effect")
                            Spacer()
                            if isGeneratingVideo {
                                ProgressView()
                            }
                        }
                    }
                    .disabled(isGeneratingVideo)

                    Button {
                        Task {
                            isGeneratingVideo = true
                            await generateTestVideo(type: .lightTrails)
                            isGeneratingVideo = false
                        }
                    } label: {
                        HStack {
                            Image(systemName: "bolt.fill")
                                .foregroundStyle(.yellow)
                                .frame(width: 30)
                            Text("Light Trails Effect")
                            Spacer()
                            if isGeneratingVideo {
                                ProgressView()
                            }
                        }
                    }
                    .disabled(isGeneratingVideo)

                    Button {
                        Task {
                            isGeneratingVideo = true
                            await generateTestVideo(type: .clouds)
                            isGeneratingVideo = false
                        }
                    } label: {
                        HStack {
                            Image(systemName: "cloud.fill")
                                .foregroundStyle(.gray)
                                .frame(width: 30)
                            Text("Moving Clouds Effect")
                            Spacer()
                            if isGeneratingVideo {
                                ProgressView()
                            }
                        }
                    }
                    .disabled(isGeneratingVideo)
                }
            }
            .navigationTitle("Example Videos")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func loadExampleVideo(named filename: String) {
        if let url = Bundle.main.url(forResource: filename, withExtension: nil) {
            Task {
                await MainActor.run {
                    appState.selectedVideoURL = url
                    Task {
                        await processVideo()
                    }
                }
            }
        }
        dismiss()
    }

    private func processVideo() async {
        guard let videoURL = appState.selectedVideoURL else { return }

        appState.isProcessing = true
        appState.processingProgress = 0.0

        do {
            let frames = try await appState.videoService.extractFrames(from: videoURL)

            await MainActor.run {
                appState.extractedFrames = frames
                appState.processingProgress = 1.0
            }

            await MainActor.run {
                appState.processingProgress = 0.0
                appState.isAligned = false
            }

            let alignedFrames = await appState.alignmentService.alignFrames(frames)

            await MainActor.run {
                appState.extractedFrames = alignedFrames
                appState.isAligned = true
                appState.processingProgress = 1.0
            }

            await MainActor.run {
                appState.processingProgress = 0.0
            }

            let result = await appState.blendingService.createLongExposure(from: alignedFrames)

            await MainActor.run {
                appState.generatedImage = result
                appState.isProcessing = false
            }
        } catch {
            await MainActor.run {
                appState.errorMessage = error.localizedDescription
                appState.isProcessing = false
            }
        }
        dismiss()
    }

    private func generateTestVideo(type: TestVideoType) async {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(type.filename).mov")

        do {
            try await VideoGenerator.generateTestVideo(
                url: tempURL,
                size: CGSize(width: 640, height: 480),
                duration: 3.0,
                type: type
            )

            await MainActor.run {
                appState.selectedVideoURL = tempURL
            }

            await processVideo()
        } catch {
            print("Failed to generate test video: \(error)")
        }
    }
}

enum TestVideoType {
    case waterDroplets
    case lightTrails
    case clouds

    var filename: String {
        switch self {
        case .waterDroplets: return "generated_water"
        case .lightTrails: return "generated_lights"
        case .clouds: return "generated_clouds"
        }
    }
}
