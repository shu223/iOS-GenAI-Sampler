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
        var title: String

        var body: some View {
            Text(title)
                .font(.title2)
                .textCase(nil)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section(header: SectionHeaderView(title: "Multimodal - GPT-4o")) {
                    NavigationLinkWithTitle("Input Text", destination: InputTextView())
                    NavigationLinkWithTitle("Input Image", destination: InputImageView())
                    NavigationLinkWithTitle("Input Video", destination: InputVideoView())
                    NavigationLinkWithTitle("Realtime Camera", destination: RealtimeCameraView())
                }
                Section(header: SectionHeaderView(title: "Local LLM - llama.cpp")) {
                    NavigationLinkWithTitle("Phi-3", destination: Phi3View())
                    NavigationLinkWithTitle("Gemma", destination: GemmaView())
                    NavigationLinkWithTitle("Mistral", destination: MistralView())
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
