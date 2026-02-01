import AVFoundation
import UIKit
import CoreGraphics

class VideoGenerator {
    static func generateTestVideo(
        url: URL,
        size: CGSize,
        duration: TimeInterval,
        type: TestVideoType
    ) async throws {
        let fps: Int = 30
        let totalFrames = Int(duration * Double(fps))

        guard let writer = try? AVAssetWriter(outputURL: url, fileType: .mov) else {
            throw NSError(domain: "VideoGenerator", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create writer"])
        }

        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: Int(size.width),
            AVVideoHeightKey: Int(size.height),
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: 5000000,
                AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel
            ]
        ]

        let writerInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        let sourcePixelBufferAttributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32ARGB),
            kCVPixelBufferWidthKey as String: Int(size.width),
            kCVPixelBufferHeightKey as String: Int(size.height)
        ]
        let adapter = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: writerInput,
            sourcePixelBufferAttributes: sourcePixelBufferAttributes
        )

        writer.add(writerInput)
        writer.startWriting()
        writer.startSession(atSourceTime: .zero)

        for frameIndex in 0..<totalFrames {
            while !writerInput.isReadyForMoreMediaData {
                try await Task.sleep(nanoseconds: 10_000_000)
            }

            let presentationTime = CMTime(value: CMTimeValue(frameIndex), timescale: CMTimeScale(fps))

            if let pixelBuffer = createFrame(frameIndex: frameIndex, totalFrames: totalFrames, size: size, type: type) {
                adapter.append(pixelBuffer, withPresentationTime: presentationTime)
            }
        }

        writerInput.markAsFinished()
        await writer.finishWriting()
    }

    private static func createFrame(frameIndex: Int, totalFrames: Int, size: CGSize, type: TestVideoType) -> CVPixelBuffer? {
        let width = Int(size.width)
        let height = Int(size.height)

        var pixelBuffer: CVPixelBuffer?
        let attrs: [CFString: Any] = [
            kCVPixelBufferCGImageCompatibilityKey: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey: true
        ]

        let status = CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_32ARGB, attrs as CFDictionary, &pixelBuffer)
        guard status == kCVReturnSuccess, let buffer = pixelBuffer else { return nil }

        CVPixelBufferLockBaseAddress(buffer, [])
        defer { CVPixelBufferUnlockBaseAddress(buffer, []) }

        guard let context = CGContext(data: CVPixelBufferGetBaseAddress(buffer),
                                       width: width, height: height,
                                       bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
                                       space: CGColorSpaceCreateDeviceRGB(),
                                       bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue) else { return nil }

        let progress = Double(frameIndex) / Double(totalFrames)

        if type == .waterDroplets {
            drawWaterDroplets(context: context, size: size, progress: progress)
        } else if type == .lightTrails {
            drawLightTrails(context: context, size: size, progress: progress)
        } else {
            drawClouds(context: context, size: size, progress: progress)
        }

        return buffer
    }

    private static func drawWaterDroplets(context: CGContext, size: CGSize, progress: Double) {
        context.setFillColor(CGColor(red: 0.1, green: 0.1, blue: 0.3, alpha: 1.0))
        context.fill(CGRect(origin: .zero, size: size))

        for i in 0..<8 {
            let angle = (Double(i) / 8.0) * .pi * 2 + progress * .pi * 2
            let centerX = size.width / 2 + cos(angle) * size.width * 0.3
            let centerY = size.height / 2 + sin(angle) * size.height * 0.3
            let radius = 20 + sin(progress * .pi * 4 + Double(i)) * 10

            context.setFillColor(CGColor(red: 0.5, green: 0.7, blue: 1.0, alpha: 0.8))
            let rect = CGRect(x: centerX - radius, y: centerY - radius, width: radius * 2, height: radius * 2)
            context.fillEllipse(in: rect)
        }
    }

    private static func drawLightTrails(context: CGContext, size: CGSize, progress: Double) {
        context.setFillColor(CGColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0))
        context.fill(CGRect(origin: .zero, size: size))

        let colors: [CGColor] = [
            CGColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0),
            CGColor(red: 1.0, green: 1.0, blue: 0.0, alpha: 1.0),
            CGColor(red: 0.0, green: 1.0, blue: 0.0, alpha: 1.0),
            CGColor(red: 0.0, green: 1.0, blue: 1.0, alpha: 1.0),
            CGColor(red: 1.0, green: 0.0, blue: 1.0, alpha: 1.0)
        ]

        for i in 0..<5 {
            let y = size.height * (0.2 + Double(i) * 0.15)
            let x = (progress * size.width * 2 + size.width * Double(i) * 0.3).truncatingRemainder(dividingBy: size.width * 2)

            context.setFillColor(colors[i])
            let rect = CGRect(x: x, y: y - 10, width: 80, height: 20)
            context.fill(rect)
        }
    }

    private static func drawClouds(context: CGContext, size: CGSize, progress: Double) {
        context.setFillColor(CGColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 1.0))
        context.fill(CGRect(origin: .zero, size: size))

        for i in 0..<4 {
            let offset = progress * 0.1
            let x = ((0.2 + Double(i) * 0.25 - offset).truncatingRemainder(dividingBy: 2.0)) * size.width - 100
            let y = size.height * (0.3 + Double(i % 2) * 0.25)

            context.setFillColor(CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.6))
            let rect = CGRect(x: x, y: y, width: 150, height: 60)
            context.fill(rect)
        }
    }
}
