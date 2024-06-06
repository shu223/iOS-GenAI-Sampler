//
//  LlamaCppState.swift
//  iOS-GenAI-Sampler
//
//  Created by Shuichi Tsutsumi on 2024/05/31.
//
//  Customized from llama.cpp/examples/llama.swiftui/llama.swiftui/Models/LlamaState.swift

import Foundation

@MainActor
class LlamaCppState: ObservableObject {
    @Published var completionLog = ""
    @Published var resultText = ""
    @Published var cacheCleared = false

    private let NS_PER_S = 1_000_000_000.0

    @Published private(set) var llamaContext: LlamaContext?

    static func modelDownloaded(filename: String) -> Bool {
        let fileURL = getFileURL(filename: filename)
        return FileManager.default.fileExists(atPath: fileURL.path)
    }

    var modelLoaded: Bool {
        return llamaContext != nil
    }

    static func getFileURL(filename: String) -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(filename)
    }

    func loadModel(modelUrl: URL) throws {
        print("Loading model...")
        llamaContext = try LlamaContext.create_context(path: modelUrl.path(), maxLength: 200)
        print("Loaded model \(modelUrl.lastPathComponent)")
    }

    func complete(text: String) async {
        guard let llamaContext else {
            print("No llama context")
            return
        }
        await llamaContext.clear()
        completionLog = ""
        resultText = ""

        completionLog += "Processing completion..."

        let t_start = DispatchTime.now().uptimeNanoseconds
        await llamaContext.completion_init(text: text)
        let t_heat_end = DispatchTime.now().uptimeNanoseconds
        let t_heat = Double(t_heat_end - t_start) / NS_PER_S

        completionLog += "\nHeat up took \(t_heat)s"

        resultText += "\(text)"

        Task.detached {
            while await llamaContext.n_cur < llamaContext.n_len {
                let result = await llamaContext.completion_loop()

                await MainActor.run {
                    self.resultText += "\(result)"
                }
            }

            let t_end = DispatchTime.now().uptimeNanoseconds
            let t_generation = Double(t_end - t_heat_end) / self.NS_PER_S
            let tokens_per_second = Double(await llamaContext.n_len) / t_generation

            await llamaContext.clear()

            Task { @MainActor in
                self.completionLog += """
                \nDone
                Generated \(tokens_per_second) t/s\n
                """
            }
        }
    }
}
