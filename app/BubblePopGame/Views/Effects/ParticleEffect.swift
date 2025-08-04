//
//  ParticleEffect.swift
//  BubblePopGame
//
//  Created on 2025/08/04
//

import SwiftUI

struct ParticleEffect: View {
    let position: CGPoint
    let color: Color
    @State private var particles: [Particle] = []
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                Circle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
                    .position(particle.position)
                    .opacity(particle.opacity)
                    .scaleEffect(particle.scale)
            }
        }
        .onAppear {
            createParticles()
            animateParticles()
        }
    }
    
    private func createParticles() {
        particles = []
        let particleCount = Int.random(in: 8...12)
        
        for _ in 0..<particleCount {
            let angle = Double.random(in: 0...(2 * .pi))
            let velocity = Double.random(in: 30...80)
            let size = Double.random(in: 4...12)
            
            let particle = Particle(
                position: position,
                velocity: CGVector(
                    dx: cos(angle) * velocity,
                    dy: sin(angle) * velocity
                ),
                color: color.opacity(Double.random(in: 0.6...1.0)),
                size: size,
                opacity: 1.0,
                scale: 1.0,
                lifespan: Double.random(in: 0.8...1.5)
            )
            particles.append(particle)
        }
    }
    
    private func animateParticles() {
        isAnimating = true
        
        let animationDuration = 1.5
        let steps = 60
        let stepDuration = animationDuration / Double(steps)
        
        for step in 0..<steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration * Double(step)) {
                updateParticles(progress: Double(step) / Double(steps))
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) {
            particles.removeAll()
            isAnimating = false
        }
    }
    
    private func updateParticles(progress: Double) {
        for i in particles.indices {
            let timeStep = 1.0 / 60.0
            
            particles[i].position.x += particles[i].velocity.dx * timeStep
            particles[i].position.y += particles[i].velocity.dy * timeStep
            
            particles[i].velocity.dy += 120 * timeStep
            
            particles[i].velocity.dx *= 0.98
            particles[i].velocity.dy *= 0.98
            
            let life = progress / particles[i].lifespan
            particles[i].opacity = max(0, 1.0 - life)
            particles[i].scale = 1.0 - (life * 0.5)
        }
    }
}