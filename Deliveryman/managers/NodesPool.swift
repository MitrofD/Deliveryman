//
//  NodesPool.swift
//  Deliveryman
//
//  Created by Dmitriy Mitrofansky on 15.08.25.
//

import SpriteKit

class NodesPool {
    static let shared = NodesPool()

    private var pool: [String: [String: [SKNode]]] = [:]

    private init() {}

    func set(key: String, ofType type: String, node: SKNode) {
        if pool[key] == nil {
            pool[key] = [:]
        }
    
        if pool[key]![type] == nil {
            pool[key]![type] = []
        }

        pool[key]![type]!.append(node)
    }

    func get(key: String, ofType type: String) -> SKNode? {
        guard let nodes = pool[key]?[type] else { return nil }

        if let node = nodes.first(where: { $0.isHidden }) {
            if node.parent != nil {
                node.removeFromParent()
            }
        
            node.isHidden = false
            return node
        }

        return nil
    }

    func clear(key: String) {
        pool[key]?.forEach { (_, nodes) in
            nodes.forEach { $0.removeFromParent() }
        }

        pool[key] = nil
    }

    // Полная очистка
    func clearAll() {
        pool.forEach { (_, types) in
            types.forEach { (_, nodes) in
                nodes.forEach { $0.removeFromParent() }
            }
        }

        pool.removeAll()
    }
}
