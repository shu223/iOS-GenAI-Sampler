//
//  ContentView.swift
//  iOS-GenAI-Sampler
//
//  Created by Shuichi Tsutsumi on 2024/05/16.
//

import SwiftUI

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
                    NavigationLink("Input Text", destination: InputTextView())
                    NavigationLink("Input Image", destination: InputImageView())
                    NavigationLink("Input Video", destination: InputVideoView())
                    NavigationLink("Realtime Camera", destination: RealtimeCameraView())
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
