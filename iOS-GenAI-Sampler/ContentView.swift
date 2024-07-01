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
                Section(header: SectionHeaderView(title: "📷 Multimodal - GPT-4o")) {
                    NavigationLinkWithTitle("Input Text", destination: InputTextView())
                    NavigationLinkWithTitle("Input Image", destination: InputImageView())
                    NavigationLinkWithTitle("Input Video", destination: InputVideoView())
                    NavigationLinkWithTitle("Realtime Camera", destination: RealtimeCameraView())
                }
                Section(header: SectionHeaderView(title: "🦙 Local LLM - llama.cpp")) {
                    NavigationLinkWithTitle("Phi-3", destination: Phi3View())
                    NavigationLinkWithTitle("Gemma", destination: GemmaView())
                    NavigationLinkWithTitle("Mistral", destination: MistralView())
                }
                Section(header: SectionHeaderView(imageName: "arrow.left.arrow.right", title: "Translation Framework - Apple")) {
                    NavigationLinkWithTitle("Simple Overlay", destination: OverlayTranslationView())
                    if #available(iOS 18.0, *) {
                        NavigationLinkWithTitle("Custom UI Translation", destination: CustomTranslationView())
                        NavigationLinkWithTitle("Download status for models", destination: SupportedLanguagesView())
                    }
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
