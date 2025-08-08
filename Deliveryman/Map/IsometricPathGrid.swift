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
    
    // For child overrides
    func didAppendStep(_ step: Step) {}
    func didRemoveStep(_ step: Step) {}
    
    override var indent: Grid.Indent {
        get {
            return super.indent
        }
        
        set(newIndent) {
            super.indent = getCorrectIndentFromIndent(newIndent, size: size, cellSize: cellSize)
        }
    }

    private(set) var steps = [Step]()
    private(set) var side = Side.left

    private var calcNextTurnPoint: () -> Void = { }
    private var centerColumn = Int.zero
    private var columnsRange = Range(uncheckedBounds: (lower: Int.zero, upper: Int.zero))
    private var prevStep: Step?
    private var stepPoint = Point.zero
    private var turnPoint = Point.zero
    // private var tiles: [[SKSpriteNode]] = []
    
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
        prevStep = nil
        
        let maxColumns = self.maxColumns
        centerColumn = maxColumns / 2
        columnsRange = .zero..<maxColumns
        calcNextTurnPoint = maxColumns.isMultiple(of: 2) ? evenCalcNextTurnPoint : oddCalcNextTurnPoint
        stepPoint.row = indent.bottom
        stepPoint.column = Int.random(in: indent.left..<maxColumns)
        side = stepPoint.column < centerColumn ? .right : .left

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
    
    override func didRemoveRow(_ row: Int, cellsOfRow: [Grid.Cell]) {
        super.didRemoveRow(row, cellsOfRow: cellsOfRow)
        
        if !steps.isEmpty {
            let step = steps.removeFirst()
            didRemoveStep(step)
        }
    }
    
    override func didAppendRow(_ row: Int, cellsOfRow: [Grid.Cell]) {
        super.didAppendRow(row, cellsOfRow: cellsOfRow)
        
        let isTurn = stepPoint == turnPoint
        let step = Step(point: stepPoint, position: cellPositionForRow(stepPoint.row, andColumn: stepPoint.column), side: side, isTurn: isTurn, prev: prevStep)
        prevStep?.next = step
        prevStep = step
        appendStep(step)

        if isTurn {
            side = side.opposite
            calcNextTurnPoint()
        }
        
        calcNextStep(forRow: row)
    }
    
    private func appendStep(_ step: Step) {
        steps.append(step)
        didAppendStep(step)
    }
}
