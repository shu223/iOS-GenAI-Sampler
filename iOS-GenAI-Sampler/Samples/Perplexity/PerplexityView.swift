import SwiftUI

struct PerplexityView: View {
    @State private var inputText = "What is iOS-GenAI-Sampler?"
    @State private var resultText = ""
    @State private var citations: [String] = []
    @State private var isLoading = false
    @State private var isStreamingEnabled = false
    @State private var selectedModel: PerplexityClient.Model = .sonarSmall
    @State private var selectedRecency: PerplexityClient.SearchRecency = .none
    
    private let client = PerplexityClient()
    
    var body: some View {
        VStack(spacing: 16) {
            TextEditor(text: $inputText)
                .frame(height: 64)
                .padding(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )

            HStack {
                Text("Model")
                Spacer()
                Picker("Model", selection: $selectedModel) {
                    ForEach(PerplexityClient.Model.allCases) { model in
                        Text(model.displayName).tag(model)
                    }
                }
                .disabled(isLoading)
            }

            HStack {
                Text("Recency Filter")
                Spacer()
                Picker("Recency", selection: $selectedRecency) {
                    ForEach(PerplexityClient.SearchRecency.allCases) { recency in
                        Text(recency.displayName).tag(recency)
                    }
                }
                .disabled(isLoading)
            }

            Toggle("Streaming", isOn: $isStreamingEnabled)
                .disabled(isLoading)

            HStack {
                Spacer()
                
                Button(action: sendMessage) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    } else {
                        Text("Send")
                    }
                }
                .disabled(inputText.isEmpty || isLoading)
            }
            
            ScrollView {
                Text(resultText)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity)
            .padding(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
            
            if !citations.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Sources:")
                        .font(.headline)
                    ForEach(citations, id: \.self) { citation in
                        Link(citation, destination: URL(string: citation)!)
                            .font(.caption)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(8)
            }
        }
        .padding()
        .navigationBarTitle("Perplexity Chat", displayMode: .inline)
    }
    
    private func sendMessage() {
        isLoading = true
        resultText = ""
        citations = []
        
        Task {
            do {
                let messages = [
                    PerplexityClient.Message(role: .system, content: "Be precise and concise."),
                    PerplexityClient.Message(role: .user, content: inputText)
                ]
                
                if isStreamingEnabled {
                    for try await result in client.sendStream(
                        messages: messages,
                        model: selectedModel,
                        searchRecency: selectedRecency.rawValue.isEmpty ? nil : selectedRecency.rawValue
                    ) {
                        await MainActor.run {
                            if !result.content.isEmpty {
                                resultText += result.content
                            }
                            if let citations = result.citations {
                                self.citations = citations
                            }
                        }
                    }
                } else {
                    let result = try await client.send(
                        messages: messages,
                        model: selectedModel,
                        searchRecency: selectedRecency.rawValue.isEmpty ? nil : selectedRecency.rawValue
                    )
                    await MainActor.run {
                        resultText = result.content
                        citations = result.citations ?? []
                    }
                }
            } catch {
                await MainActor.run {
                    resultText = "Error: \(error.localizedDescription)"
                }
            }
            
            await MainActor.run {
                isLoading = false
            }
        }
    }
}

#Preview {
    PerplexityView()
}
