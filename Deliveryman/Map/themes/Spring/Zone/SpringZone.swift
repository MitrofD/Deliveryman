//
//  SpringZone.swift
//  Deliveryman
//
//  Created by Dmitriy Mitrofansky on 12.08.25.
//

import SpriteKit

class SpringZone {
    // MARK: - Properties
    let zone: MapGrid.Zone
    let hasTarget: Bool

    private weak var map: SpringMap?
    private let adjacentAfterPathSteps: [MapGrid.Step]
    private let adjacentTurnPathStep: MapGrid.Step?
    private let adjacentBeforePathSteps: [MapGrid.Step]
    
    // MARK: - Initialization
    init(zone: MapGrid.Zone, using map: SpringMap, hasTarget: Bool = false) {
        self.zone = zone
        self.hasTarget = hasTarget
        self.map = map
        
        let splitPathSteps = Self.findAdjacentPathSteps(for: zone, using: map)
        self.adjacentAfterPathSteps = splitPathSteps.afterSteps
        self.adjacentTurnPathStep = splitPathSteps.turnStep
        self.adjacentBeforePathSteps = splitPathSteps.beforeSteps
        fill()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup Methods
    
    private func stepSprite(named name: String, cellSize: CGSize) -> SKNode {
        let texture = AtlasManager.shared.texture(named: name, atlas: "Paths", key: SpringMap.themeName)
        let node = SKSpriteNode(texture: texture, size: cellSize)
        node.name = name
        node.position = .zero
        node.zPosition = 1

        return node
    }
    
    private func fillPath(map: SpringMap) {
        if let turnStep = adjacentTurnPathStep {
            let stepName = PathType(step: turnStep)
            let sprite = stepSprite(named: stepName.rawValue, cellSize: map.cellSize)
            map.tileNode(at: turnStep.point)?.addChild(sprite)
        }
        
        if adjacentAfterPathSteps.count > .zero {
            let lastIndex = adjacentAfterPathSteps.count - 1
            var beforeBranch: PathType = .branchBeforeLeft
            var afterBranch: PathType = .branchAfterRight
            
            if zone.side == .right {
                beforeBranch = .branchBeforeRight
                afterBranch = .branchAfterLeft
            }
            
            var prevBranchType: PathType?
            
            for (index, step) in adjacentAfterPathSteps.enumerated()  {
                // Проверяем условия для ответвления
                if shouldAddBranch(at: index, step: step) && prevBranchType == nil {
                    var pathType: PathType?

                    if index == .zero {
                        pathType = beforeBranch
                    } else if index == lastIndex {
                        if prevBranchType != afterBranch {
                            pathType = afterBranch
                        }
                    } else if let unwrappedPrevBranchType = prevBranchType {
                        pathType = unwrappedPrevBranchType == beforeBranch ? afterBranch : beforeBranch
                    } else {
                        pathType = [beforeBranch, afterBranch].randomElement()!
                    }
                    
                    if let unwrappedPathType = pathType {
                        prevBranchType = unwrappedPathType
                        let sprite = stepSprite(named: unwrappedPathType.rawValue, cellSize: map.cellSize)
                        map.tileNode(at: step.point)?.addChild(sprite)
                        continue
                    }
                }
                
                prevBranchType = nil
                let sprite = stepSprite(named: PathType(step: step).rawValue, cellSize: map.cellSize)
                map.tileNode(at: step.point)?.addChild(sprite)
            }
        }
    }
    
    private func shouldAddBranch(at index: Int, step: MapGrid.Step) -> Bool {
        // guard index >= 1 && index < adjacentAfterPathSteps.count - 1 else { return false }
        
        // Случайность (30% шанс)
        let branchProbability: Float = 0.3
        return Float.random(in: 0...1) <= branchProbability
    }

    private func fill() {
        guard let map = map else {
            return
        }
        
        fillPath(map: map)

        let color = UIColor.random
        
        for cell in zone.cells {
            let node = createNode(at: cell.point, size: map.cellSize, color: color)
            map.tileNode(at: cell.point)?.addChild(node)
        }
    }
    
    private func createNode(at point: MapGrid.Point, size: CGSize, color: UIColor) -> SKNode {
        let node = SKShapeNode(circleOfRadius: size.height / 2 / 2)
        node.position = .zero
        node.strokeColor = .black
        node.lineWidth = .zero
        node.zPosition = CGFloat(point.row + 1)
        node.fillColor = color
        
        return node
    }
    
    // MARK: - Static Helper Methods
    
    /// Находит прилегающие шаги пути
    private static func findAdjacentPathSteps(
        for zone: MapGrid.Zone,
        using map: SpringMap,
    ) -> (afterSteps: [MapGrid.Step], turnStep: MapGrid.Step?, beforeSteps: [MapGrid.Step]) {
        var afterSteps: [MapGrid.Step] = []
        var beforeSteps: [MapGrid.Step] = []
        var turnStep: MapGrid.Step?
        
        // Получаем граничные точки зоны
        var borderPoints = getBorderPoints(for: zone)
        
        if let firstPoint = borderPoints.first, let firstStep = map.step(at: getPathPoint(for: firstPoint, zoneSide: zone.side)), firstStep.isTurn {
            borderPoints.removeFirst()
        }
        
        // Для каждой граничной точки находим соответствующий шаг пути
        for borderPoint in borderPoints {
            let pathPoint = getPathPoint(for: borderPoint, zoneSide: zone.side)
            
            // Ищем шаг по точке среди всех шагов
            if let step = map.step(at: pathPoint) {
                if step.isTurn {
                    turnStep = step
                } else if (turnStep != nil) {
                    beforeSteps.append(step)
                } else {
                    afterSteps.append(step)
                }
            }
        }
        
        return (afterSteps: afterSteps, turnStep: turnStep, beforeSteps: beforeSteps)
    }
    
    /// Получает граничные точки зоны
    private static func getBorderPoints(for zone: MapGrid.Zone) -> [MapGrid.Point] {
        var borderPoints: [MapGrid.Point] = []
        borderPoints.reserveCapacity(zone.endRow - zone.startRow + 1)
        var cellsByRow: [Int: [Int]] = [:]

        for cell in zone.cells {
            if cellsByRow[cell.point.row] == nil {
                cellsByRow[cell.point.row] = []
            }

            cellsByRow[cell.point.row]!.append(cell.point.column)
        }

        for (row, columns) in cellsByRow {
            if let targetColumn = (zone.side == .left ? columns.max() : columns.min()) {
                borderPoints.append(MapGrid.Point(row: row, column: targetColumn))
            }
        }
        
        return borderPoints.sorted { $0.row > $1.row }
    }
    
    /// Получает точку пути для граничной точки зоны
    private static func getPathPoint(for borderPoint: MapGrid.Point, zoneSide: MapGrid.Side) -> MapGrid.Point {
        var pathColumn: Int
        
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
