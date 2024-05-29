//
//  VideoCameraType.swift
//
//  Created by Shuichi Tsutsumi on 4/3/16.
//  Copyright © 2016 Shuichi Tsutsumi. All rights reserved.
//

import AVFoundation

public enum CameraType: Int {
    case front
    case frontTrueDepth
    case back
    case backTelephoto
    case backDual
    case backDualWide
    case backUltraWide
    case backTriple

    func captureDevice() -> AVCaptureDevice {
        switch self {
        case .front:
            if let device = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .front).devices.first {
                return device
            }
        case .frontTrueDepth:
            if let device = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInTrueDepthCamera], mediaType: .video, position: .front).devices.first {
                return device
            }
        case .back:
            if let device = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .back).devices.first {
                return device
            }
        case .backTelephoto:
            if let device = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInTelephotoCamera], mediaType: .video, position: .back).devices.first {
                return device
            }
        case .backDual:
            if let device = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInDualCamera], mediaType: .video, position: .back).devices.first {
                return device
            }
        case .backDualWide:
            if let device = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInDualWideCamera], mediaType: .video, position: .back).devices.first {
                return device
            }
        case .backUltraWide:
            if let device = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInUltraWideCamera], mediaType: .video, position: .back).devices.first {
                return device
            }
        case .backTriple:
            if let device = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInTripleCamera], mediaType: .video, position: .back).devices.first {
                return device
            }
        }
        return AVCaptureDevice.default(for: .video)!
    }

    public var isFront: Bool {
        switch self {
        case .front, .frontTrueDepth:
            return true
        default:
            return false
        }
    }

    public static var ultraWideAvailable: Bool {
        return AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInUltraWideCamera], mediaType: .video, position: .back).devices.first != nil
    }
}
