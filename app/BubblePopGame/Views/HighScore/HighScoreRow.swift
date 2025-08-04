//
//  HighScoreRow.swift
//  BubblePopGame
//
//  Created on 2025/08/04
//

import SwiftUI

struct HighScoreRow: View {
    let rank: Int
    let score: GameScore
    
    var body: some View {
        HStack {
            // ランク表示
            Text("#\(rank)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(rankColor)
                .frame(width: 50)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("\(score.score)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text(score.gameMode == "numbered" ? "数字順" : "通常")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(score.gameMode == "numbered" ? Color.orange : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                
                HStack {
                    Text("破裂数: \(score.bubblesPopped)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("正確率: \(String(format: "%.1f%%", score.accuracy * 100))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("制限時間: \(Int(score.gameTimeLimit))秒")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("プレイ時間: \(String(format: "%.1f秒", score.gameDuration))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(score.playDate.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2)
                    .foregroundColor(Color.secondary.opacity(0.7))
            }
        }
        .padding()
        .background(Color(.systemBackground).opacity(0.9))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private var rankColor: Color {
        switch rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .brown
        default: return .primary
        }
    }
}