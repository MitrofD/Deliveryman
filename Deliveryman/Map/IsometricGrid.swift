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
        
        if (row.isMultiple(of: 2)) {
            x += cellSize.width / 2
        }

        return CGPoint(
            x: x,
            y: CGFloat(row) * (cellSize.height / 2)
        )
    }
    
    override func columnsForRow(_ row: Int) -> Int {
        let columns = super.columnsForRow(row)
        return row.isMultiple(of: 2) ? columns - 1 : columns
    }
    
    var maxColumns: Int {
        return max(columnsForRow(.zero), columnsForRow(1))
    }
}
