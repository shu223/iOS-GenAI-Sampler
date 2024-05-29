//
//  VideoCapture+UIKit.swift
//
//
//  Created by Shuichi Tsutsumi on 2021/11/04.
//

import AVFoundation
import UIKit

public extension VideoCapture {
    convenience init(cameraType: CameraType, preset: AVCaptureSession.Preset? = nil, preferredSpec: VideoSpec? = nil, previewView: UIView?, useAudio: Bool = false) {
        self.init(cameraType: cameraType, preset: preset, preferredSpec: preferredSpec, previewContainer: previewView?.layer, useAudio: useAudio)
    }
}
