//
//  InputImageView.swift
//  iOS-GenAI-Sampler
//
//  Created by Shuichi Tsutsumi on 2024/05/17.
//

import OpenAI
import SwiftUI

let imageName = "openaidemo"
let imageURL = "https://upload.wikimedia.org/wikipedia/commons/thumb/d/dd/Gfp-wisconsin-madison-the-nature-boardwalk.jpg/2560px-Gfp-wisconsin-madison-the-nature-boardwalk.jpg"

struct InputImageView: View {
    @State private var selectedSegment = 0
    @State private var isLoading = false
    @State private var resultText: String = ""

    private let inputImage = UIImage(named: imageName)!
    private let inputURL = URL(string: imageURL)!

    private let promptText: String = "What's in this image?"

    var body: some View {
        VStack(spacing: 32) {
            pickerSection
            imageSection
            sendSection
            resultSection
        }
        .padding()
    }

    private var pickerSection: some View {
        Picker("Options", selection: $selectedSegment) {
            Text("Image Data").tag(0)
            Text("Image URL").tag(1)
        }
        .pickerStyle(.segmented)
    }

    private var imageSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            if selectedSegment == 0 {
                Text("Filename: \(imageName).jpg")
                Image(uiImage: inputImage)
                    .resizable()
                    .scaledToFit()
            } else if selectedSegment == 1 {
                Text("URL: \(imageURL)")
                    .lineLimit(1)
                    .truncationMode(.tail)
                AsyncImage(url: inputURL) { image in
                    image
                        .resizable()
                        .scaledToFit()
                } placeholder: {
                    Image(systemName: "photo")
                        .resizable()
                        .scaledToFit()
                }
            }
        }
    }

    private var sendSection: some View {
        VStack(alignment: .trailing, spacing: 16) {
            Text("Prompt: \(promptText)")

            Button("Send", systemImage: "paperplane", action: {
                sendMessage()
            })
            .imageScale(.large)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    private var resultSection: some View {
        VStack(spacing: 8) {
            Text("Result:")
                .frame(maxWidth: .infinity, alignment: .leading)
            ScrollView {
                if isLoading {
                    ProgressView()
                        .frame(alignment: .center)
                } else {
                    Text("\(resultText)")
                        .frame(maxWidth: .infinity, alignment: .leading)
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
            do {
                let chatResult: AsyncThrowingStream<ChatStreamResult, Error>
                if selectedSegment == 0 {
                    chatResult = OpenAIClient().sendMessage(text: promptText, image: .data(inputImage.jpegData(compressionQuality: 0.5)!))
                } else if selectedSegment == 1 {
                    chatResult = OpenAIClient().sendMessage(text: promptText, image: .url(inputURL))
                } else { fatalError() }
                try await processChatResult(chatResult)
            } catch {
                fatalError("Failed to send chat stream with error: \(error)")
            }
        }
    }

    private func processChatResult(_ chatResult: AsyncThrowingStream<ChatStreamResult, Error>) async throws {
        for try await result in chatResult {
            guard let choice = result.choices.first else { return }
            guard let message = choice.delta.content else { return }
            Task.detached { @MainActor in
                isLoading = false
                resultText += message
            }
            if let finishReason = choice.finishReason {
                print("Stream finished with reason: \(finishReason).")
                break
            }
        }
    }
}

#Preview {
    InputImageView()
}
