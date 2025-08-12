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
    private let pathItems: [MapGrid.Point: SpringMap.PathItem]
    private let adjacentAfterPathPoints: [MapGrid.Point]
    private let adjacentTurnPathPoints: MapGrid.Point?
    private let adjacentBeforePathPoints: [MapGrid.Point]
    
    private var cellNodes: [SKNode] = []
    
    // MARK: - Initialization
    init(zone: MapGrid.Zone, cellSize: CGSize, pathItems: [MapGrid.Point: SpringMap.PathItem], hasTarget: Bool = false) {
        self.zone = zone
        self.cellSize = cellSize
        self.hasTarget = hasTarget
        self.pathItems = pathItems
        
        let splitPathPoints =  Self.findAdjacentPathPoints(for: zone, from: pathItems)
        self.adjacentAfterPathPoints = splitPathPoints.afterPoints
        self.adjacentTurnPathPoints = splitPathPoints.turnPoint
        self.adjacentBeforePathPoints = splitPathPoints.beforePoints
        
        super.init()
        setup()
        fill()
        
        print("\(adjacentAfterPathPoints) \(adjacentTurnPathPoints) \(adjacentBeforePathPoints)")
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
        from pathItems: [MapGrid.Point: SpringMap.PathItem]
    ) -> (afterPoints: [MapGrid.Point], turnPoint: MapGrid.Point?, beforePoints: [MapGrid.Point]) {
        var afterPoints: [MapGrid.Point] = []
        var beforePoints: [MapGrid.Point] = []
        var turnPoint: MapGrid.Point?
        
        // Получаем граничные точки зоны
        var borderPoints = getBorderPoints(for: zone)
        borderPoints.removeFirst()
        
        // Для каждой граничной точки находим соответствующую точку пути
        for borderPoint in borderPoints {
            let pathPoint = getPathPoint(for: borderPoint, zoneSide: zone.side)
            
            // Проверяем, есть ли спрайт для этой точки пути
            if let pathItem = pathItems[pathPoint] {
                if pathItem.step.isTurn {
                    turnPoint = pathPoint
                } else if (turnPoint != nil) {
                    beforePoints.append(pathPoint)
                } else {
                    afterPoints.append(pathPoint)
                }
            }
        }
        
        return (afterPoints: afterPoints, turnPoint: turnPoint, beforePoints: beforePoints)
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
        
        return borderPoints.sorted { $0.row > $1.row }
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
