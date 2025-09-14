//
//  SunoViewModel.swift
//  iOS-GenAI-Sampler
//
//  Created by Shuichi Tsutsumi on 2025/09/15.
//

import Foundation
import AVKit
import Observation

@Observable
class SunoViewModel {
    // MARK: - Input Properties
    var prompt = "A peaceful acoustic guitar melody with soft vocals, folk style"
    var style = "Folk, Acoustic, Peaceful"
    var title = "Peaceful Morning"
    var negativeTags = ""
    var customMode = false
    var instrumental = false
    var selectedModel: SunoClient.Model = .v3_5
    var selectedVocalGender: SunoClient.VocalGender = .none

    // MARK: - State Properties
    var isGenerating = false
    var generatedMusic: [SunoClient.GeneratedMusic] = []
    var errorMessage: String?
    var showError = false
    var taskStatus = ""

    // MARK: - Playback Properties
    var player: AVPlayer?
    var isPlaying = false
    var currentPlayingIndex: Int?

    // MARK: - Export Properties
    var showingExporter = false
    var audioDataToExport: Data?
    var exportFileName = ""
    var isDownloading = false
    var downloadingIndex: Int?

    // MARK: - Client
    private let client = SunoClient()

    // MARK: - Computed Properties

    var isInputValid: Bool {
        if customMode {
            let styleValid = !style.isEmpty && style.count <= selectedModel.maxStyleLength
            let titleValid = !title.isEmpty && title.count <= 80

            if instrumental {
                return styleValid && titleValid
            } else {
                let promptValid = !prompt.isEmpty && prompt.count <= selectedModel.maxPromptLength
                return promptValid && styleValid && titleValid
            }
        } else {
            return !prompt.isEmpty && prompt.count <= selectedModel.maxPromptLength
        }
    }

    // MARK: - Music Generation

    func generateMusic() async {
        await MainActor.run {
            isGenerating = true
            errorMessage = nil
            generatedMusic = []
            taskStatus = "Sending request..."
            stopPlayback()
        }

        do {
            print("[SunoViewModel] Starting music generation...")
            print("[SunoViewModel] Parameters:")
            print("  - Prompt: \(customMode ? (instrumental ? "N/A" : prompt) : prompt)")
            print("  - Style: \(customMode ? style : "N/A")")
            print("  - Title: \(customMode ? title : "N/A")")
            print("  - Model: \(selectedModel.displayName)")
            print("  - Custom Mode: \(customMode)")
            print("  - Instrumental: \(instrumental)")

            let taskId = try await client.generateMusic(
                prompt: customMode ? (instrumental ? nil : prompt) : prompt,
                style: customMode ? style : nil,
                title: customMode ? title : nil,
                customMode: customMode,
                instrumental: instrumental,
                model: selectedModel,
                negativeTags: negativeTags.isEmpty ? nil : negativeTags,
                vocalGender: selectedVocalGender
            )

            await MainActor.run {
                taskStatus = "Task created: \(taskId)\nWaiting for completion..."
            }
            print("[SunoViewModel] Task created: \(taskId)")

            // Poll for completion
            for attempt in 1...60 {
                await MainActor.run {
                    taskStatus = "Checking status... (Attempt \(attempt))"
                }

                let taskData = try await client.checkTaskStatus(taskId)
                let status = taskData.status.uppercased()
                print("[SunoViewModel] Status check \(attempt): \(status)")

                switch status {
                case "SUCCESS":
                    if let audioDataArray = taskData.response?.sunoData,
                       !audioDataArray.isEmpty {
                        let music: [SunoClient.GeneratedMusic] = audioDataArray.compactMap { audioData in
                            guard let audioUrl = audioData.audioUrl else { return nil }
                            return SunoClient.GeneratedMusic(
                                id: audioData.id,
                                audioUrl: audioUrl,
                                title: audioData.title ?? "Untitled",
                                tags: audioData.tags ?? "",
                                duration: audioData.duration ?? 0
                            )
                        }

                        await MainActor.run {
                            generatedMusic = music
                            taskStatus = "Music generated successfully!"
                            isGenerating = false
                        }

                        print("[SunoViewModel] SUCCESS: Generated \(music.count) tracks")
                        for item in music {
                            print("[SunoViewModel]   - \(item.title): \(item.audioUrl)")
                        }
                        return
                    } else {
                        print("[SunoViewModel] ERROR: No audio data in response")
                        throw SunoClient.SunoError.invalidResponse("No audio data in response")
                    }

                case "FAILED", "ERROR":
                    print("[SunoViewModel] ERROR: Task failed with status: \(taskData.status)")
                    throw SunoClient.SunoError.taskFailed(taskData.status)

                default:
                    try await Task.sleep(nanoseconds: 10_000_000_000) // 10 seconds
                }
            }

            print("[SunoViewModel] ERROR: Task timed out")
            throw SunoClient.SunoError.timeout

        } catch {
            print("[SunoViewModel] ERROR: \(error)")
            print("[SunoViewModel] Error Details: \(error.localizedDescription)")

            await MainActor.run {
                errorMessage = error.localizedDescription
                showError = true
                taskStatus = "Error: \(error.localizedDescription)"
                isGenerating = false
            }
        }
    }

    // MARK: - Playback Control

    func togglePlayback(index: Int, url: String) {
        if isPlaying && currentPlayingIndex == index {
            stopPlayback()
        } else {
            playAudio(index: index, url: url)
        }
    }

    private func playAudio(index: Int, url: String) {
        guard let audioURL = URL(string: url) else { return }

        stopPlayback()

        player = AVPlayer(url: audioURL)
        player?.play()
        isPlaying = true
        currentPlayingIndex = index

        // Monitor playback completion
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player?.currentItem,
            queue: .main
        ) { _ in
            self.stopPlayback()
        }
    }

    func stopPlayback() {
        player?.pause()
        player = nil
        isPlaying = false
        currentPlayingIndex = nil
    }

    // MARK: - Audio Download

    func prepareDownload(index: Int, url: String, title: String) async {
        guard let audioURL = URL(string: url) else { return }

        await MainActor.run {
            isDownloading = true
            downloadingIndex = index
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: audioURL)

            await MainActor.run {
                audioDataToExport = data
                exportFileName = "\(title).mp3"
                showingExporter = true
                isDownloading = false
                downloadingIndex = nil
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to download audio: \(error.localizedDescription)"
                showError = true
                isDownloading = false
                downloadingIndex = nil
            }
        }
    }

    // MARK: - Helper Methods

    func formatDuration(_ seconds: Double) -> String {
        let minutes = Int(seconds) / 60
        let remainingSeconds = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }

    func handleExportResult(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            print("[SunoViewModel] File saved to: \(url)")
        case .failure(let error):
            print("[SunoViewModel] Failed to save file: \(error)")
            errorMessage = "Failed to save file: \(error.localizedDescription)"
            showError = true
        }
    }
}
