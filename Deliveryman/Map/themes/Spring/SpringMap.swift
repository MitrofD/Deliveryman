//
//  SpringMap.swift
//  Deliveryman
//
//  Created by Dmitriy Mitrofansky on 04.08.25.
//
import SpriteKit

class SpringMap: MapGrid, MapProtocol {
    // MARK: - Properties
    private(set) var tileNodes: [Point: SKNode] = [:]
    private(set) var pathNodes: [Step: SKNode] = [:]
    private(set) var zoneNodes: [Zone: SpringZone] = [:]
    
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
        node.position = .zero
        node.zPosition = CGFloat(step.point.row + 1)

        return node
    }
    
    private func willResetedOrBuilt() {
        // Clean tiles
        tileNodes.values.forEach { node in
            node.removeFromParent()
        }

        tileNodes.removeAll()
    
        // Clean path nodes
        pathNodes.removeAll()
        
        // Clean zones
        zoneNodes.removeAll()
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
        cellsOfRow.forEach { cell in
            let node = tileNodeForCell(cell)
            tileNodes[cell.point] = node
            gridNode.addChild(node)
        }
        
        super.didAppendRow(row, cellsOfRow: cellsOfRow)
    }
    
    override func didRemoveRow(_ row: Int, cellsOfRow: [Grid.Cell]) {
        super.didRemoveRow(row, cellsOfRow: cellsOfRow)
        
        cellsOfRow.forEach { cell in
            if let node = tileNodes[cell.point] {
                node.removeFromParent()
                tileNodes.removeValue(forKey: cell.point)
            }
        }
    }
    
    override func didAppendStep(_ step: Step) {
        super.didAppendStep(step)

        let node = pathNodeForStep(step)
        pathNodes[step] = node
        tileNode(at: step.point)?.addChild(node)
    }
    
    override func didRemoveStep(_ step: Step) {
        super.didRemoveStep(step)
        pathNodes.removeValue(forKey: step)
    }
    
    override func didAppendZone(_ zone: Zone) {
        super.didAppendZone(zone)
        zoneNodes[zone] = SpringZone(zone: zone, using: self)
    }
    
    override func willRemoveZone(_ zone: MapGrid.Zone) {
        super.willRemoveZone(zone)
    }
        
    override func didRemoveZone(_ zone: Zone) {
        super.didRemoveZone(zone)
        zoneNodes.removeValue(forKey: zone)
    }
    
    func tileNode(at point: MapGrid.Point) -> SKNode? {
        return tileNodes[point]
    }
}
