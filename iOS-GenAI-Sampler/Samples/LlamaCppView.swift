//
//  LlamaCppView.swift
//  iOS-GenAI-Sampler
//
//  Created by Shuichi Tsutsumi on 2024/06/01.
//

import SwiftUI

struct LlamaCppView: View {
    @StateObject var llamaState = LlamaCppState()

    @State private var inputText = "What's the highest building in Japan?"
    @State private var isLoading = false

    private let targetModel: LlamaCppModel

    init(model: LlamaCppModel) {
        self.targetModel = model
    }

    var body: some View {
        VStack(spacing: 32) {
            inputSection
            resultSection
        }
        .padding()
   }

    private var modelView: some View {
        VStack(spacing: 8) {
            Text("Model:")
                .headlineText()
            if llamaState.modelLoaded {
                Text(targetModel.name)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                LlamaCppDownloadButton(llamaState: llamaState, model: targetModel)
            }
        }
    }

    private var inputSection: some View {
        VStack(spacing: 16) {
            modelView

            VStack {
                Text("Prompt:")
                    .headlineText()
                TextField("Enter prompt here", text: $inputText)
                    .textFieldStyle(.roundedBorder)
            }

            Button("Send", systemImage: "paperplane", action: {
                sendMessage()
            })
            .imageScale(.large)
            .disabled(inputText.isEmpty)
            .disabled(!llamaState.modelLoaded)
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(16)
    }

    private var resultSection: some View {
        VStack(spacing: 16) {
            if !llamaState.completionLog.isEmpty {
                ScrollView {
                    Text(llamaState.completionLog)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(Font(UIFont.monospacedSystemFont(ofSize: 14.0, weight: .regular)))
                        .foregroundColor(Color.white)
                        .padding()
                }
                .frame(maxWidth: .infinity, maxHeight: 96)
                .background(Color.black.opacity(0.7))
                .cornerRadius(4)
            }

            Text("Result:")
                .headlineText()

            if isLoading {
                ProgressView()
                    .frame(alignment: .center)
            } else {
                ScrollView {
                Text(llamaState.resultText)
                    .leadingFrame()
                }
                .frame(maxWidth: .infinity)
            }
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity)
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
    LlamaCppView(model: LlamaCppModel.mistral_7B_Q4)
}
