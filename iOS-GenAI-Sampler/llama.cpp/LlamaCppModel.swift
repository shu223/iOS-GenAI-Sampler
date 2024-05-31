//
//  LlamaCppModel.swift
//  iOS-GenAI-Sampler
//
//  Created by Shuichi Tsutsumi on 2024/05/31.
//

import Foundation

struct LlamaCppModel: Identifiable {
    var id = UUID()
    var name: String
    var url: String
    var filename: String
    var status: String?

    static let tinyLlama1_1B_Q4 = LlamaCppModel(
        name: "TinyLlama-1.1B (Q4_0, 0.6 GiB)",
        url: "https://huggingface.co/TheBloke/TinyLlama-1.1B-1T-OpenOrca-GGUF/resolve/main/tinyllama-1.1b-1t-openorca.Q4_0.gguf?download=true",
        filename: "tinyllama-1.1b-1t-openorca.Q4_0.gguf", status: "download"
    )

    static let tinyLlama1_1B_Chat_Q8 = LlamaCppModel(
        name: "TinyLlama-1.1B Chat (Q8_0, 1.1 GiB)",
        url: "https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF/resolve/main/tinyllama-1.1b-chat-v1.0.Q8_0.gguf?download=true",
        filename: "tinyllama-1.1b-chat-v1.0.Q8_0.gguf", status: "download"
    )

    static let mistral7B_Q4 = LlamaCppModel(
        name: "Mistral-7B-v0.1 (Q4_K_S, 4.1 GiB)",
        url: "https://huggingface.co/TheBloke/Mistral-7B-v0.1-GGUF/resolve/main/mistral-7b-v0.1.Q4_K_S.gguf?download=true",
        filename: "mistral-7b-v0.1.Q4_K_S.gguf", status: "download"
    )
}
