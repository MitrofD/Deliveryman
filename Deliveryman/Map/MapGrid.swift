//
//  MapGrid.swift
//  Deliveryman
//
//  Created by Dmitriy Mitrofansky on 29.09.24.
//

import SpriteKit

fileprivate func getIndentTop(size: CGSize, cellSize: CGSize) -> Int {
    let multiplicator = Int(-3)

    guard cellSize.width > .zero else {
        return multiplicator
    }

    return Int(ceil(size.width / cellSize.width)) * multiplicator
}

fileprivate func getCorrectIndentFromIndent(_ indent: Grid.Indent, size: CGSize, cellSize: CGSize) -> Grid.Indent {
    return Grid.Indent(top: indent.top + getIndentTop(size: size, cellSize: cellSize), right: indent.right, bottom: indent.bottom, left: indent.left)
}

class MapGrid: IsometricGrid {
    enum Side: String {
        case left
        case right
        
        static var random: Side {
            let directions = [Side.left, Side.right]
            return directions.randomElement()!
        }
        
        var opposite: Side {
            return self == .left ? .right : .left
        }
    }
    
    class Step: CustomStringConvertible {
        enum Variant: String, CaseIterable {
            // MARK: - Основные пути
            case straightLeft = "straight_left"
            case straightRight = "straight_right"
            
            // MARK: - Повороты
            case turnLeft = "turn_left"
            case turnRight = "turn_right"
            
            // MARK: - Ветки после поворота
            case branchAfterLeft = "branch_after_left"
            case branchAfterRight = "branch_after_right"
            case branchAfterLeftEnd = "branch_after_left_end"
            case branchAfterRightEnd = "branch_after_right_end"
            
            // MARK: - Ветки до поворота
            case branchBeforeLeft = "branch_before_left"
            case branchBeforeRight = "branch_before_right"
            case branchBeforeLeftEnd = "branch_before_left_end"
            case branchBeforeRightEnd = "branch_before_right_end"
            
            // MARK: - Computed Properties
            
            /// Сторона движения
            var side: MapGrid.Side {
                switch self {
                case .straightLeft, .turnLeft, .branchAfterLeft, .branchAfterLeftEnd, .branchBeforeLeft, .branchBeforeLeftEnd:
                    return .left
                case .straightRight, .turnRight, .branchAfterRight, .branchAfterRightEnd, .branchBeforeRight, .branchBeforeRightEnd:
                    return .right
                }
            }
            
            /// Является ли поворотом
            var isTurn: Bool {
                switch self {
                case .turnLeft, .turnRight:
                    return true
                default:
                    return false
                }
            }
            
            /// Является ли веткой (включая окончания)
            var isBranch: Bool {
                switch self {
                case .branchAfterLeft, .branchAfterRight, .branchAfterLeftEnd, .branchAfterRightEnd,
                     .branchBeforeLeft, .branchBeforeRight, .branchBeforeLeftEnd, .branchBeforeRightEnd:
                    return true
                default:
                    return false
                }
            }
            
            /// Является ли началом ветки
            var isBranchStart: Bool {
                switch self {
                case .branchAfterLeft, .branchAfterRight, .branchBeforeLeft, .branchBeforeRight:
                    return true
                default:
                    return false
                }
            }
            
            /// Является ли окончанием ветки
            var isBranchEnd: Bool {
                switch self {
                case .branchAfterLeftEnd, .branchAfterRightEnd, .branchBeforeLeftEnd, .branchBeforeRightEnd:
                    return true
                default:
                    return false
                }
            }
            
            /// Является ли прямым путем
            var isStraight: Bool {
                switch self {
                case .straightLeft, .straightRight:
                    return true
                default:
                    return false
                }
            }
            
            /// Относится ли к периоду "после поворота"
            var isAfterTurn: Bool {
                switch self {
                case .branchAfterLeft, .branchAfterRight, .branchAfterLeftEnd, .branchAfterRightEnd:
                    return true
                default:
                    return false
                }
            }
            
