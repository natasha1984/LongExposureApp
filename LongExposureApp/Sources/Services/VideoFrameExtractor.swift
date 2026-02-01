import AVFoundation
import UIKit

class VideoFrameExtractor: ObservableObject {
    @Published var progress: Double = 0.0

    func extractFrames(from videoURL: URL, frameInterval: TimeInterval = 0.1, maxFrames: Int = 50) async throws -> [FrameInfo] {
        let asset = AVAsset(url: videoURL)
        let duration = try await asset.load(.duration)

        let totalDuration = CMTimeGetSeconds(duration)
        let frameCount = min(Int(totalDuration / frameInterval), maxFrames)

        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.maximumSize = CGSize(width: 1920, height: 1920)

        var frames: [FrameInfo] = []
        let frameTimeInterval = totalDuration / Double(frameCount)

        for i in 0..<frameCount {
            let time = CMTime(seconds: Double(i) * frameTimeInterval, preferredTimescale: 600)

            do {
                let cgImage = try imageGenerator.copyCGImage(at: time, actualTime: nil)
                let uiImage = UIImage(cgImage: cgImage)
                frames.append(FrameInfo(index: i, image: uiImage))
            } catch {
                print("Failed to extract frame \(i): \(error.localizedDescription)")
            }

            await MainActor.run {
                self.progress = Double(i + 1) / Double(frameCount)
            }
        }

        return frames
    }
}

enum VideoError: LocalizedError {
    case failedToCreateGenerator
    case failedToExtractFrame

    var errorDescription: String? {
        switch self {
        case .failedToCreateGenerator:
            return "Failed to create video frame generator"
        case .failedToExtractFrame:
            return "Failed to extract frame from video"
        }
    }
}
