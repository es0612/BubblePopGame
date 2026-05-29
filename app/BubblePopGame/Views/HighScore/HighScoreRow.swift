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
                    
                    // 既存の highscore_* キーを再利用
                    Text(NSLocalizedString(score.gameMode == "numbered" ? "highscore_numbered_mode" : "highscore_normal_mode", comment: "Game mode badge"))
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(score.gameMode == "numbered" ? Color.orange : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                
                HStack {
                    // ラベルは既存キー（game_bubbles_popped / gameover_accuracy）を再利用し、値を連結
                    Text("\(NSLocalizedString("game_bubbles_popped", comment: "Bubbles popped label")): \(score.bubblesPopped)")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    Text("\(NSLocalizedString("gameover_accuracy", comment: "Accuracy label")): \(String(format: NSLocalizedString("percentage_format", comment: "Percentage format"), score.accuracy * 100))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    // highscore_time_limit は値に ":" を含むためラベル後はスペース区切り。整数秒は seconds_format
                    Text("\(NSLocalizedString("highscore_time_limit", comment: "Time limit label (includes colon)")) \(String(format: NSLocalizedString("seconds_format", comment: "Integer seconds format"), Int(score.gameTimeLimit)))")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    // gameover_play_time ラベル + 小数秒（新規 seconds_decimal_format）
                    Text("\(NSLocalizedString("gameover_play_time", comment: "Play time label")): \(String(format: NSLocalizedString("seconds_decimal_format", comment: "Decimal seconds format"), score.gameDuration))")
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