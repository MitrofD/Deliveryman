//
//  IsometricPathGrid.swift
//  Deliveryman
//
//  Created by Dmitriy Mitrofansky on 29.09.24.
//

import SpriteKit

fileprivate func getIndentTop(size: CGSize, cellSize: CGSize) -> Int {
    return Int(ceil(size.width / cellSize.width)) * 3
}

fileprivate func getCorrectIndentFromIndent(_ indent: Grid.Indent, size: CGSize, cellSize: CGSize) -> Grid.Indent {
    return Grid.Indent(top: indent.top + getIndentTop(size: size, cellSize: cellSize), right: indent.right, bottom: indent.bottom, left: indent.left)
}

class IsometricPathGrid: IsometricGrid {
    enum Side {
        case left, right
        
        static var random: Side {
            let directions = [Side.left, Side.right]
            return directions.randomElement()!
        }
        
        var opposite: Side {
            return self == .left ? .right : .left
        }
    }
    
    class Step: Cell {
        fileprivate(set) var side: Side
        fileprivate(set) var isTurn = false
        fileprivate(set) weak var next: Step?
        fileprivate(set) weak var prev: Step?
        
        init(point: Point, position: CGPoint, side: Side, isTurn: Bool = false, prev: Step? = nil, next: Step? = nil) {
            self.side = side
            self.isTurn = isTurn
            self.next = next
            self.prev = prev
            super.init(point: point, position: position)
        }
        
        override var description: String {
            return "\(super.description), side: \(side), \(isTurn ? "turn" : "straight")"
        }
    }
    
    class Area: CustomStringConvertible {
        let cells: [Cell]
        let side: Side
        let startRow: Int
        let endRow: Int
        let id: UUID
        
        init(cells: [Cell], side: Side, startRow: Int, endRow: Int) {
            self.cells = cells
            self.side = side
            self.startRow = startRow
            self.endRow = endRow
            self.id = UUID()
        }
        
        var description: String {
            return "Area(id: \(id.uuidString.prefix(8)), side: \(side), rows: \(startRow)-\(endRow), cells: \(cells.count))"
        }
        
        var rowRange: ClosedRange<Int> {
            return startRow...endRow
        }
        
        func containsRow(_ row: Int) -> Bool {
            return rowRange.contains(row)
        }
    }
    
    // For child overrides - existing methods
    func didAppendStep(_ step: Step) {}
    func didRemoveStep(_ step: Step) {}
    
    // New methods for areas
    func didAppendArea(_ area: Area) {}
    func didRemoveArea(_ area: Area) {}
    
    override var indent: Grid.Indent {
        get {
            return super.indent
        }
        
        set(newIndent) {
            super.indent = getCorrectIndentFromIndent(newIndent, size: size, cellSize: cellSize)
        }
    }

    private(set) var steps = [Step]()
    private(set) var areas = [Area]()
    private(set) var side = Side.left

    private var calcNextTurnPoint: () -> Void = { }
    private var centerColumn = Int.zero
    private var columnsRange = Range(uncheckedBounds: (lower: Int.zero, upper: Int.zero))
    private var prevStep: Step?
    private var stepPoint = Point.zero
    private var turnPoint = Point.zero
    
    // Area tracking
    private var currentAreaStartRow: Int = 0
    private var pendingLeftCells: [Int: [Cell]] = [:]  // row -> [cells]
    private var pendingRightCells: [Int: [Cell]] = [:] // row -> [cells]
    private var filledCells: Set<Point> = [] // Track which cells are already filled
    
