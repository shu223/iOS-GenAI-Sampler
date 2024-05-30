//
//  InputVideoView.swift
//  iOS-GenAI-Sampler
//
//  Created by Shuichi Tsutsumi on 2024/05/17.
//

import AVKit
import SwiftUI

struct InputVideoView: View {
    private let videoURL = Bundle.main.url(forResource: "wwdc_test_60s", withExtension: "mp4")!

    private let promptText: String = "Provide a summary of the video. Respond in Markdown."

    @State private var isLoading = false
    @State private var resultText: String = ""

    var body: some View {
        VStack(spacing: 32) {
            inputSection
            resultSection
        }
        .padding()
    }

    private var inputSection: some View {
        VStack(spacing: 16) {
            VideoPlayer(player: AVPlayer(url: videoURL))
                .frame(height: 200)

            Text("Prompt: \(promptText)")
                .frame(maxWidth: .infinity, alignment: .trailing)

            Button("Send", systemImage: "paperplane", action: {
                summarizeVideo()
            })
            .frame(maxWidth: .infinity, alignment: .trailing)
            .imageScale(.large)
        }
    }

    private var resultSection: some View {
        VStack(spacing: 8) {
            Text("Result:")
                .frame(maxWidth: .infinity, alignment: .leading)
            ScrollView {
                if isLoading {
                    ProgressView()
                        .frame(alignment: .center)
                } else {
                    Text("\(resultText)")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                Spacer()
            }
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity)
    }

    func summarizeVideo() {
        isLoading = true
        Task {
            do {
                let images = try await VideoSummarizeHelper.extractFrames(from: videoURL)
                for try await result in OpenAIClient().sendMessage(text: "These are video frames.", images: images, systemMessage: promptText) {
                    guard let choice = result.choices.first else { return }
                    let message = choice.delta.content ?? ""
                    Task.detached { @MainActor in
                        isLoading = false
                        resultText += message
                    }
                    if let finishReason = choice.finishReason {
                        print("Stream finished with reason:\(finishReason).")
                        break
                    }
                }
            } catch {
                fatalError("Failed to send messages with error: \(error)")
            }
        }
    }
}

#Preview {
    InputVideoView()
}

class VideoSummarizeHelper {
    static func extractFrames(from videoURL: URL) async throws -> [Data] {
        return try await VideoUtils.extractFrames(from: videoURL, timeInterval: 5.0, maximumSize: CGSize(width: 768, height: 768)).map { $0.data! }
    }
}
