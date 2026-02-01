import Vision
import UIKit

class ImageAlignmentService: ObservableObject {
    @Published var progress: Double = 0.0

    func alignFrames(_ frames: [FrameInfo]) async -> [FrameInfo] {
        guard !frames.isEmpty else { return frames }

        guard let referenceImage = frames.first?.image.cgImage else {
            return frames
        }

        var alignedFrames: [FrameInfo] = []

        for (index, frame) in frames.enumerated() {
            let alignedImage = await alignImage(frame.image, to: referenceImage)

            var alignedFrame = frame
            alignedFrame.alignedImage = alignedImage
            alignedFrames.append(alignedFrame)

            await MainActor.run {
                self.progress = Double(index + 1) / Double(frames.count)
            }
        }

        return alignedFrames
    }

    private func alignImage(_ image: UIImage, to reference: CGImage) async -> UIImage? {
        let request = VNTranslationalImageRegistrationRequest(targetedCVPixelBuffer: convertToPixelBuffer(image)!, completionHandler: { request, error in
            if let error = error {
                print("Alignment error: \(error.localizedDescription)")
                return
            }

            guard let observation = request.results?.first as? VNTranslationObservation else {
                return
            }

            let transform = CGAffineTransform(translationX: observation.translationInImageSpace.width,
                                              y: observation.translationInImageSpace.height)
        })

        return image
    }

    private func convertToPixelBuffer(_ image: UIImage) -> CVPixelBuffer? {
        guard let cgImage = image.cgImage else { return nil }

        let width = cgImage.width
        let height = cgImage.height

        let attributes: [CFString: Any] = [
            kCVPixelBufferCGImageCompatibilityKey: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey: true
        ]

        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault, width, height,
                                          kCVPixelFormatType_32ARGB, attributes as CFDictionary,
                                          &pixelBuffer)

        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
            return nil
        }

        CVPixelBufferLockBaseAddress(buffer, [])
        defer { CVPixelBufferUnlockBaseAddress(buffer, []) }

        let context = CGContext(data: CVPixelBufferGetBaseAddress(buffer),
                                width: width, height: height,
                                bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
                                space: CGColorSpaceCreateDeviceRGB(),
                                bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)

        context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        return buffer
    }
}
