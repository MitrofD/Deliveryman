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
    let adjacentPathPoints: [MapGrid.Point]
    
    private var cellNodes: [SKNode] = []
    
    // MARK: - Initialization
    init(zone: MapGrid.Zone, cellSize: CGSize, pathSprites: [MapGrid.Point: SKNode], hasTarget: Bool = false) {
        self.zone = zone
        self.cellSize = cellSize
        self.hasTarget = hasTarget
        self.adjacentPathPoints =  Self.findAdjacentPathPoints(for: zone, from: pathSprites)
        
        super.init()
        setup()
        fill()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup Methods
    private func setup() {
        name = "SpringZone_\(zone.id.uuidString.prefix(8))"
        isUserInteractionEnabled = false
    }
    
    private func fill() {
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
    
    // MARK: - Static Helper Methods
    
    /// Находит прилегающие точки пути и соответствующие спрайты
    private static func findAdjacentPathPoints(
        for zone: MapGrid.Zone,
        from pathSprites: [MapGrid.Point: SKNode]
    ) -> [MapGrid.Point] {
        
        // Получаем граничные точки зоны
        let borderPoints = getBorderPoints(for: zone)
        var points: [MapGrid.Point] = []
        
        // Для каждой граничной точки находим соответствующую точку пути
        for borderPoint in borderPoints {
            let pathPoint = getPathPoint(for: borderPoint, zoneSide: zone.side)
            
            // Проверяем, есть ли спрайт для этой точки пути
            if pathSprites[pathPoint] != nil {
                points.append(pathPoint)
            }
        }
        
        return points
    }
    
    /// Получает граничные точки зоны
    private static func getBorderPoints(for zone: MapGrid.Zone) -> [MapGrid.Point] {
        var borderPoints: [MapGrid.Point] = []
        
        // Группируем ячейки по строкам
        let cellsByRow = Dictionary(grouping: zone.cells) { $0.point.row }
        
        switch zone.side {
        case .left:
            for (row, cellsInRow) in cellsByRow {
                let columns = cellsInRow.map { $0.point.column }
                borderPoints.append(MapGrid.Point(row: row, column: columns.max() ?? .zero))
            }
        case .right:
            for (row, cellsInRow) in cellsByRow {
                let columns = cellsInRow.map { $0.point.column }
                borderPoints.append(MapGrid.Point(row: row, column: columns.min() ?? .zero))
            }
        }
        
        return borderPoints.sorted { $0.row < $1.row }
    }
    
    /// Получает точку пути для граничной точки зоны
    private static func getPathPoint(for borderPoint: MapGrid.Point, zoneSide: MapGrid.Side) -> MapGrid.Point {
        let pathColumn: Int
        
        switch zoneSide {
        case .left:
            // Для левой зоны путь находится на 1 колонку правее
            pathColumn = borderPoint.column + 1
        case .right:
            // Для правой зоны путь находится на 1 колонку левее
            pathColumn = borderPoint.column - 1
        }
        
        return MapGrid.Point(row: borderPoint.row, column: pathColumn)
    }
}