            /// Относится ли к периоду "до поворота"
            var isBeforeTurn: Bool {
                switch self {
                case .branchBeforeLeft, .branchBeforeRight, .branchBeforeLeftEnd, .branchBeforeRightEnd:
                    return true
                default:
                    return false
                }
            }
        }

        weak var next: Step?
        weak var prev: Step?
        private(set) var cell: Cell
        var variant: Variant

        init(cell: Cell, variant: Variant, prev: Step? = nil, next: Step? = nil) {
            self.cell = cell
            self.variant = variant
            self.next = next
            self.prev = prev
        }
        
        var description: String {
            return "Step(cell: \(cell.description), variant: \(variant))"
        }
    }
    
    class Zone: CustomStringConvertible, Hashable {
        let cells: [Cell]
        let side: Side
        let startRow: Int
        let endRow: Int
        
        init(cells: [Cell], side: Side, startRow: Int, endRow: Int) {
            self.cells = cells
            self.side = side
            self.startRow = startRow
            self.endRow = endRow
        }
        
        var description: String {
            return "Zone(side: \(side), rows: \(startRow)-\(endRow), cells: \(cells.count))"
        }
        
        var rowRange: ClosedRange<Int> {
            return startRow...endRow
        }
        
        func containsRow(_ row: Int) -> Bool {
            return rowRange.contains(row)
        }
        
        // MARK: - Hashable
        static func == (lhs: Zone, rhs: Zone) -> Bool {
            return lhs.startRow == rhs.startRow && lhs.side == rhs.side
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(startRow)
            hasher.combine(side)
        }
    }
    
    // For child overrides - existing methods
    func didAppendStep(_ step: Step) {}
    func didRemoveStep(_ step: Step) {}
    
    // Zone lifecycle methods
    func didAppendZone(_ zone: Zone) {}
    func willRemoveZone(_ zone: Zone) {}
    func didRemoveZone(_ zone: Zone) {}
    
    override var indent: Grid.Indent {
        get {
            return super.indent
        }
        
        set {
            baseIndent = newValue
            super.indent = getCorrectIndentFromIndent(newValue, size: size, cellSize: cellSize)
        }
    }
    
    override var cellSize: CGSize {
        didSet {
            super.indent = getCorrectIndentFromIndent(baseIndent, size: size, cellSize: cellSize)
        }
    }

    private(set) var steps = [Step]()
    private(set) var zones = [Zone]()
    private(set) var side = Side.left
    
    private var baseIndent: Indent
    private var stepsByPoint: [Point: Step] = [:]

    private var calcNextTurnPoint: () -> Void = { }
    private var centerColumn = Int.zero
    private var columnsRange = Range(uncheckedBounds: (lower: Int.zero, upper: Int.zero))
    private var prevStep: Step?
    private var stepPoint = Point.zero
    private var turnPoint = Point.zero
    
    // Area tracking
    private var currentZoneStartRow: Int = 0
    private var pendingLeftCells: [Int: [Cell]] = [:]  // row -> [cells]
    private var pendingRightCells: [Int: [Cell]] = [:] // row -> [cells]
    private var filledCells: Set<Point> = [] // Track which cells are already filled
    
    // Zone exit optimization - теперь используем Zone как ключ
    private var zonesStartedExiting: Set<Zone> = []
    private var zonesByStartRow: [Int: [Zone]] = [:]  // O(1) lookup by start row
    
    override init(size: CGSize, cellSize: CGSize, indent: Indent = Indent(top: 1, right: .zero, bottom: .zero, left: .zero)) {
        self.baseIndent = indent
        super.init(size: size, cellSize: cellSize, indent: getCorrectIndentFromIndent(indent, size: size, cellSize: cellSize))
    }
    
    required init?(coder aDecoder: NSCoder) {
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
        steps.removeAll()
        zones.removeAll()
        pendingLeftCells.removeAll()
        pendingRightCells.removeAll()
        filledCells.removeAll()
        zonesStartedExiting.removeAll()
        zonesByStartRow.removeAll()
        stepsByPoint.removeAll()
        prevStep = nil
        
        let maxColumns = max(columnsForRow(.zero), columnsForRow(1))
        centerColumn = maxColumns / 2
        columnsRange = .zero..<maxColumns
        calcNextTurnPoint = maxColumns.isMultiple(of: 2) ? evenCalcNextTurnPoint : oddCalcNextTurnPoint
        stepPoint.row = indent.bottom
        stepPoint.column = Int.random(in: indent.left..<maxColumns)
        side = stepPoint.column < centerColumn ? .right : .left
        currentZoneStartRow = stepPoint.row
        calcNextTurnPoint()
    }
    
