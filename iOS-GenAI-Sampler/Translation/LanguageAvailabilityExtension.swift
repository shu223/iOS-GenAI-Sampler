//
//  LanguageAvailabilityExtension.swift
//  iOS-GenAI-Sampler
//
//  Created by Shuichi Tsutsumi on 2024/07/01.
//

import Foundation
import Translation

@available(iOS 18.0, *)
extension LanguageAvailability.Status {
    var description: String {
        switch self {
        case .installed:
            return "Installed"
        case .supported:
            return "Supported"
        case .unsupported:
            return "Unsupported"
        @unknown default:
            fatalError()
        }
    }
}
