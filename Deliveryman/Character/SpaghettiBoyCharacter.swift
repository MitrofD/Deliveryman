//
//  SpaghettiBoyCharacter.swift
//  Deliveryman
//
//  Created by Dmitriy Mitrofansky on 16.11.22.
//

import SpriteKit

class SpaghettiBoyCharacter: Character {
    required init(withWidth width: CGFloat) {
        super.init(withTextureAtlasName: "spaghetti-boy", width: width)

        anchorPoint.y = 0.1
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func walk() {
        let startTexure = textureAtlas.textureNamed("walk-0")

        let action = SKAction.repeatForever(SKAction.animate(
            with: [
                startTexure,
                textureAtlas.textureNamed("walk-1"),
                textureAtlas.textureNamed("walk-2"),
                textureAtlas.textureNamed("walk-3"),
                textureAtlas.textureNamed("walk-4"),
                textureAtlas.textureNamed("walk-5"),
            ],
            timePerFrame: 0.1
        ))
        
        resizeToTexture(startTexure)
        run(action, withKey: Self.stateActionKey)
    }

    // MARK: - States
    override func idle() {
        super.idle()

        let frontTexture = textureAtlas.textureNamed("idle-0")
        let waitAction = SKAction.wait(forDuration: 0.3)
        
        let action = SKAction.repeatForever(SKAction.sequence([
            SKAction.setTexture(frontTexture),
            waitAction,
            SKAction.setTexture(textureAtlas.textureNamed("idle-1")),
            waitAction,
            SKAction.run {
                self.flipHorizontally()
            }
        ]))
        
        resizeToTexture(frontTexture)
        run(action, withKey: Self.stateActionKey)
    }
    
    override func leftWalk() {
        super.leftWalk()
        
        if isFlippedHorizontally {
            flipHorizontally()
        }

        walk()
    }
    
    override func rightWalk() {
        super.rightWalk()
        
        if !isFlippedHorizontally {
            flipHorizontally()
        }

        walk()
    }
}
