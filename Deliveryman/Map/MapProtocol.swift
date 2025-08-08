//
//  MapProtocol.swift
//  Deliveryman
//
//  Created by Dmitriy Mitrofansky on 22.06.25.
//

import SpriteKit

protocol MapProtocol: IsometricPathGrid {
    var onReady: (_ map: MapProtocol) -> Void { get set }

    init(size: CGSize)
}
