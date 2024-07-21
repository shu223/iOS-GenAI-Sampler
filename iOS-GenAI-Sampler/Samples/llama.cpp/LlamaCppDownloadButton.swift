//
//  LlamaCppDownloadButton.swift
//  iOS-GenAI-Sampler
//
//  Created by Shuichi Tsutsumi on 2024/05/31.
//
//  Customized from llama.cpp/examples/llama.swiftui/llama.swiftui/UI/DownloadButton.swift

import SwiftUI

struct LlamaCppDownloadButton: View {
    @ObservedObject private var llamaState: LlamaCppState
    private var modelName: String
    private var modelUrl: String
    private var filename: String

    @State private var status: String

    @State private var downloadTask: URLSessionDownloadTask?
    @State private var progress = 0.0
    @State private var observation: NSKeyValueObservation?

    // FIXME: 文字列の状態定義をどうにかする
    init(llamaState: LlamaCppState, modelName: String, modelUrl: String, filename: String) {
        self.llamaState = llamaState
        self.modelName = modelName
        self.modelUrl = modelUrl
        self.filename = filename

        status = LlamaCppState.modelDownloaded(filename: filename) ? "downloaded" : "download"
    }

    init(llamaState: LlamaCppState, model: LlamaCppModel) {
        self.init(llamaState: llamaState, modelName: model.name, modelUrl: model.url, filename: model.filename)
    }

    private func download() {
        status = "downloading"
        print("Downloading model \(modelName) from \(modelUrl)")
        guard let url = URL(string: modelUrl) else { return }
        let fileURL = LlamaCppState.getFileURL(filename: filename)

        downloadTask = URLSession.shared.downloadTask(with: url) { temporaryURL, response, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                return
            }

            guard let response = response as? HTTPURLResponse, (200 ... 299).contains(response.statusCode) else {
                print("Server error!")
                return
            }

            do {
                if let temporaryURL = temporaryURL {
                    try FileManager.default.copyItem(at: temporaryURL, to: fileURL)
                    print("Writing to \(filename) completed")

                    DispatchQueue.main.async {
                        llamaState.cacheCleared = false
                    }
                    status = "downloaded"
                }
            } catch let err {
                print("Error: \(err.localizedDescription)")
            }
        }

        observation = downloadTask?.progress.observe(\.fractionCompleted) { progress, _ in
            self.progress = progress.fractionCompleted
        }

        downloadTask?.resume()
    }

    var body: some View {
        VStack {
            if status == "download" {
                Button(action: download) {
                    Text("Download " + modelName)
                }
            } else if status == "downloading" {
                Button(action: {
                    downloadTask?.cancel()
                    status = "download"
                }) {
                    Text("\(modelName) (Downloading \(Int(progress * 100))%)")
                }
            } else if status == "downloaded" {
                Button(action: {
                    let fileURL = LlamaCppState.getFileURL(filename: filename)
                    if !FileManager.default.fileExists(atPath: fileURL.path) {
                        download()
                        return
                    }
                    do {
                        try llamaState.loadModel(modelUrl: fileURL)
                    } catch let err {
                        print("Error: \(err.localizedDescription)")
                    }
                }) {
                    Text("Load \(modelName)")
                }
            } else {
                Text("Unknown status")
            }
        }
        .onDisappear {
            downloadTask?.cancel()
        }
        .onChange(of: llamaState.cacheCleared) { newValue in
            if newValue {
                downloadTask?.cancel()
                status = LlamaCppState.modelDownloaded(filename: filename) ? "downloaded" : "download"
            }
        }
    }
}
