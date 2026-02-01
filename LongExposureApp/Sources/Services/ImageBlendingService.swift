import UIKit
import CoreImage

class ImageBlendingService: ObservableObject {
    @Published var progress: Double = 0.0

    func createLongExposure(from frames: [FrameInfo], blendMode: BlendMode = .average) async -> UIImage? {
        guard !frames.isEmpty else { return nil }

        let images = frames.compactMap { $0.alignedImage ?? $0.image }
        guard !images.isEmpty else { return nil }

        let width = Int(images[0].size.width)
        let height = Int(images[0].size.height)

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        format.preferredRange = .standard

        let renderer = UIGraphicsImageRenderer(size: images[0].size, format: format)

        return renderer.image { context in
            var accumulatedR: Float = 0
            var accumulatedG: Float = 0
            var accumulatedB: Float = 0

            let totalImages = Float(images.count)

            for (index, uiImage) in images.enumerated() {
                uiImage.draw(in: CGRect(x: 0, y: 0, width: width, height: height))

                guard let cgImage = uiImage.cgImage,
                      let pixelData = cgImage.dataProvider?.data else {
                    continue
                }

                let pixels = CFDataGetBytePtr(pixelData)
                for y in 0..<height {
                    for x in 0..<width {
                        let pixelIndex = (y * width + x) * 4
                        accumulatedR += Float(pixels![pixelIndex + 1])
                        accumulatedG += Float(pixels![pixelIndex + 2])
                        accumulatedB += Float(pixels![pixelIndex + 3])
                    }
                }

                Task { @MainActor in
                    self.progress = Double(index + 1) / Double(images.count)
                }
            }

            let averageR = UInt8(accumulatedR / totalImages)
            let averageG = UInt8(accumulatedG / totalImages)
            let averageB = UInt8(accumulatedB / totalImages)

            UIColor(red: CGFloat(averageR) / 255.0,
                    green: CGFloat(averageG) / 255.0,
                    blue: CGFloat(averageB) / 255.0,
                    alpha: 1.0)
                .setFill()
            context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        }
    }

    enum BlendMode {
        case average
        case additive
        case max
        case min
    }
}
