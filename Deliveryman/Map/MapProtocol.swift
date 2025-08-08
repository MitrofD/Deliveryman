//
//  MapProtocol.swift
//  Deliveryman
//
//  Created by Dmitriy Mitrofansky on 22.06.25.
//

import SpriteKit

protocol MapProtocol {
    init (size: CGSize, onReady: @escaping (_ map: MapProtocol) -> Void)
    
    func present()
    func start()
}
