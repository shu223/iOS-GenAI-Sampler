import Foundation

class PerplexityClient {
    private let apiKey: String
    private let baseURL = "https://api.perplexity.ai/chat/completions"
    private var activeTask: Task<Void, Never>? {
        willSet {
            activeTask?.cancel()
        }
    }
    
    init(apiKey: String = apiKeyPerplexity) {
        self.apiKey = apiKey
    }
    
    struct Message: Codable {
        let role: String
        let content: String
    }
    
    struct Delta: Codable {
        let role: String?
        let content: String?
    }
    
    struct ChatRequest: Codable {
        let model: String
        let messages: [Message]
        let stream: Bool
        let temperature: Double?
        let maxTokens: Int?
        let topP: Double?
        let topK: Int?
        let presencePenalty: Double?
        let frequencyPenalty: Double?
        let searchDomainFilter: [String]?
        let returnImages: Bool?
        let returnRelatedQuestions: Bool?
        let searchRecencyFilter: String?

        enum CodingKeys: String, CodingKey {
            case model, messages, stream, temperature, topP, topK
            case maxTokens = "max_tokens"
            case presencePenalty = "presence_penalty"
            case frequencyPenalty = "frequency_penalty"
            case searchDomainFilter = "search_domain_filter"
            case returnImages = "return_images"
            case returnRelatedQuestions = "return_related_questions"
            case searchRecencyFilter = "search_recency_filter"
        }
    }
    
    struct ChatResponse: Codable {
        let id: String
        let model: String
        let object: String
        let created: Int
        let citations: [String]?
        let choices: [Choice]
        let usage: Usage
        
        struct Choice: Codable {
            let index: Int
            let message: Message
            let finishReason: String?
            let delta: Delta?
            
            enum CodingKeys: String, CodingKey {
                case index, message, delta
                case finishReason = "finish_reason"
            }
        }
        
        struct Usage: Codable {
            let promptTokens: Int
            let completionTokens: Int
            let totalTokens: Int
            
            enum CodingKeys: String, CodingKey {
                case promptTokens = "prompt_tokens"
                case completionTokens = "completion_tokens"
                case totalTokens = "total_tokens"
            }
        }
    }
    
    struct StreamResponse: Codable {
        let id: String?
        let model: String?
        let object: String?
        let created: Int?
        let citations: [String]?
        let choices: [StreamChoice]
        
        struct StreamChoice: Codable {
            let index: Int?
            let delta: Delta
            let finishReason: String?
            
            enum CodingKeys: String, CodingKey {
                case index, delta
                case finishReason = "finish_reason"
            }
        }
    }
    
    enum PerplexityError: LocalizedError {
        case invalidResponse(String)
        case decodingError(Error)
        case apiError(Int, String)
        case networkError(Error)
        case invalidURL
        case streamError(String)
        case invalidAPIKey
        case rateLimitExceeded
        case modelNotAvailable
        
        var errorDescription: String? {
            switch self {
            case .invalidResponse(let message):
                return "Invalid response: \(message)"
            case .decodingError(let error):
                return "Failed to decode response: \(error.localizedDescription)"
            case .apiError(let code, let message):
                return "API error (\(code)): \(message)"
            case .networkError(let error):
                return "Network error: \(error.localizedDescription)"
            case .invalidURL:
                return "Invalid URL"
            case .streamError(let message):
                return "Stream error: \(message)"
            case .invalidAPIKey:
                return "Invalid API key"
            case .rateLimitExceeded:
                return "API rate limit exceeded"
            case .modelNotAvailable:
                return "Specified model is not available"
            }
        }
    }
    
    enum Model: String, CaseIterable, Identifiable {
        case sonarSmall = "llama-3.1-sonar-small-128k-online"
        case sonarLarge = "llama-3.1-sonar-large-128k-online"
        case sonarHuge = "llama-3.1-sonar-huge-128k-online"

        var id: String { rawValue }
        
        var displayName: String {
            switch self {
            case .sonarSmall: return "Sonar Small"
            case .sonarLarge: return "Sonar Large"
            case .sonarHuge: return "Sonar Huge"
            }
        }
    }
    
    enum SearchRecency: String, CaseIterable, Identifiable {
        case none = ""
        case hour = "hour"
        case day = "day"
        case week = "week"
        case month = "month"
        
        var id: String { rawValue }
        
        var displayName: String {
            switch self {
            case .none: return "No filter"
            case .hour: return "Last hour"
            case .day: return "Last 24 hours"
            case .week: return "Last week"
            case .month: return "Last month"
            }
        }
    }
    
