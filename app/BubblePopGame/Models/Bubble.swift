//
//  Bubble.swift
//  BubblePopGame
//
//  Created on 2025/07/19
//

import Foundation
import SwiftUI

struct Bubble: Identifiable {
    let id = UUID()
    var position: CGPoint
    var velocity: CGVector
    var radius: CGFloat
    var type: BubbleType
    var number: Int?
    var color: Color
    var alpha: Double
    var animationPhase: Double
    var isPopping: Bool = false
}