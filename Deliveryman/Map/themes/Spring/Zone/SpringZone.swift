//
//  SpringZone.swift
//  Deliveryman
//
//  Created by Dmitriy Mitrofansky on 12.08.25.
//

import SpriteKit

class SpringZone: SKNode {
    // MARK: - Properties
    let zone: MapGrid.Zone
    let cellSize: CGSize
    let hasTarget: Bool
    
    private var cellNodes: [SKNode] = []
    
    // MARK: - Initialization
    init(zone: MapGrid.Zone, cellSize: CGSize, hasTarget: Bool = false) {
        self.zone = zone
        self.cellSize = cellSize
        self.hasTarget = hasTarget
        
        super.init()
        setup()
        fillCells()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup Methods
    private func setup() {
        name = "SpringZone_\(zone.id.uuidString.prefix(8))"
        isUserInteractionEnabled = false
    }
    
    private func fillCells() {
        cellNodes.removeAll()
        removeAllChildren()
        
        let color = UIColor.random
        
        for cell in zone.cells {
            let cellNode = createCellNode(for: cell, color: color)
            addChild(cellNode)
            cellNodes.append(cellNode)
        }
    }
    
    private func createCellNode(for cell: MapGrid.Cell, color: UIColor) -> SKNode {
        let node = SKShapeNode(circleOfRadius: cellSize.height / 2 / 2)
        node.position = cell.position
        node.strokeColor = .black
        node.lineWidth = .zero
        node.zPosition = CGFloat(cell.point.row + 1)
        node.fillColor = color
        
        return node
    }
}