    private func calcNextStep(forRow row: Int) {
        stepPoint.row += 1
        let isEvenRow = row.isMultiple(of: 2)
        
        if side == .left {
            if !isEvenRow {
                stepPoint.column -= 1
            }
        } else {
            if isEvenRow {
                stepPoint.column += 1
            }
        }
    }
    
    private func evenCalcNextTurnPoint() {
        var diff = abs(stepPoint.column - centerColumn)
        let count = columnsForRow(stepPoint.row)
        let isEvenCount = count.isMultiple(of: 2)
        var appendRows = Int.zero
        
        if isEvenCount {
            appendRows = diff * 2
        } else {
            if stepPoint.column >= centerColumn {
                diff += 1
            }
            
            if diff > .zero {
                appendRows = diff * 2 - 1
            }
        }
        
        let additionalRows = Int.random(in: columnsRange)
        let newRows = stepPoint.row + appendRows + additionalRows
        var newColumn = centerColumn
        
        if additionalRows > .zero {
            let newRowsIsEven = newRows.isMultiple(of: 2)
            let halfColumn = additionalRows / 2

            if side == .right {
                newColumn += halfColumn
                
               
            } else {
                newColumn -= halfColumn
                
                if newRowsIsEven {
                    newColumn -= 1
                }
            }
        }
        
        let newTurnPoint = Point(row: newRows, column: newColumn)
        
        if newTurnPoint == turnPoint {
            calcNextTurnPoint()
        } else {
            turnPoint = newTurnPoint
        }
    }

    private func oddCalcNextTurnPoint() {
        var diff = abs(stepPoint.column - centerColumn)
        let count = columnsForRow(stepPoint.row)
        let isEvenCount = count.isMultiple(of: 2)
        var appendRows = Int.zero
        
        if isEvenCount {
            appendRows = diff * 2
        } else {
            if stepPoint.column <= centerColumn {
                diff += 1
            }
            
            if diff > .zero {
                appendRows = diff * 2 - 1
            }
        }
        
        let additionalRows = Int.random(in: columnsRange)
        let newRows = stepPoint.row + appendRows + additionalRows
        var newColumn = centerColumn
        
        if additionalRows > .zero {
            let newRowsIsEven = newRows.isMultiple(of: 2)
            let halfColumn = additionalRows / 2

            if side == .right {
                newColumn += halfColumn
                
                if !newRowsIsEven {
                    newColumn += 1
                }
            } else {
                newColumn -= halfColumn
            }
        }
        
        let newTurnPoint = Point(row: newRows, column: newColumn)
        
        if newTurnPoint == turnPoint {
            calcNextTurnPoint()
        } else {
            turnPoint = newTurnPoint
        }
    }
    
    override func didAppendRow(_ row: Int, cellsOfRow: [Grid.Cell]) {
        super.didAppendRow(row, cellsOfRow: cellsOfRow)
        let isTurn = stepPoint == turnPoint
        let stepVariant: Step.Variant
        
        if isTurn {
            stepVariant = side == .left ? .turnRight : .turnLeft
        } else {
            stepVariant = side == .left ? .straightLeft : .straightRight
        }
        
        let stepCell = Cell(point: stepPoint, position: cellPositionForRow(stepPoint.row, andColumn: stepPoint.column))
        let step = Step(cell: stepCell, variant: stepVariant, prev: prevStep)
        prevStep?.next = step
        prevStep = step
        appendStep(step)
        generateZoneCellsForRow(row, stepColumn: stepPoint.column, cellsOfRow: cellsOfRow)
        
        if isTurn {
            fillZoneOnSide(endRow: row, fillSide: side)
            currentZoneStartRow = row
            side = side.opposite
            calcNextTurnPoint()
        }
        
        calcNextStep(forRow: row)
    }
    
