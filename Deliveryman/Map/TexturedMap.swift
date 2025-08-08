//
//  TexturedIsometricMap.swift
//  Deliveryman
//
//  Created by Dmitriy Mitrofansky on 08.08.25.
//

import SpriteKit

class TexturedMap: IsometricPathGrid {
    private var isLoadedTextureAtlas: Bool = false
    let textureAtlas: SKTextureAtlas
    var onReadyTexturedMap: () -> Void = {}

    required init(textureAtlas: SKTextureAtlas, size: CGSize, cellSize: CGSize) {
        self.textureAtlas = textureAtlas
        super.init(size: size, cellSize: cellSize)
        
        textureAtlas.preload { [weak self] in
            if let self = self {
                self.isLoadedTextureAtlas = true
                self.triggerOnReadyIfNeeded()
            }
        }
    }
    
    @MainActor required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didBuilt() {
        super.didBuilt()
        triggerOnReadyIfNeeded()
    }
    
    override func didReseted() {
        super.didReseted()
        triggerOnReadyIfNeeded()
    }
    
    private func triggerOnReadyIfNeeded() {
        if isFilled && isLoadedTextureAtlas {
            onReadyTexturedMap()
        }
    }
}
