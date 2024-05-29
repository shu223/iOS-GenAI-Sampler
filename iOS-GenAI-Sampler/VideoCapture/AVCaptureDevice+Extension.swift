//
//  AVCaptureDevice+Extension.swift
//
//  Created by Shuichi Tsutsumi on 4/3/16.
//  Copyright © 2016 Shuichi Tsutsumi. All rights reserved.
//

import AVFoundation

extension AVCaptureDevice {
    private func availableFormatsFor(preferredFps: Int32) -> [AVCaptureDevice.Format] {
        var availableFormats: [AVCaptureDevice.Format] = []
        for format in formats {
            if format.isAvailable(for: preferredFps) {
                availableFormats.append(format)
            }
        }
        return availableFormats
    }

    private func formatWithHighestResolution(_ availableFormats: [AVCaptureDevice.Format]) -> AVCaptureDevice.Format? {
        var maxWidth: Int32 = 0
        var selectedFormat: AVCaptureDevice.Format?
        for format in availableFormats {
            let dimensions = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
            let width = dimensions.width
            if width >= maxWidth {
                maxWidth = width
                selectedFormat = format
            }
        }
        return selectedFormat
    }

    private func formatFor(preferredSize: CGSize, availableFormats: [AVCaptureDevice.Format]) -> AVCaptureDevice.Format? {
        for format in availableFormats {
            let dimensions = CMVideoFormatDescriptionGetDimensions(format.formatDescription)

            if dimensions.width >= Int32(preferredSize.width), dimensions.height >= Int32(preferredSize.height) {
                return format
            }
        }
        return nil
    }

    func updateCaptureDeviceFormat(with preferredSpec: VideoSpec) {
        do {
            try lockForConfiguration()
        } catch {
            fatalError("")
        }

        if let preferredFps = preferredSpec.fps, preferredFps > 0, !activeFormat.isAvailable(for: preferredFps) {
            updateActiveFormat(with: preferredSpec)
        } else if let preferredSize = preferredSpec.size, preferredSize != .zero {
            updateActiveFormat(with: preferredSpec)
        }

        unlockForConfiguration()
    }

    func updateFramerate(with preferredSpec: VideoSpec) {
        guard let preferredFps = preferredSpec.fps, preferredFps > 0 else { return }
        try! lockForConfiguration()
        activeVideoMinFrameDuration = CMTimeMake(value: 1, timescale: preferredFps)
        activeVideoMaxFrameDuration = CMTimeMake(value: 1, timescale: preferredFps)
        print("active video frame duration: \(activeVideoMinFrameDuration) - \(activeVideoMaxFrameDuration)")
        unlockForConfiguration()
    }

    private func updateActiveFormat(with preferredSpec: VideoSpec) {
        let availableFormats: [AVCaptureDevice.Format]
        if let preferredFps = preferredSpec.fps, preferredFps > 0 {
            availableFormats = availableFormatsFor(preferredFps: preferredFps)
        } else {
            availableFormats = formats
        }
        //        print("available formats:\(availableFormats)")

        var format: AVCaptureDevice.Format?
        if let preferredSize = preferredSpec.size, preferredSize != .zero {
            format = formatFor(preferredSize: preferredSize, availableFormats: availableFormats)
        } else {
            format = formatWithHighestResolution(availableFormats)
        }

        guard let selectedFormat = format else { return }
        print("selected format: \(selectedFormat)")
        activeFormat = selectedFormat
    }
}

extension AVCaptureDevice.Format {
    func isAvailable(for preferredFps: Int32) -> Bool {
        let fps = Float64(preferredFps)
        let ranges = videoSupportedFrameRateRanges
        for range in ranges where range.minFrameRate <= fps && fps <= range.maxFrameRate {
            return true
        }
        return false
    }
}
