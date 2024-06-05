//
//  GemmaView.swift
//  iOS-GenAI-Sampler
//
//  Created by Shuichi Tsutsumi on 2024/06/05.
//

import SwiftUI

struct GemmaView: View {
    var body: some View {
        VStack {
            LlamaCppView(models: [.gemma_2B_Instruct_Q4, .gemma_2B_Instruct_Q8])
        }
    }
}

#Preview {
    GemmaView()
}
