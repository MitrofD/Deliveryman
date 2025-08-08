//
//  TiledIsometricPathGrid.swift
//  Deliveryman
//
//  Created by Dmitriy Mitrofansky on 22.06.25.
//

import SpriteKit

class TiledIsometricPathGrid: IsometricPathGrid {
    private var groundNodes: [Point: SKNode] = [:]
    private var pathNodes: [Point: SKNode] = [:]
    
    override init(size: CGSize, cellSize: CGSize, indent: Grid.Indent = Indent(top: 1, right: .zero, bottom: .zero, left: .zero)) {
        super.init(size: size, cellSize: cellSize, indent: indent)
    }
    
    @MainActor required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func willBuilt() {
        super.willBuilt()
        willResetedOrBuilt()
    }
    
    override func willResetted() {
        super.willResetted()
        willResetedOrBuilt()
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
        pathNodes[step.point] = nil
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
                groundNodes[cell.point] = nil
            }
        }
    }

    func pathNodeForStep(_ step: Step) -> SKNode {
        let node = SKLabelNode(text: "[\(step.point.row), \(step.point.column)]")
        node.position = step.position
        node.fontColor = .blue
        node.fontSize = 10
        node.fontName = "SFPro-Black"
        
        return node
    }
    
    func groundNodeForCell(_ cell: Cell) -> SKNode {
        let node = SKShapeNode(rectOf: cellSize)
        node.position = cell.position
        node.fillColor = .green
        node.strokeColor = .black
        node.zPosition = -1

        return node
    }
}
