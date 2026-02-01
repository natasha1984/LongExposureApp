import SwiftUI
import PhotosUI

struct ProcessingView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 30) {
            if appState.extractedFrames.isEmpty {
                ProgressView(value: appState.processingProgress)
                    .progressViewStyle(.linear)
                    .frame(width: 200)

                Text("Extracting frames...")
                    .font(.headline)
            } else if !appState.isAligned {
                ProgressView(value: appState.processingProgress)
                    .progressViewStyle(.linear)
                    .frame(width: 200)

                Text("Aligning frames...")
                    .font(.headline)
            } else {
                ProgressView(value: appState.processingProgress)
                    .progressViewStyle(.linear)
                    .frame(width: 200)

                Text("Creating long exposure...")
                    .font(.headline)
            }

            Text("\(appState.extractedFrames.count) frames extracted")
                .font(.caption)
                .foregroundStyle(.secondary)

            if !appState.extractedFrames.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(appState.extractedFrames.prefix(20)) { frame in
                            Image(uiImage: frame.alignedImage ?? frame.image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 60, height: 60)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(height: 70)
            }

            Spacer()
        }
        .padding()
    }
}

struct ResultView: View {
    @EnvironmentObject var appState: AppState
    @State private var isSaving = false
    @State private var shareURL: URL?

    var body: some View {
        VStack(spacing: 20) {
            if let image = appState.generatedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(radius: 10)

                HStack(spacing: 20) {
                    Button {
                        saveImage(image)
                    } label: {
                        Label("Save", systemImage: "square.and.arrow.down")
                    }
                    .buttonStyle(.bordered)
                    .disabled(isSaving)

                    ShareLink(
                        item: generateShareURL(for: image),
                        subject: Text("Long Exposure"),
                        message: Text("Check out this long exposure I created!")
                    ) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(.borderedProminent)
                }

                Button("Start Over") {
                    appState.reset()
                }
                .buttonStyle(.bordered)
                .padding(.top)
            }

            Spacer()
        }
        .padding()
    }

    private func generateShareURL(for image: UIImage) -> URL {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("long_exposure_\(UUID().uuidString).jpg")

        if let data = image.jpegData(compressionQuality: 0.9) {
            try? data.write(to: tempURL)
        }
        return tempURL
    }

    private func saveImage(_ image: UIImage) {
        isSaving = true
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        isSaving = false
    }
}
