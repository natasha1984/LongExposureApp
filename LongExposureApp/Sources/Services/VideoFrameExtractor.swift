import AVFoundation
import UIKit

class VideoFrameExtractor: ObservableObject {
    @Published var progress: Double = 0.0

    func extractFrames(from videoURL: URL, frameInterval: TimeInterval = 0.1, maxFrames: Int = 50) async throws -> [FrameInfo] {
        let asset = AVAsset(url: videoURL)

        let isPlayable = try await asset.load(.isPlayable)
        guard isPlayable else {
            throw VideoError.videoNotPlayable
        }

        let duration = try await asset.load(.duration)
        let tracks = try await asset.load(.tracks)

        guard !tracks.isEmpty else {
            throw VideoError.noVideoTracks
        }

        let totalDuration = CMTimeGetSeconds(duration)
        guard totalDuration > 0 else {
            throw VideoError.invalidDuration
        }

        let frameCount = min(Int(totalDuration / frameInterval), maxFrames)
        guard frameCount > 0 else {
            throw VideoError.noFramesToExtract
        }

        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.maximumSize = CGSize(width: 1280, height: 1280)
        imageGenerator.requestedTimeToleranceBefore = .zero
        imageGenerator.requestedTimeToleranceAfter = .zero

        var frames: [FrameInfo] = []
        let frameTimeInterval = totalDuration / Double(max(1, frameCount))

        for i in 0..<frameCount {
            let time = CMTime(seconds: Double(i) * frameTimeInterval, preferredTimescale: 600)

            do {
                let cgImage = try imageGenerator.copyCGImage(at: time, actualTime: nil)
                let uiImage = UIImage(cgImage: cgImage)
                frames.append(FrameInfo(index: i, image: uiImage))
            } catch {
                print("Frame \(i) at time \(CMTimeGetSeconds(time))s failed: \(error.localizedDescription)")
                // Continue with next frame instead of crashing
            }

            await MainActor.run {
                self.progress = Double(i + 1) / Double(frameCount)
            }
        }

        guard !frames.isEmpty else {
            throw VideoError.failedToExtractFrame
        }

        return frames
    }
}

enum VideoError: LocalizedError {
    case videoNotPlayable
    case noVideoTracks
    case invalidDuration
    case noFramesToExtract
    case failedToExtractFrame

    var errorDescription: String? {
        switch self {
        case .videoNotPlayable:
            return "Video is not playable"
        case .noVideoTracks:
            return "No video tracks found in the video"
        case .invalidDuration:
            return "Invalid video duration"
        case .noFramesToExtract:
            return "No frames to extract (video too short)"
        case .failedToExtractFrame:
            return "Failed to extract any frames from video"
        }
    }
}
