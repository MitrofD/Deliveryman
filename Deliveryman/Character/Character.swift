//
//  Character.swift
//  Deliveryman
//
//  Created by Dmitriy Mitrofansky on 15.11.22.
//

import SpriteKit

class Character: SKSpriteNode {
    static let stateActionKey = "stateAction"

    enum State: String {
        case idle
        case leftWalk
        case rightWalk
    }
    
    var textureAtlas: SKTextureAtlas {
        didSet {
            redrawState()
        }
    }
    
    var width: CGFloat {
        didSet {
            redrawState()
        }
    }
    
    private(set) var state = State.idle

    init(withTextureAtlasName textureAtlasName: String, width: CGFloat) {
        self.textureAtlas = SKTextureAtlas(named: "character-\(textureAtlasName)")
        self.width = width

        super.init(
            texture: nil,
            color: .clear,
            size: .zero
        )

        anchorPoint.y = .zero
        redrawState()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func idle() {
        state = .idle
    }

    func leftWalk() {
        state = .leftWalk
    }
    
    func rightWalk() {
        state = .rightWalk
    }
    
    private func redrawState() {
        switch state {
        case .idle:
            idle()
        case .leftWalk:
            leftWalk()
        case .rightWalk:
            rightWalk()
        }
    }
    
    func resizeToTexture(_ texture: SKTexture) {
        let image = texture.cgImage()

        var newSize = CGSize(
            width: image.width,
            height: image.height
        )

        let multiplier = width / newSize.width
        newSize.width *= multiplier
        newSize.height *= multiplier
        size = newSize
    }
    
    func preload(_ completionHandler: @escaping () -> Void) {
        textureAtlas.preload(completionHandler: completionHandler)
    }
}

