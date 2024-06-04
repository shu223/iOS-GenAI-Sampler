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
            modelSection
            inputSection
            resultSection
        }
        .padding()
    }

    private var modelSection: some View {
        VStack {
            if llamaState.modelLoaded {
                Text("Model: \(targetModel.name)")
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                LlamaCppDownloadButton(llamaState: llamaState, model: targetModel)
            }
        }.padding(.top)
    }

    private var inputSection: some View {
        VStack {
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
        }
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
                .background(Color.black)
            }

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
