import Vision
import UIKit
import CoreImage

class ImageAlignmentService: ObservableObject {
    @Published var progress: Double = 0.0

    func alignFrames(_ frames: [FrameInfo]) async -> [FrameInfo] {
        guard !frames.isEmpty else { return frames }

        var alignedFrames: [FrameInfo] = []

        for (index, frame) in frames.enumerated() {
            let alignedImage = alignImageSimple(frame.image, referenceSize: frames.first!.image.size)

            var alignedFrame = frame
            alignedFrame.alignedImage = alignedImage
            alignedFrames.append(alignedFrame)

            await MainActor.run {
                self.progress = Double(index + 1) / Double(frames.count)
            }
        }

        return alignedFrames
    }

    private func alignImageSimple(_ image: UIImage, referenceSize: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(referenceSize, false, 1.0)
        defer { UIGraphicsEndImageContext() }

        let ctx = UIGraphicsGetCurrentContext()
        ctx?.setFillColor(UIColor.black.cgColor)
        ctx?.fill(CGRect(origin: .zero, size: referenceSize))

        let targetRect = CGRect(
            x: (referenceSize.width - image.size.width) / 2,
            y: (referenceSize.height - image.size.height) / 2,
            width: image.size.width,
            height: image.size.height
        )

        image.draw(in: targetRect)

        return UIGraphicsGetImageFromCurrentImageContext()
    }
}
