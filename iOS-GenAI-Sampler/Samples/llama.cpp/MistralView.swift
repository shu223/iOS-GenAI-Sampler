//
//  MistralView.swift
//  iOS-GenAI-Sampler
//
//  Created by Shuichi Tsutsumi on 2024/05/31.
//

import SwiftUI

struct MistralView: View {
    var body: some View {
        LlamaCppView(models: [LlamaCppModel.mistral_7B_Q4])
    }
}

#Preview {
    MistralView()
}
