//
//  VideoUtils.swift
//
//  Copyright © 2024 Shuichi Tsutsumi. All rights reserved.
//

import AVFoundation

class VideoUtils {
    static func extractFrames(from videoURL: URL, timeInterval: Double = 1.0, maximumSize: CGSize = .zero) async throws -> [CGImage] {
        let avAsset = AVAsset(url: videoURL)

        // 動画の総時間を取得し、timeInterval秒ごとのCMTimeを生成
        let durationSeconds = try Int(CMTimeGetSeconds(await avAsset.load(.duration)))
        let frameCount = Int(Double(durationSeconds) / timeInterval)
        let times = (0 ..< frameCount).map { CMTime(seconds: Double($0) * timeInterval, preferredTimescale: CMTimeScale.max) }

        print("duration: \(durationSeconds), frame count: \(times.count)")

        return await avAsset.extractFrames(for: times, maximumSize: maximumSize)
    }
}

public extension AVAsset {
    // 動画のAVAssetからフレームを抽出する
    func extractFrames(for times: [CMTime], maximumSize: CGSize = .zero) async -> [CGImage] {
        let generator = AVAssetImageGenerator(asset: self)
        generator.appliesPreferredTrackTransform = true
        generator.requestedTimeToleranceBefore = CMTime.zero
        generator.requestedTimeToleranceAfter = CMTime.zero
        generator.maximumSize = maximumSize

        var cgImages: [CGImage] = []
        var resultsCnt = 0
        let timesValues: [NSValue] = times.map { NSValue(time: $0) }

        return await withCheckedContinuation { continuation in
            generator.generateCGImagesAsynchronously(forTimes: timesValues) { requestedTime, cgImage, actualTime, result, error in
                switch result {
                case .succeeded:
                    if let cgImage = cgImage {
                        print("Image extracted. Requested: \(requestedTime.seconds), Actual: \(actualTime.seconds)")
                        cgImages.append(cgImage)
                    }
                case .cancelled, .failed:
                    if let error = error {
                        print("Error at time \(requestedTime.seconds), \(actualTime.seconds): \(error.localizedDescription)")
                    }
                @unknown default:
                    fatalError("Unhandled case in image generation")
                }

                resultsCnt += 1
                if resultsCnt == times.count {
                    print("All frames were extracted.")
                    continuation.resume(returning: cgImages)
                }
            }
        }
    }

    // 動画のAVAssetからフレームを抽出する
    func extractFrame(for timestamp: TimeInterval, maximumSize: CGSize = .zero) async -> CGImage? {
        let time = CMTime(seconds: timestamp, preferredTimescale: CMTimeScale.max)
        // FIXME: 共通化する
        let generator = AVAssetImageGenerator(asset: self)
        generator.appliesPreferredTrackTransform = true
        generator.requestedTimeToleranceBefore = CMTime.zero
        generator.requestedTimeToleranceAfter = CMTime.zero
        generator.maximumSize = maximumSize

        return await withCheckedContinuation { continuation in
            generator.generateCGImageAsynchronously(for: time) { cgImage, actualTime, error in
                if let error = error {
                    print("Error at time \(time.seconds), \(actualTime.seconds): \(error.localizedDescription)")
                    continuation.resume(returning: nil)
                    return
                }
                print("Image extracted. Requested: \(time.seconds), Actual: \(actualTime.seconds)")
                continuation.resume(returning: cgImage)
            }
        }
    }
}
