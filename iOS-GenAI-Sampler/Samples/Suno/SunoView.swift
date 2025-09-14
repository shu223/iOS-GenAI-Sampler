//
//  SunoView.swift
//  iOS-GenAI-Sampler
//
//  Created by Shuichi Tsutsumi on 2025/09/15.
//

import SwiftUI
import AVKit
import UniformTypeIdentifiers

struct SunoView: View {
    @State private var prompt = "A peaceful acoustic guitar melody with soft vocals, folk style"
    @State private var style = "Folk, Acoustic, Peaceful"
    @State private var title = "Peaceful Morning"
    @State private var negativeTags = ""
    @State private var customMode = false
    @State private var instrumental = false
    @State private var selectedModel: SunoClient.Model = .v3_5
    @State private var selectedVocalGender: SunoClient.VocalGender = .none
    @State private var isGenerating = false
    @State private var generatedMusic: [SunoClient.GeneratedMusic] = []
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var taskStatus = ""
    @State private var player: AVPlayer?
    @State private var isPlaying = false
    @State private var currentPlayingIndex: Int?
    @State private var showingExporter = false
    @State private var audioDataToExport: Data?
    @State private var exportFileName = ""
    @State private var isDownloading = false
    @State private var downloadingIndex: Int?

    private let client = SunoClient()

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                modelSection
                modeSection

                if customMode {
                    customModeInputSection
                } else {
                    simpleModeInputSection
                }

