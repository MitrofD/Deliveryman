//
//  CGSize.swift
//  Deliveryman
//
//  Created by Dmitriy Mitrofansky on 12.10.23.
//

import CoreGraphics

extension CGSize {
    var half: CGSize {
        return CGSize(width: width * 0.5, height: height * 0.5)
    }
}
