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
    @State private var viewModel = SunoViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                modelSection
                modeSection

                if viewModel.customMode {
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
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") { }
        } message: {
            Text(viewModel.errorMessage ?? "Unknown error occurred")
        }
        .fileExporter(
            isPresented: $viewModel.showingExporter,
            document: viewModel.audioDataToExport != nil ? AudioDocument(data: viewModel.audioDataToExport!) : nil,
            contentType: .audio,
            defaultFilename: viewModel.exportFileName
        ) { result in
            viewModel.handleExportResult(result)
        }
    }

    // MARK: - View Components

    private var modelSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Model")
                .font(.headline)

            Picker("Model", selection: $viewModel.selectedModel) {
                ForEach(SunoClient.Model.allCases) { model in
                    Text(model.displayName).tag(model)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .disabled(viewModel.isGenerating)
        }
    }

    private var modeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle("Custom Mode", isOn: $viewModel.customMode)
                .disabled(viewModel.isGenerating)

            Toggle("Instrumental (No Lyrics)", isOn: $viewModel.instrumental)
                .disabled(viewModel.isGenerating)
        }
    }

    private var simpleModeInputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Prompt")
                .font(.headline)

            TextEditor(text: $viewModel.prompt)
                .frame(height: 100)
                .padding(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
                .disabled(viewModel.isGenerating)

            Text("\(viewModel.prompt.count)/\(viewModel.selectedModel.maxPromptLength)")
                .font(.caption)
                .foregroundColor(viewModel.prompt.count > viewModel.selectedModel.maxPromptLength ? .red : .gray)
        }
    }

    private var customModeInputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !viewModel.instrumental {
                Text("Prompt")
                    .font(.headline)

                TextEditor(text: $viewModel.prompt)
                    .frame(height: 80)
                    .padding(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                    .disabled(viewModel.isGenerating)

                Text("\(viewModel.prompt.count)/\(viewModel.selectedModel.maxPromptLength)")
                    .font(.caption)
                    .foregroundColor(viewModel.prompt.count > viewModel.selectedModel.maxPromptLength ? .red : .gray)
            }

            Text("Style")
                .font(.headline)

            TextField("Music style/genre", text: $viewModel.style)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .disabled(viewModel.isGenerating)

            Text("\(viewModel.style.count)/\(viewModel.selectedModel.maxStyleLength)")
                .font(.caption)
                .foregroundColor(viewModel.style.count > viewModel.selectedModel.maxStyleLength ? .red : .gray)

            Text("Title")
                .font(.headline)

            TextField("Song title", text: $viewModel.title)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .disabled(viewModel.isGenerating)

            Text("\(viewModel.title.count)/80")
                .font(.caption)
                .foregroundColor(viewModel.title.count > 80 ? .red : .gray)
        }
    }

    private var advancedOptionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Advanced Options")
                .font(.headline)

            HStack {
                Text("Vocal Gender")
                Spacer()
                Picker("Vocal Gender", selection: $viewModel.selectedVocalGender) {
                    ForEach(SunoClient.VocalGender.allCases) { gender in
                        Text(gender.displayName).tag(gender)
                    }
                }
                .disabled(viewModel.isGenerating || viewModel.instrumental)
            }

            Text("Negative Tags")
                .font(.subheadline)

            TextField("Styles to exclude", text: $viewModel.negativeTags)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .disabled(viewModel.isGenerating)
        }
    }

    private var generateButton: some View {
        Button(action: {
            Task {
                await viewModel.generateMusic()
            }
        }) {
            if viewModel.isGenerating {
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
        .background(viewModel.isGenerating ? Color.gray : Color.blue)
        .foregroundColor(.white)
        .cornerRadius(8)
        .disabled(viewModel.isGenerating || !viewModel.isInputValid)
    }

    private var statusSection: some View {
        Group {
            if !viewModel.taskStatus.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Status")
                        .font(.headline)
                    Text(viewModel.taskStatus)
                        .font(.caption)
                        .foregroundColor(.gray)

                    if viewModel.isGenerating {
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
            if !viewModel.generatedMusic.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Generated Music")
                        .font(.headline)

                    ForEach(Array(viewModel.generatedMusic.enumerated()), id: \.element.id) { index, music in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(music.title)
                                .font(.subheadline)
                                .fontWeight(.semibold)

                            if !music.tags.isEmpty {
                                Text(music.tags)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }

                            Text("Duration: \(viewModel.formatDuration(music.duration))")
                                .font(.caption)
                                .foregroundColor(.gray)

                            HStack {
                                Button(action: {
                                    viewModel.togglePlayback(index: index, url: music.audioUrl)
                                }) {
                                    HStack {
                                        Image(systemName: viewModel.isPlaying && viewModel.currentPlayingIndex == index ? "pause.fill" : "play.fill")
                                        Text(viewModel.isPlaying && viewModel.currentPlayingIndex == index ? "Pause" : "Play")
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)

                                Spacer()

                                Button(action: {
                                    Task {
                                        await viewModel.prepareDownload(index: index, url: music.audioUrl, title: music.title)
                                    }
                                }) {
                                    HStack {
                                        if viewModel.isDownloading && viewModel.downloadingIndex == index {
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
                                .disabled(viewModel.isDownloading)

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