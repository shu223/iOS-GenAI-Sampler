//
//  StableDiffusionView.swift
//  iOS-GenAI-Sampler
//
//  Created by Shuichi Tsutsumi on 2024/07/21.
//
//  Ported from swift-coreml-diffusers's LoadingView
//  See LICENSE at https://github.com/huggingface/swift-coreml-diffusers/LICENSE

import SwiftUI
import Combine

struct StableDiffusionView: View {
    let model: ModelInfo

    @StateObject var generation = GenerationContext()

    @State private var preparationPhase = "Downloading…"
    @State private var downloadProgress: Double = 0

    enum CurrentView {
        case loading
        case textToImage
        case error(String)
    }
    @State private var currentView: CurrentView = .loading

    @State private var stateSubscriber: Cancellable?

    var body: some View {
        VStack {
            switch currentView {
            case .textToImage: TextToImage().transition(.opacity)
            case .error(let message): ErrorPopover(errorMessage: message).transition(.move(edge: .top))
            case .loading:
                // TODO: Don't present progress view if the pipeline is cached
                ProgressView(preparationPhase, value: downloadProgress, total: 1).padding()
            }
        }
        .animation(.easeIn, value: currentView)
        .environmentObject(generation)
        .onAppear {
            Task.init {
                let loader = PipelineLoader(model: model)
                stateSubscriber = loader.statePublisher.sink { state in
                    DispatchQueue.main.async {
                        switch state {
                        case .downloading(let progress):
                            preparationPhase = "Downloading"
                            downloadProgress = progress
                        case .uncompressing:
                            preparationPhase = "Uncompressing"
                            downloadProgress = 1
                        case .readyOnDisk:
                            preparationPhase = "Loading"
                            downloadProgress = 1
                        default:
                            break
                        }
                    }
                }
                do {
                    if let prompt = model.placeholderPrompt {
                        generation.positivePrompt = prompt
                    }
                    generation.pipeline = try await loader.prepare()
                    self.currentView = .textToImage
                } catch {
                    self.currentView = .error("Could not load model, error: \(error)")
                }
            }
        }
    }
}

// Required by .animation
extension StableDiffusionView.CurrentView: Equatable {}

struct ErrorPopover: View {
    var errorMessage: String

    var body: some View {
        Text(errorMessage)
            .font(.headline)
            .padding()
            .foregroundColor(.red)
            .background(Color.white)
            .cornerRadius(8)
            .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    StableDiffusionView(model: ModelInfo.v21Palettized)
}
