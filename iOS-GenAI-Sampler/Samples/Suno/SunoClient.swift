//
//  SunoClient.swift
//  iOS-GenAI-Sampler
//
//  Created by Shuichi Tsutsumi on 2025/09/15.
//

import Foundation

class SunoClient {
    private let apiKey: String
    private let baseURL = "https://api.sunoapi.org"
    private var activeTask: URLSessionDataTask?

    init(apiKey: String = apiKeySuno) {
        self.apiKey = apiKey
    }

    // MARK: - Types

    enum Model: String, CaseIterable, Identifiable {
        case v3_5 = "V3_5"
        case v4 = "V4"
        case v4_5 = "V4_5"

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .v3_5: return "V3.5 - Balanced (4 min)"
            case .v4: return "V4 - High Quality (4 min)"
            case .v4_5: return "V4.5 - Advanced (8 min)"
            }
        }

        var maxPromptLength: Int {
            switch self {
            case .v3_5, .v4: return 3000
            case .v4_5: return 5000
            }
        }

        var maxStyleLength: Int {
            switch self {
            case .v3_5, .v4: return 200
            case .v4_5: return 1000
            }
        }
    }

    enum VocalGender: String, CaseIterable, Identifiable {
        case none = ""
        case male = "m"
        case female = "f"

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .none: return "Auto"
            case .male: return "Male"
            case .female: return "Female"
            }
        }
    }

    struct GenerateRequest: Codable {
        let customMode: Bool
        let instrumental: Bool
        let model: String
        let prompt: String?
        let style: String?
        let title: String?
        let negativeTags: String?
        let vocalGender: String?
        let styleWeight: Double?
        let weirdnessConstraint: Double?
        let audioWeight: Double?
        let callBackUrl: String
    }

    struct GenerateResponse: Codable {
        let code: Int
        let msg: String
        let data: GenerateData?

        struct GenerateData: Codable {
            let taskId: String
        }
    }

    struct TaskStatusResponse: Codable {
        let code: Int
        let msg: String
        let data: TaskData?

        struct TaskData: Codable {
            let taskId: String
            let status: String
            let response: TaskResponse?
            let errorCode: String?
            let errorMessage: String?

            struct TaskResponse: Codable {
                let taskId: String?
                let sunoData: [AudioData]?

                struct AudioData: Codable {
                    let id: String
                    let audioUrl: String?
                    let streamAudioUrl: String?
                    let imageUrl: String?
                    let title: String?
                    let tags: String?
                    let duration: Double?
                    let createTime: Double?
                    let modelName: String?
                    let prompt: String?
                }
            }
        }
    }

    enum SunoError: LocalizedError {
        case invalidResponse(String)
        case decodingError(Error)
        case apiError(Int, String)
        case networkError(Error)
        case invalidURL
        case invalidAPIKey
        case taskFailed(String)
        case timeout

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
            case .invalidAPIKey:
                return "Invalid API key"
            case .taskFailed(let message):
                return "Task failed: \(message)"
            case .timeout:
                return "Request timed out"
            }
        }
    }

    struct GeneratedMusic {
        let id: String
        let audioUrl: String
        let title: String
        let tags: String
        let duration: Double
    }

    // MARK: - Public Methods

    func generateMusic(
        prompt: String? = nil,
        style: String? = nil,
        title: String? = nil,
        customMode: Bool = false,
        instrumental: Bool = false,
        model: Model = .v3_5,
        negativeTags: String? = nil,
        vocalGender: VocalGender = .none
    ) async throws -> String {
        let endpoint = "\(baseURL)/api/v1/generate"
        print("[SunoClient] Generating music with endpoint: \(endpoint)")
        print("[SunoClient] Parameters - customMode: \(customMode), instrumental: \(instrumental), model: \(model.rawValue)")

        guard let url = URL(string: endpoint) else {
            print("[SunoClient] ERROR: Invalid URL - \(endpoint)")
            throw SunoError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        // Use a dummy callback URL since we'll use polling instead
        let callBackUrl = "https://example.com/callback"

        let generateRequest = GenerateRequest(
            customMode: customMode,
            instrumental: instrumental,
            model: model.rawValue,
            prompt: prompt,
            style: style,
            title: title,
            negativeTags: negativeTags,
            vocalGender: vocalGender.rawValue.isEmpty ? nil : vocalGender.rawValue,
            styleWeight: nil,
            weirdnessConstraint: nil,
            audioWeight: nil,
            callBackUrl: callBackUrl
        )
        print("[SunoClient] Using callback URL: \(callBackUrl) (will poll for status)")

        request.httpBody = try JSONEncoder().encode(generateRequest)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            print("[SunoClient] ERROR: Not an HTTP response")
            throw SunoError.invalidResponse("Not an HTTP response")
        }

        print("[SunoClient] Response status code: \(httpResponse.statusCode)")

        if httpResponse.statusCode == 401 {
            print("[SunoClient] ERROR: Invalid API key")
            throw SunoError.invalidAPIKey
        }

        if !(200...299).contains(httpResponse.statusCode) {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("[SunoClient] ERROR: API error (\(httpResponse.statusCode)): \(errorMessage)")
            throw SunoError.apiError(httpResponse.statusCode, errorMessage)
        }

        let responseString = String(data: data, encoding: .utf8) ?? "Unable to decode"
        print("[SunoClient] Raw response: \(responseString)")

        let generateResponse = try JSONDecoder().decode(GenerateResponse.self, from: data)

        if generateResponse.code != 200 {
            print("[SunoClient] ERROR: Response code \(generateResponse.code): \(generateResponse.msg)")
            throw SunoError.apiError(generateResponse.code, generateResponse.msg)
        }

        guard let taskId = generateResponse.data?.taskId else {
            print("[SunoClient] ERROR: No task ID in response")
            throw SunoError.invalidResponse("No task ID in response")
        }

        print("[SunoClient] Task created successfully with ID: \(taskId)")
        return taskId
    }

    func checkTaskStatus(_ taskId: String) async throws -> TaskStatusResponse.TaskData {
        let endpoint = "\(baseURL)/api/v1/generate/record-info?taskId=\(taskId)"
        print("[SunoClient] Checking task status: \(endpoint)")

        guard let url = URL(string: endpoint) else {
            print("[SunoClient] ERROR: Invalid URL - \(endpoint)")
            throw SunoError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            print("[SunoClient] ERROR: Not an HTTP response")
            throw SunoError.invalidResponse("Not an HTTP response")
        }

        if httpResponse.statusCode == 401 {
            print("[SunoClient] ERROR: Invalid API key")
            throw SunoError.invalidAPIKey
        }

        if !(200...299).contains(httpResponse.statusCode) {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("[SunoClient] ERROR: Status check failed (\(httpResponse.statusCode)): \(errorMessage)")
            throw SunoError.apiError(httpResponse.statusCode, errorMessage)
        }

        let responseString = String(data: data, encoding: .utf8) ?? "Unable to decode"
        print("[SunoClient] Raw status response: \(responseString)")

        let statusResponse = try JSONDecoder().decode(TaskStatusResponse.self, from: data)
        print("[SunoClient] Task status: \(statusResponse.data?.status ?? "unknown")")

        if statusResponse.code != 200 {
            print("[SunoClient] ERROR: Response code \(statusResponse.code): \(statusResponse.msg)")
            throw SunoError.apiError(statusResponse.code, statusResponse.msg)
        }

        guard let taskData = statusResponse.data else {
            print("[SunoClient] ERROR: No task data in response")
            throw SunoError.invalidResponse("No task data in response")
        }

        return taskData
    }

    func waitForCompletion(taskId: String, maxAttempts: Int = 30, delaySeconds: UInt64 = 10) async throws -> [GeneratedMusic] {
        print("[SunoClient] Waiting for task completion: \(taskId)")

        for attempt in 0..<maxAttempts {
            let taskData = try await checkTaskStatus(taskId)
            let status = taskData.status.uppercased()
            print("[SunoClient] Attempt \(attempt + 1)/\(maxAttempts) - Status: \(status)")

            switch status {
            case "SUCCESS":
                guard let audioDataArray = taskData.response?.sunoData,
                      !audioDataArray.isEmpty else {
                    print("[SunoClient] ERROR: No audio data in completed task")
                    throw SunoError.invalidResponse("No audio data in completed task")
                }

                let generatedMusic: [GeneratedMusic] = audioDataArray.compactMap { audioData in
                    guard let audioUrl = audioData.audioUrl else { return nil }
                    return GeneratedMusic(
                        id: audioData.id,
                        audioUrl: audioUrl,
                        title: audioData.title ?? "Untitled",
                        tags: audioData.tags ?? "",
                        duration: audioData.duration ?? 0
                    )
                }
                print("[SunoClient] SUCCESS: Generated \(generatedMusic.count) music tracks")
                for music in generatedMusic {
                    print("[SunoClient]   - \(music.title): \(music.audioUrl)")
                }
                return generatedMusic

            case "FAILED", "ERROR":
                print("[SunoClient] ERROR: Task failed with status: \(taskData.status)")
                throw SunoError.taskFailed(taskData.status)

            case "PENDING", "PROCESSING":
                try await Task.sleep(nanoseconds: delaySeconds * 1_000_000_000)
                continue

            default:
                try await Task.sleep(nanoseconds: delaySeconds * 1_000_000_000)
                continue
            }
        }

        print("[SunoClient] ERROR: Task timed out after \(maxAttempts) attempts")
        throw SunoError.timeout
    }

    func generateAndWaitForMusic(
        prompt: String? = nil,
        style: String? = nil,
        title: String? = nil,
        customMode: Bool = false,
        instrumental: Bool = false,
        model: Model = .v3_5,
        negativeTags: String? = nil,
        vocalGender: VocalGender = .none
    ) async throws -> [GeneratedMusic] {
        let taskId = try await generateMusic(
            prompt: prompt,
            style: style,
            title: title,
            customMode: customMode,
            instrumental: instrumental,
            model: model,
            negativeTags: negativeTags,
            vocalGender: vocalGender
        )

        return try await waitForCompletion(taskId: taskId)
    }
}
