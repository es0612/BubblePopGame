//
//  ScoreCard.swift
//  BubblePopGame
//
//  Created on 2025/08/04
//

import SwiftUI

struct ScoreCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 5) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .padding()
        .background(Color(.systemBackground).opacity(0.9))
        .cornerRadius(10)
        .shadow(radius: 2)
    }
}