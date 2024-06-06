//
//  CustomModifiers.swift
//  iOS-GenAI-Sampler
//
//  Created by Shuichi Tsutsumi on 2024/06/04.
//

import SwiftUI

struct HeadlineTextModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .font(.headline)
            .foregroundColor(.secondary)
    }
}

struct LeadingFrameModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

extension View {
    func headlineText() -> some View {
        modifier(HeadlineTextModifier())
    }

    func leadingFrame() -> some View {
        modifier(LeadingFrameModifier())
    }
}
