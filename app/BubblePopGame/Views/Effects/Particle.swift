//
//  Particle.swift
//  BubblePopGame
//
//  Created on 2025/08/04
//

import SwiftUI

struct Particle: Identifiable {
    let id = UUID()
    var position: CGPoint
    var velocity: CGVector
    let color: Color
    let size: Double
    var opacity: Double
    var scale: Double
    let lifespan: Double
}