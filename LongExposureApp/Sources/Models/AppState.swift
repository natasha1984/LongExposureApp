import SwiftUI
import Combine

class AppState: ObservableObject {
    @Published var selectedVideoURL: URL?
    @Published var extractedFrames: [FrameInfo] = []
    @Published var processingProgress: Double = 0.0
    @Published var isProcessing: Bool = false
    @Published var generatedImage: UIImage?
    @Published var errorMessage: String?
    @Published var isAligned: Bool = false

    let videoService = VideoFrameExtractor()
    let alignmentService = ImageAlignmentService()
    let blendingService = ImageBlendingService()

    func reset() {
        selectedVideoURL = nil
        extractedFrames = []
        processingProgress = 0.0
        generatedImage = nil
        errorMessage = nil
        isAligned = false
    }
}

struct FrameInfo: Identifiable {
    let id = UUID()
    let index: Int
    let image: UIImage
    var alignedImage: UIImage?
}
