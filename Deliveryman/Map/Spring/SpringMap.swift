//
//  SpringMap.swift
//  Deliveryman
//
//  Created by Dmitriy Mitrofansky on 04.08.25.
//

import SpriteKit

class SpringMap: IsometricPathGrid, MapProtocol {
    let groundNode: SKSpriteNode
    let leftPathNode: SKSpriteNode
    let leftPathTurnNode: SKSpriteNode
    let rightPathNode: SKSpriteNode
    let rightPathTurnNode: SKSpriteNode
    
    private var groundNodes: [Point: SKNode] = [:]
    private var pathNodes: [Point: SKNode] = [:]
    private var areaNodes: [UUID: [SKNode]] = [:]
    
    required init(size: CGSize, onReady: @escaping (_ map: MapProtocol) -> Void) {
        let textureAtlas = SKTextureAtlas(named: "map-spring")
        let cellTexture = textureAtlas.textureNamed("base")
        let cellTextureSize = cellTexture.size()
        let cellWidth = size.width / (CGFloat(5))
        let cellHeigth = cellWidth * (cellTextureSize.height / cellTextureSize.width)
        let cellSize = CGSize(width: cellWidth, height: cellHeigth)

        groundNode = SKSpriteNode(texture: cellTexture, size: cellSize)
        leftPathNode = SKSpriteNode(texture: textureAtlas.textureNamed("left-path"), size: cellSize)
        leftPathTurnNode = SKSpriteNode(texture: textureAtlas.textureNamed("left-path-turn"), size: cellSize)
        rightPathNode = SKSpriteNode(texture: textureAtlas.textureNamed("right-path"), size: cellSize)
        rightPathTurnNode = SKSpriteNode(texture: textureAtlas.textureNamed("right-path-turn"), size: cellSize)

        super.init(size: size, cellSize: cellSize)
        
        textureAtlas.preload { [weak self] in
            guard let self = self else { return }
            onReady(self)
        }
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
    
    private func groundNodeForCell(_ cell: Cell) -> SKNode {
        let nodeClone = groundNode.clone()
        nodeClone.position = cell.position
        nodeClone.zPosition = CGFloat(cell.point.row)
        return nodeClone
    }
    
    private func pathNodeForStep(_ step: IsometricPathGrid.Step) -> SKNode {
        var node: SKNode
        
        if step.isTurn {
            node = step.side == .right ? leftPathTurnNode : rightPathTurnNode
        } else {
            node = step.side == .left ? leftPathNode : rightPathNode
        }

        let nodeClone = node.clone()
        nodeClone.position = step.position
        nodeClone.zPosition = CGFloat(step.point.row + 1)

        return nodeClone
    }
    
    private func areaNodeForCell(_ cell: Cell, area: Area, color: UIColor) -> SKNode {
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
        pathNodes.values.forEach { node in
            node.removeFromParent()
        }
        pathNodes.removeAll()
        
        // Clean ground
        groundNodes.values.forEach { node in
            node.removeFromParent()
        }
        groundNodes.removeAll()
        
        // Clean areas
        areaNodes.values.forEach { nodes in
            nodes.forEach { $0.removeFromParent() }
        }
        areaNodes.removeAll()
    }
    
    // MARK: - MapProtocol
    func present() {
        build()
    }
    
    func start() {
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
            let node = groundNodeForCell(cell)
            groundNodes[cell.point] = node
            gridNode.addChild(node)
        }
    }
    
    override func didRemoveRow(_ row: Int, cellsOfRow: [Grid.Cell]) {
        super.didRemoveRow(row, cellsOfRow: cellsOfRow)
        
        cellsOfRow.forEach { cell in
            if let node = groundNodes[cell.point] {
                node.removeFromParent()
                groundNodes.removeValue(forKey: cell.point)
            }
        }
    }
    
    override func didAppendStep(_ step: Step) {
        super.didAppendStep(step)
        let node = pathNodeForStep(step)
        gridNode.addChild(node)
        pathNodes[step.point] = node
    }
    
    override func didRemoveStep(_ step: Step) {
        super.didRemoveStep(step)
        pathNodes[step.point]?.removeFromParent()
        pathNodes.removeValue(forKey: step.point)
    }
    
    override func didAppendArea(_ area: Area) {
        super.didAppendArea(area)
        var nodes: [SKNode] = []
        
        let color = UIColor.random

        for cell in area.cells {
            let node = areaNodeForCell(cell, area: area, color: color)
            gridNode.addChild(node)
            nodes.append(node)
        }
        
        areaNodes[area.id] = nodes
    }
        
    override func didRemoveArea(_ area: Area) {
        super.didRemoveArea(area)
        
        if let nodes = areaNodes[area.id] {
            nodes.forEach { $0.removeFromParent()}
            areaNodes.removeValue(forKey: area.id)
        }
    }
}
