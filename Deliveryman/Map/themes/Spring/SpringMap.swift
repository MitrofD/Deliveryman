//
//  SpringMap.swift
//  Deliveryman
//
//  Created by Dmitriy Mitrofansky on 04.08.25.
//

import SpriteKit

class SpringMap: MapGrid, MapProtocol {
    private var tileSprites: [Point: SKNode] = [:]
    private var pathSprites: [Point: SKNode] = [:]
    private var zoneSprites: [UUID: [SKNode]] = [:]
    
    required init(size: CGSize) {
        super.init(size: size, cellSize: .zero)
    }
    
    @MainActor required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    required init(textureAtlas: SKTextureAtlas, size: CGSize) {
        fatalError("init(textureAtlas:size:) has not been implemented")
    }
    
    required init(textureAtlas: SKTextureAtlas, size: CGSize, cellSize: CGSize) {
        fatalError("init(textureAtlas:size:cellSize:) has not been implemented")
    }
    
    private func tileNodeForCell(_ cell: Cell) -> SKNode {
        let texture = AtlasManager.shared.texture(named: "base", atlas: "Tiles", key: Self.themeName)
        let node = SKSpriteNode(texture: texture, size: cellSize)
        node.position = cell.position
        node.zPosition = CGFloat(cell.point.row)
        return node
    }
    
    private func pathNodeForStep(_ step: MapGrid.Step) -> SKNode {
        let pathName = step.isTurn
            ? "turn_\(step.side.opposite.rawValue)"
            : step.side.rawValue
        
        let texture = AtlasManager.shared.texture(named: pathName, atlas: "Paths", key: Self.themeName)
        let node = SKSpriteNode(texture: texture, size: cellSize)
        node.position = step.position
        node.zPosition = CGFloat(step.point.row + 1)

        return node
    }
    
    private func zoneNodeForCell(_ cell: Cell, area: Zone, color: UIColor) -> SKNode {
        let node = SKShapeNode(circleOfRadius: cellSize.height / 2 / 2)
        node.position = cell.position
        node.strokeColor = .black
        node.lineWidth = .zero
        node.zPosition = CGFloat(cell.point.row + 1)
        node.fillColor = color
        return node
    }
    
    private func willResetedOrBuilt() {
        // Clean path
        pathSprites.values.forEach { node in
            node.removeFromParent()
        }

        pathSprites.removeAll()
        
        // Clean ground
        tileSprites.values.forEach { node in
            node.removeFromParent()
        }

        tileSprites.removeAll()
        
        // Clean areas
        zoneSprites.values.forEach { nodes in
            nodes.forEach { $0.removeFromParent() }
        }

        zoneSprites.removeAll()
    }
    
    // MARK: - MapProtocol
    func loadPreviewAssets(_ completion: @escaping (any MapProtocol) -> Void) {
        AtlasManager.shared.loadAtlases(for: Self.themeName, atlasNames: ["Tiles", "Paths"]) { [weak self] _ in
            guard let self = self else { return }

            let texture = AtlasManager.shared.texture(named: "base", atlas: "Tiles", key: Self.themeName)
            let cellTextureSize = texture.size()
            let cellWidth = size.width / (CGFloat(5))
            let cellHeigth = cellWidth * (cellTextureSize.height / cellTextureSize.width)
            self.cellSize = CGSize(width: cellWidth, height: cellHeigth)
            completion(self)
        }
    }
    
    func loadAllAssets(_ callback: @escaping (any MapProtocol) -> Void) {
        
    }

    func preview() {
        build()
    }
    
    func play() {
        moveByStep(duration: 0.2)
    }
    
    // MARK: - Overrides
    override func willBuilt() {
        super.willBuilt()
        willResetedOrBuilt()
    }
    
    override func willResetted() {
        super.willResetted()
        willResetedOrBuilt()
    }
    
    override func didAppendRow(_ row: Int, cellsOfRow: [Grid.Cell]) {
        super.didAppendRow(row, cellsOfRow: cellsOfRow)
    
        cellsOfRow.forEach { cell in
            let node = tileNodeForCell(cell)
            tileSprites[cell.point] = node
            gridNode.addChild(node)
        }
    }
    
    override func didRemoveRow(_ row: Int, cellsOfRow: [Grid.Cell]) {
        super.didRemoveRow(row, cellsOfRow: cellsOfRow)
        
        cellsOfRow.forEach { cell in
            if let node = tileSprites[cell.point] {
                node.removeFromParent()
                tileSprites.removeValue(forKey: cell.point)
            }
        }
    }
    
    override func didAppendStep(_ step: Step) {
        super.didAppendStep(step)
        let node = pathNodeForStep(step)
        gridNode.addChild(node)
        pathSprites[step.point] = node
    }
    
    override func didRemoveStep(_ step: Step) {
        super.didRemoveStep(step)
        pathSprites[step.point]?.removeFromParent()
        pathSprites.removeValue(forKey: step.point)
    }
    
    override func didAppendZone(_ zone: Zone) {
        super.didAppendZone(zone)
        var nodes: [SKNode] = []
        let color = UIColor.random

        for cell in zone.cells {
            let node = zoneNodeForCell(cell, area: zone, color: color)
            gridNode.addChild(node)
            nodes.append(node)
        }
        
        zoneSprites[zone.id] = nodes
    }
        
    override func didRemoveZone(_ zone: Zone) {
        super.didRemoveZone(zone)
        
        if let nodes = zoneSprites[zone.id] {
            nodes.forEach { $0.removeFromParent()}
            zoneSprites.removeValue(forKey: zone.id)
        }
    }
}
