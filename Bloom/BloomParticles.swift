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
        emitter.emissionAngle = 0             // Center
        emitter.emissionAngleRange = 2 * .pi  // 360 degrees spread
        
        emitter.xAcceleration = 0
        emitter.yAcceleration = 0             // No gravity/wind, just drift
        
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

// MARK: - Finger Particles

struct TouchParticleOverlay: UIViewRepresentable {
    var touches: [TouchPoint]
    
    func makeUIView(context: Context) -> SKView {
        let view = SKView()
        view.backgroundColor = .clear
        view.allowsTransparency = true
        view.isUserInteractionEnabled = false // Let touches pass through
        
        let scene = TouchParticleScene()
        scene.scaleMode = .resizeFill
        scene.backgroundColor = .clear
        view.presentScene(scene)
        return view
    }
    
    func updateUIView(_ uiView: SKView, context: Context) {
        if let scene = uiView.scene as? TouchParticleScene {
            scene.updateParticleTargets(touches)
        }
    }
}

class TouchParticleScene: SKScene {
    var emitters: [Int: SKEmitterNode] = [:]
    
    override func didMove(to view: SKView) {
        self.size = view.bounds.size
        self.scaleMode = .resizeFill
        self.backgroundColor = .clear
        // Set anchor to bottom-left (default), we will manually flip Y
        self.anchorPoint = CGPoint.zero 
    }
    
    func updateParticleTargets(_ activeTouches: [TouchPoint]) {
        let activeIDs = Set(activeTouches.map { $0.id })
        
        // Update or create emitters
        for touch in activeTouches {
            // Flip Y coordinate (UIKit -> SpriteKit)
            let skLocation = CGPoint(x: touch.location.x, y: self.size.height - touch.location.y)
            
            if let emitter = emitters[touch.id] {
                emitter.position = skLocation
            } else {
                let emitter = createEmitter()
                emitter.position = skLocation
                addChild(emitter)
                emitters[touch.id] = emitter
            }
        }
        
        // Remove stale emitters
        for (id, emitter) in emitters {
            if !activeIDs.contains(id) {
                // Stop birthing new particles
                emitter.particleBirthRate = 0
                
                // Let existing particles die out then remove node
                // Lifetime is ~0.6s, wait 1s to be safe
                let wait = SKAction.wait(forDuration: 1.0)
                let remove = SKAction.removeFromParent()
                emitter.run(SKAction.sequence([wait, remove]))
                
                emitters.removeValue(forKey: id)
            }
        }
    }
    
    func createEmitter() -> SKEmitterNode {
        let emitter = SKEmitterNode()
        
        // We'll reuse the soft circle texture logic if possible, 
        // or create a new texture here to be self-contained.
        let texture = SKTexture(image: createSoftCircleImage())
        emitter.particleTexture = texture
        
        emitter.particleBirthRate = 80
        emitter.particleLifetime = 0.6
        emitter.particleLifetimeRange = 0.2
        
        // Emitting Area
        emitter.particlePositionRange = CGVector(dx: 40, dy: 40) // Increased emitting area
        
        // Appearance
        emitter.particleScale = 0.4
        emitter.particleScaleRange = 0.2
        emitter.particleScaleSpeed = -0.6 // Rapid shrink to avoid lingering "clouds"
        emitter.particleColor = .white
        emitter.particleBlendMode = .add
        emitter.particleColorBlendFactor = 1.0
        
        // Color Sequence: Gold -> Pink -> Purple -> Transparent
        let sequence = SKKeyframeSequence(
            keyframeValues: [
                UIColor(red: 1.0, green: 0.8, blue: 0.2, alpha: 1.0), // Gold
                UIColor.systemPink,
                UIColor.systemPurple,
                UIColor.clear
            ],
            times: [0.0, 0.3, 0.7, 1.0]
        )
        emitter.particleColorSequence = sequence
        
        // Physics
        emitter.particleSpeed = 40
        emitter.particleSpeedRange = 20
        emitter.emissionAngleRange = 2 * .pi
        emitter.particleAlpha = 0.8
        emitter.particleAlphaSpeed = -1.0 // Fade out
        
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
        // Mock touches for preview not easily possible without TouchPoint definition
    }
}
