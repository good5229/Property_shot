#!/usr/bin/env swift

import AVFoundation
import Foundation

func fail(_ message: String) -> Never {
    fputs("DEMO VIDEO INVALID: \(message)\n", stderr)
    exit(1)
}

guard CommandLine.arguments.count == 2 else {
    fail("usage: verify_demo_video.swift <video.mov>")
}

let url = URL(fileURLWithPath: CommandLine.arguments[1])
guard FileManager.default.fileExists(atPath: url.path) else {
    fail("file does not exist: \(url.path)")
}
let asset = AVURLAsset(url: url)
guard let track = asset.tracks(withMediaType: .video).first else {
    fail("no video track")
}
let duration = CMTimeGetSeconds(asset.duration)
let size = track.naturalSize
let transform = track.preferredTransform
let epsilon: CGFloat = 0.0001
let identity = abs(transform.a - 1) < epsilon && abs(transform.b) < epsilon &&
    abs(transform.c) < epsilon && abs(transform.d - 1) < epsilon &&
    abs(transform.tx) < epsilon && abs(transform.ty) < epsilon
guard abs(duration - 60.0) < 0.001 else {
    fail("duration must be exactly 60.000s (got \(String(format: "%.3f", duration)))")
}
guard Int(size.width) == 390 && Int(size.height) == 844 else {
    fail("natural size must be 390x844 (got \(Int(size.width))x\(Int(size.height)))")
}
guard identity else {
    fail("preferred transform is not identity: \(transform)")
}
guard let rawFormat = track.formatDescriptions.first else {
    fail("missing video format description")
}
let format = rawFormat as! CMFormatDescription
let codec = CMFormatDescriptionGetMediaSubType(format)
let avc1 = FourCharCode(0x61766331) // avc1 / H.264
guard codec == avc1 else {
    fail("video codec must be avc1 H.264")
}
print("DEMO VIDEO VALID: 60.000s · 390x844 · H.264/avc1 · identity transform")
