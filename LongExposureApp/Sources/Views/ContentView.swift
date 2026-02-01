import SwiftUI
import PhotosUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if appState.generatedImage != nil {
                    ResultView()
                } else if appState.selectedVideoURL != nil {
                    ProcessingView()
                } else {
                    SelectionView()
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
        }
    }
}

struct SelectionView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedItem: PhotosPickerItem?

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

struct VideoTransferable: Transferable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { movie in
            SentTransferredFile(movie.url)
        } importing: { received in
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(received.file.lastPathComponent)
            if FileManager.default.fileExists(atPath: tempURL.path) {
                try FileManager.default.removeItem(at: tempURL)
            }
            try FileManager.default.copyItem(at: received.file, to: tempURL)
            return Self(url: tempURL)
        }
    }
}
