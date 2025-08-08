//
//  SKTexture.swift
//  Deliveryman
//
//  Created by Dmitriy Mitrofansky on 05.10.23.
//

import SpriteKit

extension SKTexture {
    var flippedHorizontally: SKTexture {
        let image = cgImage()
        let imageSize = CGSize(width: image.width, height: image.height)
        
        UIGraphicsBeginImageContextWithOptions(imageSize, false, 1)

        let context = UIGraphicsGetCurrentContext()!
        context.translateBy(x: .zero, y: imageSize.height)
        context.scaleBy(x: 1, y: -1)
        context.translateBy(x: imageSize.width, y: 0)
        context.scaleBy(x: -1, y: 1)
        context.draw(image, in: CGRect(origin: .zero, size: imageSize))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()!

        UIGraphicsEndImageContext()

        return SKTexture(image: newImage)
    }
}
