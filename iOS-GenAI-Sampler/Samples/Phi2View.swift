//
//  Phi2View.swift
//  iOS-GenAI-Sampler
//
//  Created by Shuichi Tsutsumi on 2024/06/01.
//

import SwiftUI

struct Phi2View: View {
    var body: some View {
        LlamaCppView(models: [LlamaCppModel.phi2_Q4])
    }
}

#Preview {
    Phi2View()
}
