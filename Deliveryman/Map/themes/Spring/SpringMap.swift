//
//  SpringMap.swift
//  Deliveryman
//
//  Created by Dmitriy Mitrofansky on 04.08.25.
//

import SpriteKit

class SpringMap: MapGrid, MapProtocol {
    class TileNode: SKSpriteNode {
        func clear() {
            children.forEach { $0.isHidden = true }
        }
    }

    // MARK: - Properties
    private var tileNodes = [Point: TileNode]()
    private var mapZonesByZone = [Zone: SpringZone]()
    private var cachedEvenTileNodes = [Int: TileNode]()
    private var cachedOddTileNodes = [Int: TileNode]()
    
    required init(size: CGSize) {
        super.init(size: size, cellSize: .zero)
    }
    
    @MainActor required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func tileNodeForCell(_ cell: Cell) -> TileNode {
        let texture = AtlasManager.shared.texture(named: "base", atlas: "Tiles", key: Self.mapName)
        return TileNode(texture: texture, size: cellSize)
    }
    
    // MARK: - MapProtocol
    func loadPreviewAssets(_ completion: @escaping (any MapProtocol) -> Void) {
        AtlasManager.shared.loadAtlases(for: Self.mapName, atlasNames: ["Tiles", "Paths"]) { [weak self] _ in
            guard let self = self else {
                return
            }

            let texture = AtlasManager.shared.texture(named: "base", atlas: "Tiles", key: Self.mapName)
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
        moveByStep(duration: 0.09)
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
    
    private func resetCache() {
        cachedEvenTileNodes.removeAll()
        cachedOddTileNodes.removeAll()
    }
    
    private func willResetedOrBuilt() {
        // Clean tiles
        tileNodes.values.forEach { node in
            node.removeFromParent()
        }

        tileNodes.removeAll()
        mapZonesByZone.removeAll()
        
        resetCache()
    }
    
    override func didAppendRow(_ row: Int, cellsOfRow: [Grid.Cell]) {
        let cachedTileSprites = isEvenRow(row) ? cachedEvenTileNodes : cachedOddTileNodes

        cellsOfRow.forEach { cell in
            let tileNode: TileNode

            if let cachedTileNode = cachedTileSprites[cell.point.column] {
                cachedTileNode.clear()
                tileNode = cachedTileNode
            } else {
                tileNode = tileNodeForCell(cell)
                gridNode.addChild(tileNode)
            }
            
            tileNode.position = cell.position
            tileNode.zPosition = CGFloat(row)
            /*
            let labelNode = SKLabelNode(text: "\(cell.point)")
            labelNode.fontSize = 10
            labelNode.fontName = "Helvetica-Bold"
            labelNode.zPosition = 100
            node.addChild(labelNode)
            */
            tileNodes[cell.point] = tileNode
        }
        
        super.didAppendRow(row, cellsOfRow: cellsOfRow)
    }
    
    override func didRemoveRow(_ row: Int, cellsOfRow: [Grid.Cell]) {
        super.didRemoveRow(row, cellsOfRow: cellsOfRow)
        var cachedTileSprites = [Int: TileNode]()
        
        cellsOfRow.forEach { cell in
            if let node = tileNodes[cell.point] {
                cachedTileSprites[cell.point.column] = node
                tileNodes.removeValue(forKey: cell.point)
            }
        }
        
        if isEvenRow(row) {
            cachedEvenTileNodes = cachedTileSprites
        } else {
            cachedOddTileNodes = cachedTileSprites
        }
    }
    
    override func didAppendZone(_ zone: Zone) {
        super.didAppendZone(zone)
        mapZonesByZone[zone] = SpringZone(zone: zone, using: self)
    }

    override func didRemoveZone(_ zone: Zone) {
        super.didRemoveZone(zone)
        mapZonesByZone.removeValue(forKey: zone)
    }
    
    func tileNode(at point: MapGrid.Point) -> SKNode? {
        return tileNodes[point]
    }
}
