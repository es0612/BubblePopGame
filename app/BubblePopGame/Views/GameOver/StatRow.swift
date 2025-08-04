//
//  StatRow.swift
//  BubblePopGame
//
//  Created on 2025/08/04
//

import SwiftUI

struct StatRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.body)
                .foregroundColor(.primary)
            Spacer()
            Text(value)
                .font(.body)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
        }
    }
}