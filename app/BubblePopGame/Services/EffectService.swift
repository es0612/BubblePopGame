//
//  EffectService.swift
//  BubblePopGame
//
//  Created on 2025/07/19
//

import Foundation
import SwiftUI
import UIKit

protocol EffectService {
    func createPopEffect(at position: CGPoint, color: Color)
    func triggerHapticFeedback(intensity: UIImpactFeedbackGenerator.FeedbackStyle)
}

class EffectServiceImpl: EffectService {
    private let hapticFeedback: UIImpactFeedbackGenerator
    
    init() {
        self.hapticFeedback = UIImpactFeedbackGenerator()
        hapticFeedback.prepare()
    }
    
    func createPopEffect(at position: CGPoint, color: Color) {
        // TODO: パーティクルエフェクト実装
        print("Creating pop effect at position: \(position) with color: \(color)")
    }
    
    func triggerHapticFeedback(intensity: UIImpactFeedbackGenerator.FeedbackStyle) {
        hapticFeedback.impactOccurred(intensity: intensity)
    }
}