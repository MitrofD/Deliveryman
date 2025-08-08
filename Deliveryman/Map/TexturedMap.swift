//
//  TexturedIsometricMap.swift
//  Deliveryman
//
//  Created by Dmitriy Mitrofansky on 08.08.25.
//

import SpriteKit

class TexturedMap: IsometricPathGrid {
    let textureAtlas: SKTextureAtlas
    var onReadyTexturedMap: () -> Void = {}

    required init(textureAtlas: SKTextureAtlas, size: CGSize, cellSize: CGSize) {
        self.textureAtlas = textureAtlas
        super.init(size: size, cellSize: cellSize)
        
        textureAtlas.preload { [weak self] in
            if let self = self {
                self.onReadyTexturedMap()
            }
        }
    }
    
    @MainActor required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
