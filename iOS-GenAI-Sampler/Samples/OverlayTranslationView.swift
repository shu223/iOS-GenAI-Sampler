//
//  OverlayTranslationView.swift
//  iOS-GenAI-Sampler
//
//  Created by Shuichi Tsutsumi on 2024/06/14.
//

import SwiftUI
import Translation

struct OverlayTranslationView: View {
    // Define the condition to display the translation UI.
    @State private var showTranslation = false

    // Define the text you want to translate.
    var originalText = "Hallo, welt!"

    var body: some View {
        VStack {
            Text(verbatim: originalText)
                .padding()

            Button("Translate") {
                showTranslation.toggle()
            }
            .padding()
        }
        // Offer a system UI translation.
        .translationPresentation(isPresented: $showTranslation,
                                 text: originalText)
    }
}

#Preview {
    OverlayTranslationView()
}
