//
//  GameScene.swift
//  Deliveryman
//
//  Created by Dmitriy Mitrofansky on 05.10.22.
//

import SpriteKit

class GameScene: SKScene {
    override func sceneDidLoad() {
        super.sceneDidLoad()
        mapSettings()
    }
    
    func mapSettings() {
        let mapSize = CGSize(width: size.width, height: size.height)
        let map = SpringMap(size: mapSize)
        map.position = CGPoint(x: (self.size.width - mapSize.width) / 2, y: (self.size.height - mapSize.height) / 2)
        self.addChild(map)
        map.onReady = onReadyMap
        map.build()
    }
    
    // MARK: - Map hooks
    private func onReadyMap(_ map: MapProtocol) {
        map.moveByStep(duration: 0.5)
        /*
        let centerY = size.half.height
        
        for step in map.steps {
            if step.sprite.position.y >= centerY {
                let offset = step.sprite.position.y - centerY
                
                if offset > .zero {
                   // map.move(distance: offset)
                }

                step.sprite.texture = nil
                step.sprite.color = .green
                
                if let prevStep = step.prev {
                    prevStep.sprite.texture = nil
                    prevStep.sprite.color = .blue
                }
                
                if let nextStep = step.next {
                    nextStep.sprite.texture = nil
                    nextStep.sprite.color = .red
                }
                break
            }
        }
        */
    }
}
