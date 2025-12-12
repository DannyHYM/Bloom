import SwiftUI
import SpriteKit
import UIKit

struct BloomParticles: View {
    var body: some View {
        SpriteView(scene: ParticleScene(), options: [.allowsTransparency])
            .ignoresSafeArea()
            .background(Color.clear)
    }
}

class ParticleScene: SKScene {
    override func didMove(to view: SKView) {
        size = view.bounds.size
        scaleMode = .resizeFill
        backgroundColor = .clear
        anchorPoint = CGPoint(x: 0.5, y: 0.5) // Center the scene
        
        let emitter = makeEmitter()
        addChild(emitter)
    }
    
    func makeEmitter() -> SKEmitterNode {
        let emitter = SKEmitterNode()
        
        let texture = SKTexture(image: createSoftCircleImage())
        emitter.particleTexture = texture
        
        emitter.particleBirthRate = 45        // More particles!
        emitter.particleLifetime = 5.5        // Longer life
        emitter.particleLifetimeRange = 2.0
        
        emitter.position = CGPoint.zero
        emitter.particlePositionRange = CGVector(dx: 100, dy: 100) // Wider birth area
        
        emitter.particleScale = 0.08          // Slightly larger
        emitter.particleScaleRange = 0.12     // More size variation
        emitter.particleScaleSpeed = -0.005   // Slower shrink
        emitter.particleColor = .white
        emitter.particleBlendMode = .add
        emitter.particleColorBlendFactor = 1.0
        
        let sequence = SKKeyframeSequence(
            keyframeValues: [
                UIColor.white,
                UIColor.systemTeal,
                UIColor.systemPurple,
                UIColor.systemYellow.withAlphaComponent(0.5),
                UIColor.clear
            ],
            times: [0.0, 0.15, 0.5, 0.8, 1.0]
        )
        emitter.particleColorSequence = sequence
        
        emitter.particleAlpha = 0.0
        emitter.particleAlphaSpeed = 0.8      // Faster fade in
        
        emitter.particleSpeed = 25
        emitter.particleSpeedRange = 15
        emitter.emissionAngle = .pi / 2       // Mostly upwards
        emitter.emissionAngleRange = .pi / 2  // But spreading out
        
        emitter.xAcceleration = 0
        emitter.yAcceleration = 15            // Stronger updraft
        
        emitter.fieldBitMask = 0 // No physics fields yet, but ready

        
        return emitter
    }
    
    func createSoftCircleImage() -> UIImage {
        let size = CGSize(width: 64, height: 64)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            let cgContext = context.cgContext
            
            let colors = [UIColor.white.cgColor, UIColor.clear.cgColor] as CFArray
            let locations: [CGFloat] = [0.0, 1.0]
            guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: locations) else { return }
            
            let center = CGPoint(x: 32, y: 32)
            cgContext.drawRadialGradient(gradient, startCenter: center, startRadius: 0, endCenter: center, endRadius: 32, options: [])
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        BloomParticles()
    }
}
