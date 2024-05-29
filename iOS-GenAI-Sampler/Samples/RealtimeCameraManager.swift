//
//  RealtimeCameraManager.swift
//  iOS-GenAI-Sampler
//
//  Created by Shuichi Tsutsumi on 2024/05/20.
//

import AVFoundation
import CoreImage
import Foundation
import UIKit.UIImage

class RealtimeCameraManager: ObservableObject {
    private(set) var videoCapture: VideoCapture?

    private var lastProcessedTime: CFAbsoluteTime = 0
    private var lastAccumulatedTime: CFAbsoluteTime = 0
    let context = CIContext()
    let openAI = OpenAIClient()

    private var prevText: String? = nil
    private var isSending: Bool = false
    private var shouldResetText: Bool = false
    private var accumulatedFrames: [Data] = []

    // Parameters
    static let processInterval: CFAbsoluteTime = 0.5
    static let accumulateInterval: CFAbsoluteTime = 1
    static let maxFrames: Int = 2
    static let maxImageSize: CGFloat = 512

    @Published var useJP: Bool = false

    @Published var resultText: String = ""

    func requestAccess() async -> Bool {
        return await AVCaptureDevice.requestAccess(for: .video)
    }

    private func createImageData(from sampleBuffer: CMSampleBuffer) -> Data? {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        let resizedImage = ciImage.resizedByShortestSide(to: RealtimeCameraManager.maxImageSize).cropped(to: RealtimeCameraManager.maxImageSize)

        guard let cgImage = context.createCGImage(resizedImage, from: resizedImage.extent) else { return nil }
        return cgImage.data
    }

    private func videoNarratingPrompt(with prevText: String?) -> String {
        print("prevText: \(String(describing: prevText))")
        if useJP {
            return
                """
                これは動画の連続したフレームです。
                前のフレームの内容を踏まえて、動画の流れに沿ったナレーションを80文字以内でつけてください。
                - 前のフレームの説明: \(prevText ?? "なし")
                - 前のフレームと同じ状況の描写は省略し、変わった部分について描写してください。
                - 文字があれば読んでください。読めなければ描写不要です。
                - 「現在のフレームでは」といった接頭辞は省略してください。
                """
        } else {
            return
                """
                This is a sequence of video frames.
                Please add a narration in 20 words that follow the flow of the video, considering the content of the previous frame.
                - Description of the previous frame: \(prevText ?? "None")
                - Omit descriptions of unchanged situations from the previous frame, and describe only what has changed.
                - If there are any texts, please read them. If not readable, no description is needed.
                - Omit prefixes like "In the current frame".
                """
        }
    }

    func initialize(with view: UIView) {
        let videoCapture = VideoCapture(cameraType: .front, previewView: view, useAudio: false)

        videoCapture.videoOutputHandler = { _, sampleBuffer, _ in
            assert(!Thread.isMainThread)

            // 前回の処理から指定した時間が経過しているか？
            let currentTime = CFAbsoluteTimeGetCurrent()
            guard currentTime - self.lastProcessedTime >= RealtimeCameraManager.processInterval else { return }
            self.lastProcessedTime = currentTime

            guard !self.isSending else {
                print("Sending")
                // スキップしたフレームを蓄積
                guard currentTime - self.lastAccumulatedTime >= RealtimeCameraManager.accumulateInterval else { return }
                if let imageData = self.createImageData(from: sampleBuffer) {
                    self.accumulatedFrames.append(imageData)
                    self.lastAccumulatedTime = currentTime
                }
                return
            }
            self.isSending = true

            guard let imageData = self.createImageData(from: sampleBuffer) else { return }
            self.accumulatedFrames.append(imageData)

            Task {
                await self.addNarration()
            }
        }

        self.videoCapture = videoCapture
    }

    func startCapture() {
        videoCapture?.startCapture()
    }

    func stopCapture() {
        videoCapture?.stopCapture {
            print("capture stopped")
        }
    }

    private func addNarration() async {
        let startTime = CFAbsoluteTimeGetCurrent()
        let userPrompt = videoNarratingPrompt(with: prevText)
        print("num accumlated: \(accumulatedFrames.count)")
        let stream = openAI.sendMessage(text: userPrompt, images: accumulatedFrames.suffix(RealtimeCameraManager.maxFrames), detail: .low, maxTokens: 80)
        accumulatedFrames = []
        do {
            for try await result in stream {
                guard let choice = result.choices.first else { return }
                if let finishReason = choice.finishReason {
                    print("Stream finished with reason:\(finishReason)")
                    let endTime = CFAbsoluteTimeGetCurrent()
                    print("Final result: \(resultText)")
                    print("Elapsed time: \(endTime - startTime)")

                    prevText = resultText
                    isSending = false

                    // finishしたらすぐにリセットするのではなく、次の結果が来るまで表示しておきたい
                    // ので、フラグを立てておく
                    shouldResetText = true
                }
                guard let message = choice.delta.content else { return }
                await MainActor.run {
                    if self.shouldResetText {
                        // 前回までの結果の蓄積をリセットして新しい結果を入れていく
                        self.resultText = message
                        self.shouldResetText = false
                    } else {
                        self.resultText += message
                    }
                }
            }

        } catch {
            print("Failed to send messages with error: \(error)")
            resultText = error.localizedDescription
            isSending = false
            shouldResetText = true
        }
    }
}

extension CGImage {
    var data: Data? {
        return UIImage(cgImage: self).jpegData(compressionQuality: 0.3)
    }
}