    private func appendStep(_ step: Step) {
        steps.append(step)
        stepsByPoint[step.cell.point] = step
        didAppendStep(step)
    }
    
    private func generateZoneCellsForRow(_ row: Int, stepColumn: Int, cellsOfRow: [Grid.Cell]) {
        var leftCells: [Cell] = []
        var rightCells: [Cell] = []
        
        for cell in cellsOfRow {
            let cellColumn = cell.point.column

            if cellColumn == stepColumn {
                continue
            }
            
            if cellColumn < stepColumn {
                leftCells.append(cell)
            } else {
                rightCells.append(cell)
            }
        }

        if !leftCells.isEmpty {
            pendingLeftCells[row] = leftCells
        }

        if !rightCells.isEmpty {
            pendingRightCells[row] = rightCells
        }
    }
    
    private func fillZoneOnSide(endRow: Int, fillSide: Side) {
        if endRow > currentZoneStartRow {
            var zoneCells: [Cell] = []

            for (row, cells) in (fillSide == .left ? pendingLeftCells : pendingRightCells) {
                if row <= endRow {
                    for cell in cells {
                        if !filledCells.contains(cell.point) {
                            zoneCells.append(cell)
                            filledCells.insert(cell.point)
                        }
                    }
                }
            }
            
            if !zoneCells.isEmpty {
                let zone = Zone(
                    cells: zoneCells,
                    side: fillSide,
                    startRow: zoneCells.map { $0.point.row }.min() ?? currentZoneStartRow,
                    endRow: endRow
                )

                zones.append(zone)

                if zonesByStartRow[zone.startRow] == nil {
                    zonesByStartRow[zone.startRow] = []
                }

                zonesByStartRow[zone.startRow]?.append(zone)
                didAppendZone(zone)
            }
        }

        if fillSide == .left {
            let keysToRemove = pendingLeftCells.keys.filter { $0 <= endRow }

            for key in keysToRemove {
                pendingLeftCells.removeValue(forKey: key)
            }
        } else {
            let keysToRemove = pendingRightCells.keys.filter { $0 <= endRow }

            for key in keysToRemove {
                pendingRightCells.removeValue(forKey: key)
            }
        }
    }
    
    override func didRemoveRow(_ row: Int, cellsOfRow: [Grid.Cell]) {
        super.didRemoveRow(row, cellsOfRow: cellsOfRow)
        
        if !steps.isEmpty {
            let step = steps.removeFirst()
            stepsByPoint.removeValue(forKey: step.cell.point)
            didRemoveStep(step)
        }

        if let zonesAtThisRow = zonesByStartRow[row] {
            for zone in zonesAtThisRow {
                if !zonesStartedExiting.contains(zone) {
                    zonesStartedExiting.insert(zone)
                    willRemoveZone(zone)
                }
            }

            zonesByStartRow.removeValue(forKey: row)
        }

        var indicesToRemove: [Int] = []
        var zonesToRemove: [Zone] = []

        for (index, zone) in zones.enumerated() {
            if zone.endRow <= row {
                indicesToRemove.append(index)
                zonesToRemove.append(zone)
            }
        }

        for index in indicesToRemove.reversed() {
            zones.remove(at: index)
        }

        for zone in zonesToRemove {
            zonesStartedExiting.remove(zone)
            didRemoveZone(zone)

            for cell in zone.cells {
                filledCells.remove(cell.point)
            }
        }

        pendingLeftCells.removeValue(forKey: row)
        pendingRightCells.removeValue(forKey: row)
    }
    
    // MARK: - Helper methods for working with zones
    func zoneContaining(row: Int) -> [Zone] {
        return zones.filter { $0.containsRow(row) }
    }
    
    func zoneOnSide(_ side: Side) -> [Zone] {
        return zones.filter { $0.side == side }
    }
    
    func zone(matching zone: Zone) -> Zone? {
        return zones.first { $0 == zone }
    }
    
    func step(at point: Point) -> Step? {
        return stepsByPoint[point]
    }
}
