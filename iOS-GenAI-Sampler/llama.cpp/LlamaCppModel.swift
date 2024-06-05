//
//  LlamaCppModel.swift
//  iOS-GenAI-Sampler
//
//  Created by Shuichi Tsutsumi on 2024/05/31.
//

import Foundation

struct LlamaCppModel: Identifiable, Hashable {
    var id = UUID()
    var name: String
    var shortName: String?
    var url: String
    var filename: String
    var status: String?

    static let tinyLlama_1_1B_Q4 = LlamaCppModel(
        name: "TinyLlama-1.1B (Q4_0, 0.6 GB)",
        url: "https://huggingface.co/TheBloke/TinyLlama-1.1B-1T-OpenOrca-GGUF/resolve/main/tinyllama-1.1b-1t-openorca.Q4_0.gguf?download=true",
        filename: "tinyllama-1.1b-1t-openorca.Q4_0.gguf", status: "download"
    )

    static let tinyLlama_1_1B_Chat_Q8 = LlamaCppModel(
        name: "TinyLlama-1.1B Chat (Q8_0, 1.1 GB)",
        url: "https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF/resolve/main/tinyllama-1.1b-chat-v1.0.Q8_0.gguf?download=true",
        filename: "tinyllama-1.1b-chat-v1.0.Q8_0.gguf", status: "download"
    )

    static let mistral_7B_Q4 = LlamaCppModel(
        name: "Mistral-7B-v0.1 (Q4_K_S, 4.1 GB)",
        url: "https://huggingface.co/TheBloke/Mistral-7B-v0.1-GGUF/resolve/main/mistral-7b-v0.1.Q4_K_S.gguf?download=true",
        filename: "mistral-7b-v0.1.Q4_K_S.gguf", status: "download"
    )

    static let phi2_Q4 = LlamaCppModel(
        name: "Phi-2 2.7B (Q4_0, 1.6 GB)",
        url: "https://huggingface.co/ggml-org/models/resolve/main/phi-2/ggml-model-q4_0.gguf?download=true",
        filename: "phi-2-q4_0.gguf", status: "download"
    )

    static let phi3_Mini_4K_Instruct_Q4 = LlamaCppModel(
        name: "Phi-3 Mini-4K-Instruct (Q4, 2.2 GB)",
        url: "https://huggingface.co/microsoft/Phi-3-mini-4k-instruct-gguf/resolve/main/Phi-3-mini-4k-instruct-q4.gguf?download=true",
        filename: "Phi-3-mini-4k-instruct-q4.gguf", status: "download"
    )

    static let gemma_2B_Instruct_Q4 = LlamaCppModel(
        name: "Gemma 2B Instruct (Q4, 1.5 GB)",
        shortName: "Q4",
        url: "https://huggingface.co/lmstudio-ai/gemma-2b-it-GGUF/resolve/main/gemma-2b-it-q4_k_m.gguf?download=true",
        filename: "gemma-2b-it-q4_k_m.gguf", status: "download"
    )

    static let gemma_2B_Instruct_Q8 = LlamaCppModel(
        name: "Gemma 2B Instruct (Q8, 2.67 GB)",
        shortName: "Q8",
        url: "https://huggingface.co/lmstudio-ai/gemma-2b-it-GGUF/resolve/main/gemma-2b-it-q8_0.gguf?download=true",
        filename: "gemma-2b-it-q8_0.gguf", status: "download"
    )
}