    private func createRequest(
        messages: [Message],
        model: Model,
        temperature: Double,
        searchRecency: String?,
        isStreaming: Bool
    ) throws -> URLRequest {
        var request = URLRequest(url: URL(string: baseURL)!)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let chatRequest = ChatRequest(
            model: model.rawValue,
            messages: messages,
            stream: isStreaming,
            temperature: temperature,
            maxTokens: nil,
            topP: 0.9,
            topK: 0,
            presencePenalty: 0,
            frequencyPenalty: 1,
            searchDomainFilter: ["perplexity.ai"],
            returnImages: false,
            returnRelatedQuestions: false,
            searchRecencyFilter: searchRecency
        )
        
        request.httpBody = try JSONEncoder().encode(chatRequest)
        return request
    }
    
    private func handleHTTPResponse(_ response: URLResponse) throws -> HTTPURLResponse {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PerplexityError.invalidResponse("Not an HTTP response")
        }
        return httpResponse
    }
    
    private func handleErrorStatus(_ statusCode: Int, errorData: Data) throws {
        let errorMessage: String
        if let errorJson = try? JSONSerialization.jsonObject(with: errorData) as? [String: Any],
           let message = errorJson["error"] as? String {
            errorMessage = message
        } else {
            errorMessage = String(data: errorData, encoding: .utf8) ?? "Unknown error"
        }
        
        switch statusCode {
        case 401: throw PerplexityError.invalidAPIKey
        case 429: throw PerplexityError.rateLimitExceeded
        case 404: throw PerplexityError.modelNotAvailable
        default: throw PerplexityError.apiError(statusCode, errorMessage)
        }
    }
    
    private func processStreamLine(_ line: String, citations: inout [String]?) throws -> (String, [String]?, Bool)? {
        guard !line.isEmpty else { return nil }
        guard line.hasPrefix("data: ") else {
            throw PerplexityError.streamError("Invalid stream format")
        }
        
        let json = String(line.dropFirst(6))
        guard json != "[DONE]" else { return nil }
        
        let streamResponse = try JSONDecoder().decode(StreamResponse.self, from: json.data(using: .utf8)!)
        let isFinished = streamResponse.choices.first?.finishReason != nil
        
        if let responseCitations = streamResponse.citations {
            citations = responseCitations
        }
        
        if isFinished {
            print("Stream finished with reason: \(streamResponse.choices.first?.finishReason ?? "unknown")")
            return ("", citations, true)
        }
        
        if let content = streamResponse.choices.first?.delta.content {
            return (content, citations, false)
        }
        
        if citations != nil {
            return ("", citations, false)
        }
        
        return nil
    }
    
    func send(
        messages: [Message],
        model: Model = .sonarSmall,
        temperature: Double = 0.2,
        searchRecency: String? = nil
    ) async throws -> (String, [String]?) {
        let request = try createRequest(
            messages: messages,
            model: model,
            temperature: temperature,
            searchRecency: searchRecency,
            isStreaming: false
        )
        
        let (data, response) = try await URLSession.shared.data(for: request)
        let httpResponse = try handleHTTPResponse(response)
        
        if !(200...299).contains(httpResponse.statusCode) {
            try handleErrorStatus(httpResponse.statusCode, errorData: data)
        }
        
        let chatResponse = try JSONDecoder().decode(ChatResponse.self, from: data)
        return (chatResponse.choices.first?.message.content ?? "", chatResponse.citations)
    }
    
    func sendStream(
        messages: [Message],
        model: Model = .sonarSmall,
        temperature: Double = 0.2,
        searchRecency: String? = nil
    ) -> AsyncThrowingStream<(String, [String]?), Error> {
        AsyncThrowingStream { continuation in
            activeTask?.cancel()
            
            let task = Task {
                do {
                    let request = try createRequest(
                        messages: messages,
                        model: model,
                        temperature: temperature,
                        searchRecency: searchRecency,
                        isStreaming: true
                    )
                    
                    let (result, response) = try await URLSession.shared.bytes(for: request)
                    let httpResponse = try handleHTTPResponse(response)
                    
                    if !(200...299).contains(httpResponse.statusCode) {
                        throw PerplexityError.apiError(httpResponse.statusCode, "Stream request failed")
                    }
                    
                    var citations: [String]?
                    
                    for try await line in result.lines {
                        if let (content, cits, isFinished) = try processStreamLine(line, citations: &citations) {
                            continuation.yield((content, cits))
                            
                            if isFinished {
                                break
                            }
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            
            activeTask = task
            continuation.onTermination = { @Sendable _ in
                task.cancel()
                self.activeTask = nil
            }
        }
    }
    
    func cancelCurrentTask() {
        activeTask?.cancel()
        activeTask = nil
    }
} 
