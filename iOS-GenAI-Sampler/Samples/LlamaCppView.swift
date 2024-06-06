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

    @State private var targetModel: LlamaCppModel
    private var models: [LlamaCppModel]

    init(models: [LlamaCppModel]) {
        targetModel = models.first!
        self.models = models
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
            if models.count > 1 {
                Picker("Model:", selection: $targetModel) {
                    ForEach(models, id: \.self) { model in
                        Text(model.shortName ?? model.name).tag(model)
                    }
                }
                .pickerStyle(.segmented)
            }
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
            .disabled(inputText.isEmpty || !llamaState.modelLoaded)
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
                Spacer()
            } else {
                ScrollView {
                    Text(llamaState.resultText)
                        .leadingFrame()
                }
                .padding()
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
    }

    private func sendMessage() {
        isLoading = true
        Task {
            await llamaState.complete(text: inputText)

            Task { @MainActor in
                self.isLoading = false
            }
        }
    }
}

#Preview {
    LlamaCppView(models: [LlamaCppModel.phi3_Mini_4K_Instruct_Q4])
}
