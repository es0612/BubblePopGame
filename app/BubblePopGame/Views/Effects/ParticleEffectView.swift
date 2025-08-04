//
//  ParticleEffectView.swift
//  BubblePopGame
//
//  Created on 2025/08/04
//

import SwiftUI

struct ParticleEffectView: View {
    @State private var effects: [ParticleEffectData] = []
    
    var body: some View {
        ZStack {
            ForEach(effects) { effect in
                ParticleEffect(position: effect.position, color: effect.color)
            }
        }
    }
    
    func addEffect(at position: CGPoint, color: Color) {
        let effect = ParticleEffectData(position: position, color: color)
        effects.append(effect)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            effects.removeAll { $0.id == effect.id }
        }
    }
}