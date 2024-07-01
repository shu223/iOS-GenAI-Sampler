//
//  SupportedLanguagesView.swift
//  iOS-GenAI-Sampler
//
//  Created by Shuichi Tsutsumi on 2024/07/01.
//

import SwiftUI
import Translation

@available(iOS 18.0, *)
class SupportedLanguagesViewModel: ObservableObject {
    @Published var availableLanguages: [AvailableLanguage] = [] {
        didSet {
            let preferredLocale = Locale(identifier:Locale.preferredLanguages[0])
            selectedFrom = availableLanguages.first { $0.locale == preferredLocale.language }?.locale ?? availableLanguages.first?.locale
        }
    }
    @Published var selectedFrom: Locale.Language?
    @Published var languageStatuses: [Locale.Language: String] = [:]

    private let languageAvailability = LanguageAvailability()

    func prepareSupportedLanguages() async {
        let supportedLanguages = await languageAvailability.supportedLanguages
        await MainActor.run {
            availableLanguages = supportedLanguages.map { AvailableLanguage(locale: $0) }.sorted()
        }
    }

    func updateLanguageStatuses() async {
        print("\(type(of: self))/\(#function)")
        guard let selectedFrom = selectedFrom else { return }
        for language in availableLanguages {
            let status = await languageAvailability.status(from: selectedFrom, to: language.locale)
            await MainActor.run {
                languageStatuses[language.locale] = status.description
            }
        }
    }
}

@available(iOS 18.0, *)
struct SupportedLanguagesView: View {
    @StateObject private var viewModel = SupportedLanguagesViewModel()

    var body: some View {
        VStack(alignment: .leading) {
            Text("From:")
                .padding()
            Picker("Source", selection: $viewModel.selectedFrom) {
                ForEach(viewModel.availableLanguages) { language in
                    Text(language.localizedName)
                        .tag(Optional(language.locale))
                }
            }
            .onChange(of: viewModel.selectedFrom) {
                Task {
                    await viewModel.updateLanguageStatuses()
                }
            }
            .padding()

            Text("To:")
                .padding()
            List(viewModel.availableLanguages, id: \.self) { language in
                RightDetailRow(title: language.localizedName, detail: viewModel.languageStatuses[language.locale, default: "Loading..."])
            }
            .listStyle(.inset)
            .padding()
        }
        .onAppear {
            Task {
                await viewModel.prepareSupportedLanguages()
            }
        }
    }
}

#Preview {
    if #available(iOS 18.0, *) {
        SupportedLanguagesView()
    } else {
        // Fallback on earlier versions
    }
}
