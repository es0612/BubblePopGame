//
//  ParticleEffectView.swift
//  BubblePopGame
//
//  Created on 2025/08/04
//

import SwiftUI

@Observable
@MainActor
class ParticleEffectViewModel {
    var effects: [ParticleEffectData] = []

    func addEffect(at position: CGPoint, color: Color) {
        let effect = ParticleEffectData(position: position, color: color)
        effects.append(effect)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.effects.removeAll { $0.id == effect.id }
        }
    }
}

struct ParticleEffectView: View {
    let viewModel: ParticleEffectViewModel

    var body: some View {
        ZStack {
            ForEach(viewModel.effects) { effect in
                ParticleEffect(position: effect.position, color: effect.color)
            }
        }
    }
}
