//
//  Phi3View.swift
//  iOS-GenAI-Sampler
//
//  Created by Shuichi Tsutsumi on 2024/06/04.
//

import SwiftUI

struct Phi3View: View {
    var body: some View {
        LlamaCppView(models: [LlamaCppModel.phi3_Mini_4K_Instruct_Q4])
    }
}

#Preview {
    Phi3View()
}
