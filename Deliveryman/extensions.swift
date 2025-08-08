//
//  extensions.swift
//  Deliveryman
//
//  Created by Dmitriy Mitrofansky on 03.12.22.
//

import SpriteKit

extension SKNode {
    func flipHorizontally() {
        let absScale = abs(xScale)
        xScale = isFlippedHorizontally ? absScale : -absScale
    }
    
    var isFlippedHorizontally: Bool {
        return xScale < 0
    }
}
