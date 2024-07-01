//
//  RightDetailRow.swift
//  iOS-GenAI-Sampler
//
//  Created by Shuichi Tsutsumi on 2024/07/01.
//

import SwiftUI

struct RightDetailRow: View {
    var title: String
    var detail: String

    var body: some View {
        HStack {
            Text(title)
                .font(.body)
                .foregroundColor(.primary)
            Spacer()
            Text(detail)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    RightDetailRow(title: "Title", detail: "Detail")
}
