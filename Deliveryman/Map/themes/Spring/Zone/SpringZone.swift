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

    private let map: SpringMap
    private let adjacentAfterSteps: [MapGrid.Step]
    private let adjacentTurnStep: MapGrid.Step?
    private let adjacentBeforeSteps: [MapGrid.Step]
    
    // MARK: - Initialization
    init(zone: MapGrid.Zone, using map: SpringMap, hasTarget: Bool = false) {
        self.zone = zone
        self.hasTarget = hasTarget
        self.map = map
        
        let splitPathSteps = Self.findAdjacentPathSteps(for: zone, using: map)
        self.adjacentAfterSteps = splitPathSteps.afterSteps
        self.adjacentTurnStep = splitPathSteps.turnStep
        self.adjacentBeforeSteps = splitPathSteps.beforeSteps
        fill()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup Methods
    
    private func stepSprite(variant: MapGrid.Step.Variant, cellSize: CGSize) -> SKNode {
        let node: SKNode
    
        if let cachedNode = NodesPool.shared.get(key: SpringMap.mapName, ofType: variant.rawValue) {
            node = cachedNode
        } else {
            print("Create \(variant.rawValue)")
            let texture = AtlasManager.shared.texture(named: variant.rawValue, atlas: "Paths", key: SpringMap.mapName)
            node = SKSpriteNode(texture: texture, size: cellSize)
            node.name = variant.rawValue
            NodesPool.shared.set(key: SpringMap.mapName, ofType: variant.rawValue, node: node)
        }

        node.position = .zero
        node.zPosition = 2

        return node
    }
    
    private func fillPath() {
        if let turnStep = adjacentTurnStep {
            let sprite = stepSprite(variant: turnStep.variant, cellSize: map.cellSize)
            map.tileNode(at: turnStep.cell.point)?.addChild(sprite)
        }
        
        if adjacentAfterSteps.count > .zero {
            let lastIndex = adjacentAfterSteps.count - 1
            var beforeBranchVariant: MapGrid.Step.Variant = .branchBeforeLeft
            var afterBranchVariant: MapGrid.Step.Variant = .branchAfterRight
            
            if zone.side == .right {
                beforeBranchVariant = .branchBeforeRight
                afterBranchVariant = .branchAfterLeft
            }
            
            var prevBranchVariant: MapGrid.Step.Variant?
            
            for (index, step) in adjacentAfterSteps.enumerated()  {
                // Проверяем условия для ответвления
                if let branch = getBranch(
                    at: index,
                    lastIndex: lastIndex,
                    step: step,
                    beforeBranchVariant: beforeBranchVariant,
                    afterBranchVariant: afterBranchVariant,
                    prevBranchVariant: prevBranchVariant
                ) {
                    prevBranchVariant = branch.startBranchVariant
                    step.variant = branch.startBranchVariant
                    
                    for step in branch.steps {
                        let sprite = stepSprite(variant: step.variant, cellSize: map.cellSize)
                        map.tileNode(at: step.cell.point)?.addChild(sprite)
                    }

                    continue
                }
                
                prevBranchVariant = nil
                let sprite = stepSprite(variant: step.variant, cellSize: map.cellSize)
                map.tileNode(at: step.cell.point)?.addChild(sprite)
            }
        }
    }
    
    private func getBranchSteps(
        for step: MapGrid.Step,
        startBranchVariant: MapGrid.Step.Variant
    ) -> [MapGrid.Step]? {
        var endStep: MapGrid.Step?
        
        switch startBranchVariant {
        case .branchAfterLeft:
            if let cell = map.getNorthWestCell(for: step.cell.point) {
                endStep = MapGrid.Step(cell: cell, variant: .branchAfterLeftEnd)
            }
            
        case .branchBeforeLeft:
            if let cell = map.getSouthWestCell(for: step.cell.point) {
                endStep = MapGrid.Step(cell: cell, variant: .branchBeforeLeftEnd)
            }
            
        case .branchAfterRight:
            if let cell = map.getNorthEastCell(for: step.cell.point) {
                endStep = MapGrid.Step(cell: cell, variant: .branchAfterRightEnd)
            }
            
        case .branchBeforeRight:
            if let cell = map.getSouthEastCell(for: step.cell.point) {
                endStep = MapGrid.Step(cell: cell, variant: .branchBeforeRightEnd)
            }

        default: break
        }
        
        guard let unwrappedEndStep = endStep else { return nil }
        
        let startStep = MapGrid.Step(cell: step.cell, variant: startBranchVariant)
        unwrappedEndStep.prev = startStep

        return [startStep, unwrappedEndStep]
    }
    
    private func getBranch(
        at index: Int,
        lastIndex: Int,
        step: MapGrid.Step,
        beforeBranchVariant: MapGrid.Step.Variant,
        afterBranchVariant: MapGrid.Step.Variant,
        prevBranchVariant: MapGrid.Step.Variant?
    ) -> (startBranchVariant: MapGrid.Step.Variant, steps: [MapGrid.Step])? {
        guard lastIndex > .zero, prevBranchVariant == nil else { return nil }
        
        // Случайность (30% шанс)
        let branchProbability = Float(0.3)
    
        guard Float.random(in: 0...1) <= branchProbability else {
            return nil
        }
        
        var startBranchVariant: MapGrid.Step.Variant?

        if index == .zero {
            startBranchVariant = beforeBranchVariant
        } else if index == lastIndex {
            if prevBranchVariant != afterBranchVariant {
                startBranchVariant = afterBranchVariant
            }
        } else if let branchVariant = prevBranchVariant {
            startBranchVariant = branchVariant == beforeBranchVariant ? afterBranchVariant : beforeBranchVariant
        } else {
            startBranchVariant = [beforeBranchVariant, afterBranchVariant].randomElement()!
        }
        
        guard let unwrappedStartBranchVariant = startBranchVariant, let branchSteps = getBranchSteps(for: step, startBranchVariant: unwrappedStartBranchVariant) else {
            return nil
        }
        
        return (startBranchVariant: unwrappedStartBranchVariant, steps: branchSteps)
    }

    private func fill() {
        fillPath()
        /*
        let color = UIColor.random
        
        for cell in zone.cells {
            let node = createNode(at: cell.point, size: map.cellSize, color: color)
            map.tileNode(at: cell.point)?.addChild(node)
        }
        */
    }
    
    private func createNode(at point: MapGrid.Point, size: CGSize, color: UIColor) -> SKNode {
        let node = SKShapeNode(circleOfRadius: size.height / 2 / 2)
        node.position = .zero
        node.strokeColor = .black
        node.lineWidth = .zero
        node.zPosition = 2
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
        
        if let firstPoint = borderPoints.first, let firstStep = map.step(at: getPathPoint(for: firstPoint, zoneSide: zone.side)), firstStep.variant.isTurn {
            borderPoints.removeFirst()
        }
        
        // Для каждой граничной точки находим соответствующий шаг пути
        for borderPoint in borderPoints {
            let stepPoint = getPathPoint(for: borderPoint, zoneSide: zone.side)
            
            // Ищем шаг по точке среди всех шагов
            if let step = map.step(at: stepPoint) {
                if step.variant.isTurn {
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
            pathColumn = borderPoint.column + 1
        case .right:
            pathColumn = borderPoint.column - 1
        }
        
        return MapGrid.Point(row: borderPoint.row, column: pathColumn)
    }
}
