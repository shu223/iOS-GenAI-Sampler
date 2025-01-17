//
//  ContentView.swift
//  iOS-GenAI-Sampler
//
//  Created by Shuichi Tsutsumi on 2024/05/16.
//

import SwiftUI

struct NavigationLinkWithTitle<Destination>: View where Destination: View {
    var title: String
    var destination: Destination

    init(_ title: String, destination: Destination) {
        self.title = title
        self.destination = destination
    }

    var body: some View {
        NavigationLink(title, destination: destination.navigationBarTitle(title, displayMode: .automatic))
    }
}

struct ContentView: View {
    struct SectionHeaderView: View {
        var imageName: String?
        var title: String

        var body: some View {
            HStack {
                if let imageName {
                    Image(systemName: imageName)
                }
                Text(title)
                    .font(.title2)
                    .textCase(nil)
            }
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section(header: SectionHeaderView(title: "📷 OpenAI API")) {
                    NavigationLinkWithTitle("Input Text", destination: InputTextView())
                    NavigationLinkWithTitle("Input Image", destination: InputImageView())
                    NavigationLinkWithTitle("Input Video", destination: InputVideoView())
                    NavigationLinkWithTitle("Realtime Camera", destination: RealtimeCameraView())
                }
                Section(header: SectionHeaderView(title: "🕵 Perplexity API")) {
                    NavigationLinkWithTitle("Search", destination: PerplexityView())
                }
                Section(header: SectionHeaderView(title: "🦙 Local LLM - llama.cpp")) {
                    NavigationLinkWithTitle("Phi-3", destination: Phi3View())
                    NavigationLinkWithTitle("Gemma", destination: GemmaView())
                    NavigationLinkWithTitle("Mistral", destination: MistralView())
                }
                Section(header: SectionHeaderView(imageName: "arrow.left.arrow.right", title: "Translation Framework - Apple")) {
                    NavigationLinkWithTitle("Simple Overlay", destination: OverlayTranslationView())
                }
                Section(header: SectionHeaderView(title: "🖼️ Image Gen - Stable Diffusion")) {
                    NavigationLinkWithTitle("Stable Diffusion v2.1", destination: StableDiffusionView(model: ModelInfo.v21Palettized))
                    NavigationLinkWithTitle("Stable Diffusion XL", destination: StableDiffusionView(model: ModelInfo.xlmbpChunked))
                }
                Section(header: SectionHeaderView(title: "🎤 Speech Recognition - Whisper")) {
                    NavigationLinkWithTitle("WhisperKit", destination: WhisperKitView())
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("GenAI Sampler")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    ContentView()
}
