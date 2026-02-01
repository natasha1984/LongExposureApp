import SwiftUI
import PhotosUI

struct ProcessingView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 20) {
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
    @State private var showFullImage = false

    var body: some View {
        VStack(spacing: 20) {
            ScrollView {
                if let image = appState.generatedImage {
                    Button {
                        showFullImage = true
                    } label: {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(radius: 10)
                    }
                    .buttonStyle(.plain)

                    VStack(spacing: 12) {
                        HStack(spacing: 20) {
                            Button {
                                saveImage(image)
                            } label: {
                                Label("Save", systemImage: "square.and.arrow.down")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .disabled(isSaving)

                            ShareLink(
                                item: generateShareURL(for: image),
                                subject: Text("Long Exposure"),
                                message: Text("Check out this long exposure I created!")
                            ) {
                                Label("Share", systemImage: "square.and.arrow.up")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                        }

                        Button("Start Over") {
                            appState.reset()
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.horizontal)
                }
            }

            Spacer()
        }
        .padding()
        .sheet(isPresented: $showFullImage) {
            if let image = appState.generatedImage {
                FullImageView(image: image)
            }
        }
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

struct FullImageView: View {
    let image: UIImage
    @Environment(\.dismiss) private var dismiss
    @State private var scale: CGFloat = 1.0

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ScrollView([.horizontal, .vertical]) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .scaleEffect(scale)
                        .frame(
                            width: geometry.size.width * scale,
                            height: geometry.size.height * scale
                        )
                        .onTapGesture(count: 2) {
                            withAnimation {
                                scale = scale > 1.0 ? 1.0 : 2.0
                            }
                        }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .background(Color.black)
            .navigationTitle("Result")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button {
                        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                    } label: {
                        Label("Save", systemImage: "square.and.arrow.down")
                    }
                }
            }
        }
    }
}
