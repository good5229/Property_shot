#!/usr/bin/env swift

import AppKit
import AVFoundation
import CoreVideo
import Foundation

func fail(_ message: String) -> Never {
    fputs("\(message)\n", stderr)
    exit(1)
}

guard CommandLine.arguments.count == 4 else {
    fail("usage: encode_png_frames.swift <frames-dir> <fps> <output.mov>")
}

let framesDirectory = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
guard let fps = Int32(CommandLine.arguments[2]), fps > 0 else {
    fail("fps must be a positive integer")
}
let outputURL = URL(fileURLWithPath: CommandLine.arguments[3])
let fileManager = FileManager.default
let frameURLs: [URL]
do {
    frameURLs = try fileManager.contentsOfDirectory(
        at: framesDirectory,
        includingPropertiesForKeys: nil
    ).filter { $0.lastPathComponent.hasPrefix("frame-") && $0.pathExtension == "png" }
     .sorted { $0.lastPathComponent < $1.lastPathComponent }
} catch {
    fail("cannot list frames: \(error)")
}
guard let firstURL = frameURLs.first,
      let firstImage = NSImage(contentsOf: firstURL),
      let firstCGImage = firstImage.cgImage(forProposedRect: nil, context: nil, hints: nil)
else {
    fail("no readable PNG frames")
}

try? fileManager.removeItem(at: outputURL)
let writer: AVAssetWriter
do {
    writer = try AVAssetWriter(outputURL: outputURL, fileType: .mov)
} catch {
    fail("cannot create writer: \(error)")
}

let width = firstCGImage.width
let height = firstCGImage.height
let settings: [String: Any] = [
    AVVideoCodecKey: AVVideoCodecType.h264,
    AVVideoWidthKey: width,
    AVVideoHeightKey: height,
    AVVideoCompressionPropertiesKey: [
        AVVideoAverageBitRateKey: 2_500_000,
        AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel,
    ],
]
let input = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
input.expectsMediaDataInRealTime = false
let attributes: [String: Any] = [
    kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB,
    kCVPixelBufferWidthKey as String: width,
    kCVPixelBufferHeightKey as String: height,
]
let adaptor = AVAssetWriterInputPixelBufferAdaptor(
    assetWriterInput: input,
    sourcePixelBufferAttributes: attributes
)
guard writer.canAdd(input) else { fail("writer cannot add video input") }
writer.add(input)
guard writer.startWriting() else { fail("startWriting failed: \(String(describing: writer.error))") }
writer.startSession(atSourceTime: .zero)

func makePixelBuffer(from image: CGImage) -> CVPixelBuffer? {
    var buffer: CVPixelBuffer?
    let status = CVPixelBufferCreate(
        kCFAllocatorDefault,
        width,
        height,
        kCVPixelFormatType_32ARGB,
        nil,
        &buffer
    )
    guard status == kCVReturnSuccess, let pixelBuffer = buffer else { return nil }
    CVPixelBufferLockBaseAddress(pixelBuffer, [])
    defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, []) }
    guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else { return nil }
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    guard let context = CGContext(
        data: baseAddress,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
    ) else { return nil }
    context.clear(CGRect(x: 0, y: 0, width: width, height: height))
    context.translateBy(x: 0, y: CGFloat(height))
    context.scaleBy(x: 1, y: -1)
    context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
    return pixelBuffer
}

for (index, url) in frameURLs.enumerated() {
    while !input.isReadyForMoreMediaData {
        Thread.sleep(forTimeInterval: 0.002)
    }
    guard let image = NSImage(contentsOf: url),
          let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil),
          let buffer = makePixelBuffer(from: cgImage)
    else {
        fail("cannot decode frame \(url.lastPathComponent)")
    }
    let presentationTime = CMTime(value: Int64(index), timescale: fps)
    guard adaptor.append(buffer, withPresentationTime: presentationTime) else {
        fail("append failed at frame \(index): \(String(describing: writer.error))")
    }
}

input.markAsFinished()
let semaphore = DispatchSemaphore(value: 0)
writer.finishWriting { semaphore.signal() }
semaphore.wait()
guard writer.status == .completed else {
    fail("finishWriting failed: \(String(describing: writer.error))")
}

print("encoded \(frameURLs.count) frames · \(width)x\(height) · \(fps)fps · \(outputURL.path)")
