//
//  TestMap.swift
//  Deliveryman
//
//  Created by Dmitriy Mitrofansky on 14.08.25.
//

import SpriteKit

class TestMap: Grid {
    var nodes = [Point: SKShapeNode]()

    override func didAppendRow(_ row: Int, cellsOfRow: [Grid.Cell]) {
        super.didAppendRow(row, cellsOfRow: cellsOfRow)
        
        let color = UIColor.random
        
        for cell in cellsOfRow {
            let node = createNode(at: cell.position, size: cellSize, color: color)
            let labelNode = SKLabelNode(text: "\(cell.point)")
            labelNode.fontSize = 10
            labelNode.fontName = "Helvetica-Bold"
            node.addChild(labelNode)
            nodes[cell.point] = node
            gridNode.addChild(node)
        }
    }
    
    override func didRemoveCell(_ cell: Grid.Cell) {
        // print("\(cell)")
        guard let node = nodes[cell.point] else { return }
        
        node.removeFromParent()
        nodes.removeValue(forKey: cell.point)
    }
    
    override func didRemoveRow(_ row: Int, cellsOfRow: [Grid.Cell]) {
        print("didRemoveRow \(cellsOfRow.map { $0.point })")
    }
    
    override func didBuilt() {
        
        let point = Point(row: 9, column: 3)
        
        guard let shapeCell = westCell(for: point) else { return }
        
        guard let shape = nodes[shapeCell.point] else { return }
        
        shape.fillColor = .red
        
        /*
        guard let neighborCell = northWestCell(for: cell) else { return }
        
        guard let neighborShape = nodes[neighborCell.point] else { return }
        
        neighborShape.fillColor = .blue
        */
    }
    
    private func createNode(at point: CGPoint, size: CGSize, color: UIColor) -> SKShapeNode {
        let node = SKShapeNode(rectOf: size)
        node.position = .zero
        node.strokeColor = .black
        node.position = point
        node.zPosition = 1
        node.fillColor = color
        
        return node
    }
}
