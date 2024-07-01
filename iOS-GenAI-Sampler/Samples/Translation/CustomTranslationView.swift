//
//  CustomTranslationView.swift
//  iOS-GenAI-Sampler
//
//  Created by Shuichi Tsutsumi on 2024/07/01.
//

import SwiftUI
import Translation

@available(iOS 18.0, *)
struct CustomTranslationView: View {
    @State private var sourceText = "Hallo, welt!"
    @State private var targetText = ""

    @State private var configuration: TranslationSession.Configuration?

    var body: some View {
        VStack {
            TextField("Enter text to translate", text: $sourceText)
                .textFieldStyle(.roundedBorder)
                .padding()

            Button("Translate") {
                triggerTranslation()
            }
            Text(verbatim: targetText)
                .padding()
        }
        .translationTask(configuration) { session in
            // Use the session the task provides to translate the text.
            let response = try? await session.translate(sourceText)

            // Update the view with the translated result.
            targetText = response?.targetText ?? ""
        }
        .padding()
    }

    private func triggerTranslation() {
        guard configuration == nil else {
            configuration?.invalidate()
            return
        }

        // Let the framework automatically determine the language pairing.
        configuration = .init()
    }
}

#Preview {
    if #available(iOS 18.0, *) {
        CustomTranslationView()
    } else {
        // Fallback on earlier versions
    }
}
