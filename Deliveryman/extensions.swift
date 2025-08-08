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

extension UIColor {
    static var random: UIColor {
        return UIColor(
            red: .random(in: 0...1),
            green: .random(in: 0...1),
            blue: .random(in: 0...1),
            alpha: 1.0
        )
    }
}
