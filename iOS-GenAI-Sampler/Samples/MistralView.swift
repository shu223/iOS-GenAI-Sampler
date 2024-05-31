//
//  MistralView.swift
//  iOS-GenAI-Sampler
//
//  Created by Shuichi Tsutsumi on 2024/05/31.
//

import SwiftUI

struct MistralView: View {
    @StateObject var llamaState = LlamaCppState()

    @State private var inputText = "What's the highest building in Japan?"
    @State private var isLoading = false

    private let targetModel = LlamaCppModel.mistral7B_Q4

    var body: some View {
        VStack(spacing: 32) {
            if llamaState.modelLoaded {
                Text("Model: \(targetModel.name)")
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                LlamaCppDownloadButton(llamaState: llamaState, model: targetModel)
            }

            TextField("Enter prompt here", text: $inputText)
                .textFieldStyle(.roundedBorder)

            VStack(alignment: .trailing, spacing: 16) {
                Button("Send", systemImage: "paperplane", action: {
                    sendMessage()
                })
                .imageScale(.large)
                .disabled(inputText.isEmpty)
                .disabled(!llamaState.modelLoaded)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)

            if !llamaState.completionLog.isEmpty {
                ScrollView {
                    Text(llamaState.completionLog)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(Font(UIFont.monospacedSystemFont(ofSize: 14.0, weight: .regular)))
                        .foregroundColor(Color.white)
                        .padding()
                }
                .frame(maxWidth: .infinity, maxHeight: 96)
                .background(Color.black)
            }

            VStack(spacing: 16) {
                Text("Result:")
                    .frame(maxWidth: .infinity, alignment: .leading)

                ScrollView {
                    if isLoading {
                        ProgressView()
                            .frame(alignment: .center)
                    } else {
                        Text(llamaState.resultText)
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
        Task {
            await llamaState.complete(text: inputText)

            Task.detached { @MainActor in
                self.isLoading = false
            }
        }
    }
}

#Preview {
    MistralView()
}
