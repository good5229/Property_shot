#!/usr/bin/env swift

import AppKit
import AVFoundation
import Foundation

func fail(_ message: String) -> Never {
    fputs("\(message)\n", stderr)
    exit(1)
}

guard CommandLine.arguments.count >= 4 else {
    fail("usage: extract_video_frames.swift <video> <output-dir> <seconds> [seconds ...]")
}

let videoURL = URL(fileURLWithPath: CommandLine.arguments[1])
let outputDirectory = URL(fileURLWithPath: CommandLine.arguments[2], isDirectory: true)
let seconds = CommandLine.arguments.dropFirst(3).compactMap(Double.init)
guard !seconds.isEmpty else { fail("at least one valid timestamp is required") }

do {
    try FileManager.default.createDirectory(
        at: outputDirectory,
        withIntermediateDirectories: true
    )
} catch {
    fail("cannot create output directory: \(error)")
}

let asset = AVURLAsset(url: videoURL)
let generator = AVAssetImageGenerator(asset: asset)
generator.appliesPreferredTrackTransform = true
generator.requestedTimeToleranceBefore = .zero
generator.requestedTimeToleranceAfter = .zero
let duration = CMTimeGetSeconds(asset.duration)
let videoTrack = asset.tracks(withMediaType: .video).first
let transformedSize = videoTrack?.naturalSize.applying(videoTrack?.preferredTransform ?? .identity)
print(
    "video \(String(format: "%.3f", duration))s · " +
    "\(Int(abs(transformedSize?.width ?? 0)))x\(Int(abs(transformedSize?.height ?? 0)))"
)

for value in seconds {
    let time = CMTime(seconds: value, preferredTimescale: 600)
    let image: CGImage
    do {
        image = try generator.copyCGImage(at: time, actualTime: nil)
    } catch {
        fail("cannot extract frame at \(value)s: \(error)")
    }
    let bitmap = NSBitmapImageRep(cgImage: image)
    guard let data = bitmap.representation(using: .png, properties: [:]) else {
        fail("cannot encode extracted frame at \(value)s")
    }
    let label = String(format: "%05.2f", value).replacingOccurrences(of: ".", with: "-")
    let outputURL = outputDirectory.appendingPathComponent("frame-\(label)s.png")
    do {
        try data.write(to: outputURL)
    } catch {
        fail("cannot write extracted frame: \(error)")
    }
    print("extracted \(String(format: "%.2f", value))s · \(image.width)x\(image.height) · \(outputURL.path)")
}
