//
//  IsometricGrid.swift
//  Deliveryman
//
//  Created by Dmitriy Mitrofansky on 28.09.24.
//

import Foundation

class IsometricGrid: Grid {
    override func cellPositionForRow(_ row: Int, andColumn column: Int) -> CGPoint {
        var x = CGFloat(column) * cellSize.width
        
        if (isEvenRow(row)) {
            x += cellSize.width / 2
        }

        return CGPoint(
            x: x,
            y: CGFloat(row) * (cellSize.height / 2)
        )
    }
    
    override func columnsForRow(_ row: Int) -> Int {
        let columns = super.columnsForRow(row)
        return isEvenRow(row) ? columns - 1 : columns
    }
    
    func isEvenRow(_ row: Int) -> Bool {
        return row.isMultiple(of: 2)
    }
    
    override func getSouthCell(for point: Point) -> Cell? {
        return getCell(for: point.row - 2, column: point.column)
    }
    
    override func getNorthCell(for point: Point) -> Cell? {
        return getCell(for: point.row + 2, column: point.column)
    }
    
    override func getNorthWestCell(for point: Point) -> Cell? {
        return getCell(for: point.row + 1, column: isEvenRow(point.row) ? point.column : point.column - 1)
    }
    
    override func getNorthEastCell(for point: Point) -> Cell? {
        return getCell(for: point.row + 1, column: !isEvenRow(point.row) ? point.column : point.column + 1)
    }
    
    override func getSouthWestCell(for point: Point) -> Cell? {
        return getCell(for: point.row - 1, column: isEvenRow(point.row) ? point.column : point.column - 1)
    }
    
    override func getSouthEastCell(for point: Point) -> Cell? {
        return getCell(for: point.row - 1, column: !isEvenRow(point.row) ? point.column : point.column + 1)
    }
}
