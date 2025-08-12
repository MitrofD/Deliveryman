//
//  SpringMap.swift
//  Deliveryman
//
//  Created by Dmitriy Mitrofansky on 04.08.25.
//
import SpriteKit

class SpringMap: MapGrid, MapProtocol {
    // MARK: - PathItem Structure
    struct PathItem {
        let step: MapGrid.Step
        let node: SKNode
    }
    
    // MARK: - Properties
    private var tileSprites: [Point: SKNode] = [:]
    private var pathItems: [Point: PathItem] = [:]  // Храним и step, и node
    private var zones: [UUID: SpringZone] = [:]
    
    required init(size: CGSize) {
        super.init(size: size, cellSize: .zero)
    }
    
    @MainActor required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
    
    private func willResetedOrBuilt() {
        // Clean path items
        pathItems.values.forEach { pathItem in
            pathItem.node.removeFromParent()
        }
        pathItems.removeAll()
        
        // Clean ground
        tileSprites.values.forEach { node in
            node.removeFromParent()
        }
        tileSprites.removeAll()
        
        // Clean zones
        zones.values.forEach { springZone in
            springZone.removeFromParent()
        }
        zones.removeAll()
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
        moveByStep(duration: 0.1)
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
        let pathItem = PathItem(step: step, node: node)
        
        gridNode.addChild(node)
        pathItems[step.point] = pathItem
    }
    
    override func didRemoveStep(_ step: Step) {
        super.didRemoveStep(step)
        
        if let pathItem = pathItems[step.point] {
            pathItem.node.removeFromParent()
            pathItems.removeValue(forKey: step.point)
        }
    }
    
    override func didAppendZone(_ zone: Zone) {
        super.didAppendZone(zone)

        let springZone = SpringZone(zone: zone, cellSize: cellSize, pathItems: pathItems)
        gridNode.addChild(springZone)
        zones[zone.id] = springZone
    }
    
    override func willRemoveZone(_ zone: MapGrid.Zone) {
        super.willRemoveZone(zone)
    }
        
    override func didRemoveZone(_ zone: Zone) {
        super.didRemoveZone(zone)

        if let springZone = zones[zone.id] {
            springZone.removeFromParent()
            zones.removeValue(forKey: zone.id)
        }
    }
}
