//
//  AccessibilityUtils.swift
//  BubblePopGame
//
//  Created on 2025/07/20
//

import Foundation
import SwiftUI
import UIKit

struct AccessibilityUtils {
    
    // MARK: - Color Accessibility
    
    /// 色覚異常者に配慮した色を提供する
    static func accessibleColor(for originalColor: Color, isHighContrast: Bool = false) -> Color {
        if isHighContrast {
            return highContrastColor(for: originalColor)
        } else {
            return colorBlindFriendlyColor(for: originalColor)
        }
    }
    
    /// 高コントラストモード用の色を提供
    private static func highContrastColor(for color: Color) -> Color {
        switch color {
        case .blue:
            return Color(red: 0.0, green: 0.0, blue: 1.0) // Pure blue
        case .red:
            return Color(red: 1.0, green: 0.0, blue: 0.0) // Pure red
        case .green:
            return Color(red: 0.0, green: 1.0, blue: 0.0) // Pure green
        case .yellow:
            return Color(red: 1.0, green: 1.0, blue: 0.0) // Pure yellow
        case .purple:
            return Color(red: 1.0, green: 0.0, blue: 1.0) // Pure magenta
        case .orange:
            return Color(red: 1.0, green: 0.5, blue: 0.0) // High contrast orange
        default:
            return color
        }
    }
    
    /// 色覚異常者に配慮した色を提供
    private static func colorBlindFriendlyColor(for color: Color) -> Color {
        switch color {
        case .red:
            // 赤色の代わりに暖色系だが区別しやすい色
            return Color(red: 0.8, green: 0.2, blue: 0.0)
        case .green:
            // 緑色の代わりに青緑系
            return Color(red: 0.0, green: 0.7, blue: 0.6)
        case .blue:
            // 青色は比較的安全
            return Color(red: 0.0, green: 0.4, blue: 0.8)
        case .yellow:
            // 黄色は比較的安全
            return Color(red: 1.0, green: 0.9, blue: 0.0)
        case .purple:
            // 紫色を濃い青色に
            return Color(red: 0.3, green: 0.0, blue: 0.7)
        case .orange:
            // オレンジ色を暖色系だが区別しやすく
            return Color(red: 1.0, green: 0.6, blue: 0.0)
        default:
            return color
        }
    }
    
    // MARK: - Dynamic Type Support
    
    /// Dynamic Typeに対応したフォントサイズを計算
    static func accessibleFontSize(baseSize: CGFloat, category: UIContentSizeCategory) -> CGFloat {
        let scaleFactor: CGFloat
        
        switch category {
        case .extraSmall:
            scaleFactor = 0.8
        case .small:
            scaleFactor = 0.9
        case .medium:
            scaleFactor = 1.0
        case .large:
            scaleFactor = 1.1
        case .extraLarge:
            scaleFactor = 1.2
        case .extraExtraLarge:
            scaleFactor = 1.3
        case .extraExtraExtraLarge:
            scaleFactor = 1.4
        case .accessibilityMedium:
            scaleFactor = 1.6
        case .accessibilityLarge:
            scaleFactor = 1.8
        case .accessibilityExtraLarge:
            scaleFactor = 2.0
        case .accessibilityExtraExtraLarge:
            scaleFactor = 2.2
        case .accessibilityExtraExtraExtraLarge:
            scaleFactor = 2.4
        default:
            scaleFactor = 1.0
        }
        
        return baseSize * scaleFactor
    }
    
    // MARK: - Touch Target Size
    
    /// アクセシビリティガイドラインに準拠したタッチターゲットサイズを確保
    static func accessibleTouchTarget(for size: CGSize) -> CGSize {
        let minSize: CGFloat = 44.0 // iOS Human Interface Guidelines
        return CGSize(
            width: max(size.width, minSize),
            height: max(size.height, minSize)
        )
    }
    
    // MARK: - Reduce Motion Support
    
    /// Reduce Motionの設定に応じてアニメーション期間を調整
    static func accessibleAnimationDuration(_ baseDuration: Double, reduceMotion: Bool) -> Double {
        return reduceMotion ? baseDuration * 0.1 : baseDuration
    }
}

// MARK: - Environment Extensions

extension EnvironmentValues {
    var isHighContrastEnabled: Bool {
        UIAccessibility.isDarkerSystemColorsEnabled
    }
    
    var isReduceMotionEnabled: Bool {
        self.accessibilityReduceMotion
    }
}

// MARK: - Color Extensions

extension Color {
    /// 高コントラストまたは色覚異常者対応の色を取得
    func accessible(highContrast: Bool = false) -> Color {
        return AccessibilityUtils.accessibleColor(for: self, isHighContrast: highContrast)
    }
}