                advancedOptionsSection
                generateButton
                statusSection
                resultsSection
            }
            .padding()
        }
        .navigationBarTitle("Suno Music Generator", displayMode: .inline)
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage ?? "Unknown error occurred")
        }
        .fileExporter(
            isPresented: $showingExporter,
            document: audioDataToExport != nil ? AudioDocument(data: audioDataToExport!) : nil,
            contentType: .audio,
            defaultFilename: exportFileName
        ) { result in
            switch result {
            case .success(let url):
                print("[SunoView] File saved to: \(url)")
            case .failure(let error):
                print("[SunoView] Failed to save file: \(error)")
                errorMessage = "Failed to save file: \(error.localizedDescription)"
                showError = true
            }
        }
    }

    // MARK: - View Components

    private var modelSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Model")
                .font(.headline)

            Picker("Model", selection: $selectedModel) {
                ForEach(SunoClient.Model.allCases) { model in
                    Text(model.displayName).tag(model)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .disabled(isGenerating)
        }
    }

    private var modeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle("Custom Mode", isOn: $customMode)
                .disabled(isGenerating)

            Toggle("Instrumental (No Lyrics)", isOn: $instrumental)
                .disabled(isGenerating)
        }
    }

    private var simpleModeInputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Prompt")
                .font(.headline)

            TextEditor(text: $prompt)
                .frame(height: 100)
                .padding(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
                .disabled(isGenerating)

            Text("\(prompt.count)/\(selectedModel.maxPromptLength)")
                .font(.caption)
                .foregroundColor(prompt.count > selectedModel.maxPromptLength ? .red : .gray)
        }
    }

    private var customModeInputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !instrumental {
                Text("Prompt")
                    .font(.headline)

                TextEditor(text: $prompt)
                    .frame(height: 80)
                    .padding(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                    .disabled(isGenerating)

                Text("\(prompt.count)/\(selectedModel.maxPromptLength)")
                    .font(.caption)
                    .foregroundColor(prompt.count > selectedModel.maxPromptLength ? .red : .gray)
            }

            Text("Style")
                .font(.headline)

            TextField("Music style/genre", text: $style)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .disabled(isGenerating)

            Text("\(style.count)/\(selectedModel.maxStyleLength)")
                .font(.caption)
                .foregroundColor(style.count > selectedModel.maxStyleLength ? .red : .gray)

            Text("Title")
                .font(.headline)

            TextField("Song title", text: $title)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .disabled(isGenerating)

            Text("\(title.count)/80")
                .font(.caption)
                .foregroundColor(title.count > 80 ? .red : .gray)
        }
    }

    private var advancedOptionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Advanced Options")
                .font(.headline)

            HStack {
                Text("Vocal Gender")
                Spacer()
                Picker("Vocal Gender", selection: $selectedVocalGender) {
                    ForEach(SunoClient.VocalGender.allCases) { gender in
                        Text(gender.displayName).tag(gender)
                    }
                }
                .disabled(isGenerating || instrumental)
            }

            Text("Negative Tags")
                .font(.subheadline)

            TextField("Styles to exclude", text: $negativeTags)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .disabled(isGenerating)
        }
    }

    private var generateButton: some View {
        Button(action: generateMusic) {
            if isGenerating {
                HStack {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                    Text("Generating...")
                }
                .frame(maxWidth: .infinity)
            } else {
                Text("Generate Music")
                    .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(isGenerating ? Color.gray : Color.blue)
        .foregroundColor(.white)
        .cornerRadius(8)
        .disabled(isGenerating || !isInputValid)
    }

    private var statusSection: some View {
        Group {
            if !taskStatus.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Status")
                        .font(.headline)
                    Text(taskStatus)
                        .font(.caption)
                        .foregroundColor(.gray)

                    if isGenerating {
                        Text("⏱ Estimated time:")
                            .font(.caption)
                            .foregroundColor(.orange)
                            .padding(.top, 4)
                        Text("• Stream URL: 30-40 seconds")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text("• Full download: 2-3 minutes")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
        }
    }

    private var resultsSection: some View {
        Group {
            if !generatedMusic.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Generated Music")
                        .font(.headline)

                    ForEach(Array(generatedMusic.enumerated()), id: \.element.id) { index, music in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(music.title)
                                .font(.subheadline)
                                .fontWeight(.semibold)

                            if !music.tags.isEmpty {
                                Text(music.tags)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }

                            Text("Duration: \(formatDuration(music.duration))")
                                .font(.caption)
                                .foregroundColor(.gray)

                            HStack {
                                Button(action: {
                                    togglePlayback(index: index, url: music.audioUrl)
                                }) {
                                    HStack {
                                        Image(systemName: isPlaying && currentPlayingIndex == index ? "pause.fill" : "play.fill")
                                        Text(isPlaying && currentPlayingIndex == index ? "Pause" : "Play")
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)

                                Spacer()

                                Button(action: {
                                    downloadAudio(index: index, url: music.audioUrl, title: music.title)
                                }) {
                                    HStack {
                                        if isDownloading && downloadingIndex == index {
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                                .scaleEffect(0.8)
                                        } else {
                                            Image(systemName: "arrow.down.circle.fill")
                                        }
                                        Text("Save")
                                    }
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                                .disabled(isDownloading)

                                if let url = URL(string: music.audioUrl) {
                                    ShareLink(item: url) {
                                        Image(systemName: "square.and.arrow.up")
                                            .padding(8)
                                            .background(Color.gray.opacity(0.2))
                                            .cornerRadius(8)
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                    }
                }
            }
        }
    }

    // MARK: - Helper Properties

    private var isInputValid: Bool {
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

    // MARK: - Actions

    private func generateMusic() {
        isGenerating = true
        errorMessage = nil
        generatedMusic = []
        taskStatus = "Sending request..."
        stopPlayback()

        Task {
            do {
                print("[SunoView] Starting music generation...")
                print("[SunoView] Parameters:")
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

                taskStatus = "Task created: \(taskId)\nWaiting for completion..."
                print("[SunoView] Task created: \(taskId)")

                // Poll for completion
                for attempt in 1...60 {
                    taskStatus = "Checking status... (Attempt \(attempt)/60)"

                    let taskData = try await client.checkTaskStatus(taskId)
                    let status = taskData.status.uppercased()
                    print("[SunoView] Status check \(attempt)/60: \(status)")

                    switch status {
                    case "SUCCESS":
                        if let audioDataArray = taskData.response?.sunoData,
                           !audioDataArray.isEmpty {
                            generatedMusic = audioDataArray.compactMap { audioData in
                                guard let audioUrl = audioData.audioUrl else { return nil }
                                return SunoClient.GeneratedMusic(
                                    id: audioData.id,
                                    audioUrl: audioUrl,
                                    title: audioData.title ?? "Untitled",
                                    tags: audioData.tags ?? "",
                                    duration: audioData.duration ?? 0
                                )
                            }
                            taskStatus = "Music generated successfully!"
                            print("[SunoView] SUCCESS: Generated \(generatedMusic.count) tracks")
                            for music in generatedMusic {
                                print("[SunoView]   - \(music.title): \(music.audioUrl)")
                            }
                        } else {
                            print("[SunoView] ERROR: No audio data in response")
                            throw SunoClient.SunoError.invalidResponse("No audio data in response")
                        }
                        isGenerating = false
                        return

                    case "FAILED", "ERROR":
                        print("[SunoView] ERROR: Task failed with status: \(taskData.status)")
                        throw SunoClient.SunoError.taskFailed(taskData.status)

                    default:
                        try await Task.sleep(nanoseconds: 10_000_000_000) // 10 seconds
                    }
                }

                print("[SunoView] ERROR: Task timed out")
                throw SunoClient.SunoError.timeout

            } catch {
                print("[SunoView] ERROR: \(error)")
                print("[SunoView] Error Details: \(error.localizedDescription)")
                errorMessage = error.localizedDescription
                showError = true
                taskStatus = "Error: \(error.localizedDescription)"
                isGenerating = false
            }
        }
    }

    private func togglePlayback(index: Int, url: String) {
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

    private func stopPlayback() {
        player?.pause()
        player = nil
        isPlaying = false
        currentPlayingIndex = nil
    }

    private func formatDuration(_ seconds: Double) -> String {
        let minutes = Int(seconds) / 60
        let remainingSeconds = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }

    private func downloadAudio(index: Int, url: String, title: String) {
        guard let audioURL = URL(string: url) else { return }

        isDownloading = true
        downloadingIndex = index

        Task {
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
    }
}

// MARK: - AudioDocument for file export

struct AudioDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.audio] }

    let data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents {
            self.data = data
        } else {
            throw CocoaError(.fileReadCorruptFile)
        }
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        return FileWrapper(regularFileWithContents: data)
    }
}

