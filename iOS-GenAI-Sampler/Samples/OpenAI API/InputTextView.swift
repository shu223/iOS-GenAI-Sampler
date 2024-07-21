//
//  InputTextView.swift
//  iOS-GenAI-Sampler
//
//  Created by Shuichi Tsutsumi on 2024/05/26.
//

import SwiftUI

struct InputTextView: View {
    @State private var inputText = "What do you think about the future of AI?"
    @State private var resultText = ""
    @State private var isLoading = false
    @State private var isStreamingEnabled = false

    var body: some View {
        VStack(spacing: 32) {
            TextField("Enter prompt here", text: $inputText)
                .textFieldStyle(.roundedBorder)

            VStack(alignment: .trailing, spacing: 16) {
                Toggle("Streaming", isOn: $isStreamingEnabled)

                Button("Send", systemImage: "paperplane", action: {
                    sendMessage()
                })
                .imageScale(.large)
                .disabled(inputText.isEmpty)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)

            VStack(spacing: 16) {
                Text("Result:")
                    .frame(maxWidth: .infinity, alignment: .leading)

                ScrollView {
                    if isLoading {
                        ProgressView()
                            .frame(alignment: .center)
                    } else {
                        Text(resultText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                    }
                }
                .frame(maxWidth: .infinity)

                Spacer()
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
    }

    private func sendMessage() {
        isLoading = true
        resultText = ""
        Task {
            do {
                if isStreamingEnabled {
                    for try await result in OpenAIClient().sendMessage(text: inputText) {
                        guard let choice = result.choices.first else { return }
                        let message = choice.delta.content ?? ""
                        Task.detached { @MainActor in
                            self.isLoading = false
                            self.resultText += message
                        }
                        if let finishReason = choice.finishReason {
                            print("Stream finished with reason:\(finishReason).")
                            break
                        }
                    }
                } else {
                    let chatResult = try await OpenAIClient().sendMessage(text: inputText)
                    Task.detached { @MainActor in
                        self.resultText = chatResult
                    }
                }
            } catch {
                Task.detached { @MainActor in
                    self.resultText = "Error: \(error.localizedDescription)"
                }
            }
            Task.detached { @MainActor in
                self.isLoading = false
            }
        }
    }
}

#Preview {
    InputTextView()
}
