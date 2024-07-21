//
//  VideoCapture.swift
//
//  Created by Shuichi Tsutsumi on 4/3/16.
//  Copyright © 2016 Shuichi Tsutsumi. All rights reserved.
//

import AVFoundation
import Foundation

public struct VideoSpec {
    var fps: Int32?
    var size: CGSize?

    static let best = VideoSpec(fps: 0, size: .zero)

    public init(fps: Int32?, size: CGSize?) {
        self.fps = fps
        self.size = size
    }
}

public class VideoCapture: NSObject {
    public typealias VideoOutputHandler = (AVCaptureVideoDataOutput, CMSampleBuffer, AVCaptureConnection) -> Void
    public typealias AudioOutputHandler = (AVCaptureAudioDataOutput, CMSampleBuffer, AVCaptureConnection) -> Void

    private let captureSession = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "com.shu223.queue.capturesession")

    @Published public private(set) var videoDevice: AVCaptureDevice = .default(for: .video)!

    private var videoConnection: AVCaptureConnection?
    private var previewLayer: AVCaptureVideoPreviewLayer?

    public var isRunning: Bool {
        return captureSession.isRunning
    }

    @Published public private(set) var currentDimensions: CMVideoDimensions = .init(width: 0, height: 0)

    public var videoOutputHandler: VideoOutputHandler?
    public var audioOutputHandler: AudioOutputHandler?

    public let videoDataOutput = AVCaptureVideoDataOutput()
    public let audioDataOutput = AVCaptureAudioDataOutput()

    public init(cameraType: CameraType, preset: AVCaptureSession.Preset? = nil, preferredSpec: VideoSpec? = nil, previewContainer: CALayer?, useAudio: Bool = true) {
        super.init()

        // setup preview
        if let previewContainer = previewContainer {
            let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer.frame = previewContainer.bounds
            previewLayer.contentsGravity = CALayerContentsGravity.resizeAspect
            previewLayer.videoGravity = .resizeAspect
            previewContainer.insertSublayer(previewLayer, at: 0)
            self.previewLayer = previewLayer
        }

        // setup video device, capture format and video device input
        configureCaptureDevice(cameraType: cameraType, preset: preset, preferredSpec: preferredSpec)

        if useAudio {
            // Find the microphone
            guard let microphone = AVCaptureDevice.default(for: .audio) else {
                fatalError("Could not find the microphone")
            }

            // setup audio device input
            do {
                let audioDeviceInput = try AVCaptureDeviceInput(device: microphone)
                guard captureSession.canAddInput(audioDeviceInput) else {
                    fatalError("Could not add microphone device input")
                }
                captureSession.addInputWithNoConnections(audioDeviceInput)
            } catch {
                fatalError("Could not create microphone input: \(error)")
            }

            // setup audio output
            do {
                let queue = DispatchQueue(label: "com.shu223.queue.audiosample")
                audioDataOutput.setSampleBufferDelegate(self, queue: queue)
                guard captureSession.canAddOutput(audioDataOutput) else {
                    fatalError()
                }
                captureSession.addOutput(audioDataOutput)
            }
        }

        // setup video output
        do {
            videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
            videoDataOutput.alwaysDiscardsLateVideoFrames = true
            let queue = DispatchQueue(label: "com.shu223.queue.videosample")
            videoDataOutput.setSampleBufferDelegate(self, queue: queue)
            guard captureSession.canAddOutput(videoDataOutput) else {
                fatalError()
            }
            captureSession.addOutput(videoDataOutput)
        }

        do {
            videoConnection = videoDataOutput.connection(with: .video)
            videoConnection?.videoOrientation = .portrait
            if cameraType == .front {
                videoConnection?.automaticallyAdjustsVideoMirroring = false
                videoConnection?.isVideoMirrored = true
            }

//            if videoConnection.isVideoStabilizationSupported {
//                videoConnection.preferredVideoStabilizationMode = .auto
//            }
        }

        // setup asset writer
        do {}
        /*

         // Asset Writer
         self.assetWriterManager = [[TTMAssetWriterManager alloc] initWithVideoDataOutput:videoDataOutput
                                                                          audioDataOutput:audioDataOutput
                                                                            preferredSize:preferredSize
                                                                                 mirrored:(cameraType == CameraTypeFront)];
          */
    }

    private func configureCaptureDevice(cameraType: CameraType, preset: AVCaptureSession.Preset?, preferredSpec: VideoSpec?) {
        print("\(type(of: self))/\(#function)")
        captureSession.beginConfiguration()

        let videoDevice = cameraType.captureDevice()
        print("video device:\(videoDevice)")

        // setup video format
        do {
            if let preset = preset {
                captureSession.sessionPreset = preset
            }
            print("current format:\(videoDevice.activeFormat)")
            if let preferredSpec = preferredSpec {
                videoDevice.updateCaptureDeviceFormat(with: preferredSpec)
            }
        }
        currentDimensions = videoDevice.activeFormat.formatDescription.dimensions

        // setup video device input
        do {
            let videoDeviceInput: AVCaptureDeviceInput
            do {
                videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
            } catch {
                fatalError("Could not create AVCaptureDeviceInput instance with error: \(error).")
            }

            captureSession.inputs.forEach { input in
                guard let deviceInput = input as? AVCaptureDeviceInput else { return }
                if deviceInput.device.hasMediaType(.video) {
                    print("input removed: \(deviceInput)")
                    captureSession.removeInput(input)
                }
            }

            guard captureSession.canAddInput(videoDeviceInput) else {
                fatalError()
            }
            captureSession.addInput(videoDeviceInput)
        }

        captureSession.commitConfiguration()

        // videoConnectionの入力デバイスが現在のものと合致していない場合、videoConnectionを取得しなおして改めて設定
        if let videoConnection = videoConnection, let inputPort = videoConnection.inputPorts.first,
           inputPort.sourceDeviceType != videoDevice.deviceType ||
           inputPort.sourceDevicePosition != videoDevice.position
        {
            // videoConnectionを更新
            self.videoConnection = videoDataOutput.connection(with: .video)
            self.videoConnection?.videoOrientation = .portrait

            if cameraType == .front {
                self.videoConnection?.automaticallyAdjustsVideoMirroring = false
                self.videoConnection?.isVideoMirrored = true
            }
        }

        // videoConnection確定後にフレームレートを設定しないと、recommendedVideoSettingsForAssetWriterで取得するvideo settingsに変更後のフレームレートが反映されない
        if let preferredSpec = preferredSpec {
            videoDevice.updateFramerate(with: preferredSpec)
        }

        // もろもろ完了してからCombineのイベントを発火させるため、最後にプロパティにセット
        self.videoDevice = videoDevice
    }

    public func startCapture(completionHandler: (() -> Void)? = nil) {
        print("\(classForCoder)/" + #function)
        sessionQueue.async { [weak self] in
            guard let self else { return }
            guard !self.captureSession.isRunning else {
                print("already running")
                return
            }
            // This method is synchronous and blocks until the session starts running or it fails, which it reports by posting an AVCaptureSessionRuntimeError notification.
            self.captureSession.startRunning()
            print("Capture started")
            completionHandler?()
        }
    }

    public func stopCapture(completionHandler: @escaping () -> Void) {
        print("\(classForCoder)/" + #function)
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            guard self.captureSession.isRunning else {
                print("already stopped")
                completionHandler()
                return
            }
            // This method is synchronous and blocks until the session stops running completely.
            self.captureSession.stopRunning()
            completionHandler()
        }
    }

    public func changeCamera(cameraType: CameraType, preset: AVCaptureSession.Preset, preferredSpec: VideoSpec?, completionHandler: @escaping () -> Void) {
        print("\(type(of: self))/\(#function)")
        let wasRunning = captureSession.isRunning
        stopCapture {
            self.configureCaptureDevice(cameraType: cameraType, preset: preset, preferredSpec: preferredSpec)

            if wasRunning {
                self.startCapture()
            }

            completionHandler()
        }
    }

    public func changePreset(to newPreset: AVCaptureSession.Preset, preferredSpec: VideoSpec?) {
        guard captureSession.sessionPreset != newPreset else { return }
        let wasRunning = captureSession.isRunning

        stopCapture {
            self.captureSession.beginConfiguration()
            self.captureSession.sessionPreset = newPreset
            print("current format:\(self.videoDevice.activeFormat)")
            if let preferredSpec = preferredSpec {
                self.videoDevice.updateCaptureDeviceFormat(with: preferredSpec)
                self.videoDevice.updateFramerate(with: preferredSpec)
            }
            self.captureSession.commitConfiguration()

            self.currentDimensions = self.videoDevice.activeFormat.formatDescription.dimensions

            if wasRunning {
                self.startCapture()
            }
        }
    }

    public func resizePreview() {
        if let previewLayer = previewLayer {
            guard let superlayer = previewLayer.superlayer else { return }
            previewLayer.frame = superlayer.bounds
        }
    }
}

extension VideoCapture: AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {
    public func captureOutput(_: AVCaptureOutput, didDrop _: CMSampleBuffer, from _: AVCaptureConnection) {
//        print("\(self.classForCoder)/" + #function)
    }

    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if let videoDataOutput = output as? AVCaptureVideoDataOutput {
            videoOutputHandler?(videoDataOutput, sampleBuffer, connection)
            // 常にnanになる
//            print("video duration: \(sampleBuffer.duration.seconds)")
        } else if let audioDataOutput = output as? AVCaptureAudioDataOutput {
            audioOutputHandler?(audioDataOutput, sampleBuffer, connection)
//            print("audio duration: \(sampleBuffer.duration.seconds)")
        }
    }
}
