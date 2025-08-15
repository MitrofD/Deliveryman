//
//  MapProtocol.swift
//  Deliveryman
//
//  Created by Dmitriy Mitrofansky on 22.06.25.
//

import SpriteKit

protocol MapProtocol: SKNode {
    static var mapName: String { get }

    init (size: CGSize)
    
    func loadPreviewAssets(_ completion: @escaping (_ map: MapProtocol) -> Void)
    func loadAllAssets(_ completion: @escaping (_ map: MapProtocol) -> Void)

    func preview()
    func play()
}

extension MapProtocol {
    static var mapName: String {
        return String(describing: self) // Реализация по умолчанию
    }
}
