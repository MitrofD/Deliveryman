//
//  SKNode.swift
//  Deliveryman
//
//  Created by Dmitriy Mitrofansky on 05.10.23.
//

import SpriteKit

extension SKNode {
    func hasParent(_ parentNode: SKNode) -> Bool {
        guard let parent = self.parent else {
            return false
        }

        return parent === parentNode ? true : parent.hasParent(parentNode)
    }
}

