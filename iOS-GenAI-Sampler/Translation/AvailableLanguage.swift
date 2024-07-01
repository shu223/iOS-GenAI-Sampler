//
//  AvailableLanguage.swift
//  iOS-GenAI-Sampler
//
//  Created by Shuichi Tsutsumi on 2024/07/01.
//

import Foundation

struct AvailableLanguage: Identifiable, Hashable, Comparable {
    var id: Self { self }
    let locale: Locale.Language

    var localizedName: String {
        let locale = Locale.current
        let shortName = shortName

        guard let localizedName = locale.localizedString(forLanguageCode: shortName) else {
            return "Unknown language code"
        }

        return "\(localizedName) (\(shortName))"
    }

    private var shortName: String {
        "\(locale.languageCode ?? "")-\(locale.region ?? "")"
    }

    static func <(lhs: AvailableLanguage, rhs: AvailableLanguage) -> Bool {
        return lhs.localizedName < rhs.localizedName
    }
}
