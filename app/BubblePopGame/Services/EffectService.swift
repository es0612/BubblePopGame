//
//  EffectService.swift
//  BubblePopGame
//
//  Created on 2025/07/19
//

import Foundation
import SwiftUI
import UIKit

@MainActor
protocol EffectService {
    func createPopEffect(at position: CGPoint, color: Color)
    func triggerHapticFeedback(intensity: UIImpactFeedbackGenerator.FeedbackStyle)
    func triggerSuccessFeedback()
    func triggerWarningFeedback()
    func triggerErrorFeedback()
}

@MainActor
class EffectServiceImpl: EffectService {
    private let lightFeedback: UIImpactFeedbackGenerator
    private let mediumFeedback: UIImpactFeedbackGenerator
    private let heavyFeedback: UIImpactFeedbackGenerator
    private let selectionFeedback: UISelectionFeedbackGenerator
    private let notificationFeedback: UINotificationFeedbackGenerator
    
    var particleEffectViewModel: ParticleEffectViewModel?
    
    init() {
        self.lightFeedback = UIImpactFeedbackGenerator(style: .light)
        self.mediumFeedback = UIImpactFeedbackGenerator(style: .medium)
        self.heavyFeedback = UIImpactFeedbackGenerator(style: .heavy)
        self.selectionFeedback = UISelectionFeedbackGenerator()
        self.notificationFeedback = UINotificationFeedbackGenerator()
        
        // フィードバックジェネレーターの準備
        lightFeedback.prepare()
        mediumFeedback.prepare()
        heavyFeedback.prepare()
        selectionFeedback.prepare()
        notificationFeedback.prepare()
    }
    
    func createPopEffect(at position: CGPoint, color: Color) {
        // パーティクルエフェクトを作成
        particleEffectViewModel?.addEffect(at: position, color: color)
        debugLog("🎆 Pop effect created at: \(position)")
    }
    
    func triggerHapticFeedback(intensity: UIImpactFeedbackGenerator.FeedbackStyle) {
        switch intensity {
        case .light:
            lightFeedback.impactOccurred()
        case .medium:
            mediumFeedback.impactOccurred()
        case .heavy:
            heavyFeedback.impactOccurred()
        case .soft:
            lightFeedback.impactOccurred()
        case .rigid:
            heavyFeedback.impactOccurred()
        @unknown default:
            lightFeedback.impactOccurred()
        }
    }
    
    func triggerSuccessFeedback() {
        notificationFeedback.notificationOccurred(.success)
    }
    
    func triggerWarningFeedback() {
        notificationFeedback.notificationOccurred(.warning)
    }
    
    func triggerErrorFeedback() {
        notificationFeedback.notificationOccurred(.error)
    }
}