//
//  SpringMap.swift
//  Deliveryman
//
//  Created by Dmitriy Mitrofansky on 04.08.25.
//

import SpriteKit

class SpringMap: TexturedMap, MapProtocol {
    var onReadyMap: (_ any: MapProtocol) -> Void = { _ in }
    
    required init(size: CGSize) {
        super.init(textureAtlas: SKTextureAtlas(named: "map-spring"), size: size)
        
        self.onReady = { [weak self] in
            if let self = self {
                self.onReadyMap(self)
            }
        }
    }
    
    @MainActor required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    required init(textureAtlas: SKTextureAtlas, size: CGSize) {
        fatalError("init(textureAtlas:size:) has not been implemented")
    }
}