    override init(size: CGSize, cellSize: CGSize, indent: Indent = Indent(top: 1, right: .zero, bottom: .zero, left: .zero)) {
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
        areas.removeAll()
        pendingLeftCells.removeAll()
        pendingRightCells.removeAll()
        filledCells.removeAll()
        prevStep = nil
        
        let maxColumns = self.maxColumns
        centerColumn = maxColumns / 2
        columnsRange = .zero..<maxColumns
        calcNextTurnPoint = maxColumns.isMultiple(of: 2) ? evenCalcNextTurnPoint : oddCalcNextTurnPoint
        stepPoint.row = indent.bottom
        stepPoint.column = Int.random(in: indent.left..<maxColumns)
        side = stepPoint.column < centerColumn ? .right : .left
        
        currentAreaStartRow = stepPoint.row

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
    
    private var lastTurn: Step? {
        for step in steps.reversed() {
            if (step.isTurn) {
                return step
            }
        }

        return nil
    }
    
    override func didAppendRow(_ row: Int, cellsOfRow: [Grid.Cell]) {
        super.didAppendRow(row, cellsOfRow: cellsOfRow)
        
        let isTurn = stepPoint == turnPoint
        let step = Step(point: stepPoint, position: cellPositionForRow(stepPoint.row, andColumn: stepPoint.column), side: side, isTurn: isTurn, prev: prevStep)
        prevStep?.next = step
        prevStep = step
        appendStep(step)

        // Generate area cells for current row
        generateAreaCellsForRow(row, stepColumn: stepPoint.column, cellsOfRow: cellsOfRow)
        
        if isTurn {
            // Fill the area on the SAME side as current movement direction
            // If moving left (to left), fill left side. If moving right (to right), fill right side.
            let fillSide = side
            fillAreaOnSide(endRow: row, fillSide: fillSide)
            currentAreaStartRow = row
            
            side = side.opposite
            calcNextTurnPoint()
        }
        
        calcNextStep(forRow: row)
    }
    
    private func appendStep(_ step: Step) {
        steps.append(step)
        didAppendStep(step)
    }
    
    private func generateAreaCellsForRow(_ row: Int, stepColumn: Int, cellsOfRow: [Grid.Cell]) {
        var leftCells: [Cell] = []
        var rightCells: [Cell] = []
        
        for cell in cellsOfRow {
            let cellColumn = cell.point.column
            
            // Skip the path cell itself
            if cellColumn == stepColumn {
                continue
            }
            
            if cellColumn < stepColumn {
                leftCells.append(cell)
            } else {
                rightCells.append(cell)
            }
        }
        
        // Store pending cells
        if !leftCells.isEmpty {
            pendingLeftCells[row] = leftCells
        }
        if !rightCells.isEmpty {
            pendingRightCells[row] = rightCells
        }
    }
    
    private func fillAreaOnSide(endRow: Int, fillSide: Side) {
        if endRow > currentAreaStartRow {
            var areaCells: [Cell] = []
            
            // Collect ALL unfilled cells from the specified side up to the turn row
            // Search through ALL pending cells, not just current segment
            for (row, cells) in (fillSide == .left ? pendingLeftCells : pendingRightCells) {
                if row <= endRow { // All rows up to and including turn row
                    for cell in cells {
                        // Only add cells that haven't been filled yet
                        if !filledCells.contains(cell.point) {
                            areaCells.append(cell)
                            filledCells.insert(cell.point)
                        }
                    }
                }
            }
            
            if !areaCells.isEmpty {
                let area = Area(
                    cells: areaCells,
                    side: fillSide,
                    startRow: areaCells.map { $0.point.row }.min() ?? currentAreaStartRow,
                    endRow: endRow
                )
                areas.append(area)
                didAppendArea(area)
            }
        }
        
        // Clean up processed pending cells for the filled side up to endRow
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
            didRemoveStep(step)
        }
        
        // Remove areas that are no longer visible
        let areasToRemove = areas.filter { area in
            area.endRow <= row
        }
        
        for area in areasToRemove {
            if let index = areas.firstIndex(where: { $0.id == area.id }) {
                areas.remove(at: index)
                didRemoveArea(area)
                
                // Remove filled cells from the removed area
                for cell in area.cells {
                    filledCells.remove(cell.point)
                }
            }
        }
        
        // Clean up pending cells for this row
        pendingLeftCells.removeValue(forKey: row)
        pendingRightCells.removeValue(forKey: row)
    }
    
    // Helper methods for working with areas
    func areasContaining(row: Int) -> [Area] {
        return areas.filter { $0.containsRow(row) }
    }
    
    func areasOnSide(_ side: Side) -> [Area] {
        return areas.filter { $0.side == side }
    }
    
    func area(withId id: UUID) -> Area? {
        return areas.first { $0.id == id }
    }
}
