//
//  Grid.swift
//  Deliveryman
//
//  Created by Dmitriy Mitrofansky on 28.09.24.
//

import SpriteKit

class Grid: SKNode {
    static let moveActionKey = "procedural_grid_move"

    struct Indent: Equatable {
        let top: Int
        let right: Int
        let bottom: Int
        let left: Int
        
        init(top: Int, right: Int, bottom: Int, left: Int) {
            self.top = top
            self.right = right
            self.bottom = bottom
            self.left = left
        }
        
        init(x: Int, y: Int) {
            self.init(top: y, right: x, bottom: y, left: x)
        }
        
        init(_ value: Int) {
            self.init(top: value, right: value, bottom: value, left: value)
        }
    }

    struct Direction {
        let row: Int
        let column: Int
        
        static let east = Self(row: .zero, column: 1)
        static let north = Self(row: 2, column: .zero)
        static let northEast = Self(row: 1, column: 1)
        static let northWest = Self(row: 1, column: .zero)
        static let south = Self(row: -2, column: .zero)
        static let southEast = Self(row: -1, column: 1)
        static let southWest = Self(row: -1, column: .zero)
        static let west = Self(row: .zero, column: -1)

        private init(row: Int, column: Int) {
            self.row = row
            self.column = column
        }
    }
    
    struct Point: CustomStringConvertible, Hashable {
        var row: Int
        var column: Int
        
        static var zero: Point {
            return .init(row: .zero, column: .zero)
        }
        
        var description: String {
            return "(\(row), \(column))"
        }
    }
    
    class Cell: CustomStringConvertible, Hashable {
        static func ==(lhs: Cell, rhs: Cell) -> Bool {
            return lhs.point == rhs.point && lhs.position == rhs.position
        }

        let point: Point
        let position: CGPoint
        
        init(row: Int, column: Int, position: CGPoint) {
            self.position = position
            self.point = Point(row: row, column: column)
        }
        
        init(point: Point, position: CGPoint) {
            self.position = position
            self.point = point
        }
        
        var description: String {
            return "Point: \(point), position: \(position)"
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(point)

            if #available(iOS 18.0, *) {
                hasher.combine(position)
            } else {
                hasher.combine(position.x)
                hasher.combine(position.y)
            }
        }
    }

    func willMove(distance: CGFloat, duration: TimeInterval) -> Void {}
    func willBuilt() -> Void {}
    func didBuilt() -> Void {}
    func willDestroyed() -> Void {}
    func didDestroyed() -> Void {}
    func willResetted() -> Void {}
    func didReseted() -> Void {}
    func willMoved(distance: CGFloat, duration: TimeInterval) -> Void {}
    func didStepped() -> Void {}
    func didAppendCell(_ cell: Cell) -> Void {}
    func didAppendRow(_ row: Int, cellsOfRow: [Cell]) -> Void {}
    func didRemoveCell(_ cell: Cell) -> Void {}
    func didRemoveRow(_ row: Int, cellsOfRow: [Cell]) -> Void {}
    
    var cellSize: CGSize {
        didSet {
            resetIfChanges(old: oldValue, current: cellSize)
        }
    }
    
    var indent: Indent {
        didSet {
            resetIfChanges(old: oldValue, current: indent)
        }
    }
    
    var size: CGSize {
        didSet {
            resetIfChanges(old: oldValue, current: size)
        }
    }
    
    let gridNode = SKNode()
    
    private(set) var cells = [[Cell]]()
    private(set) var isFilled = false

    private var appendToTop: () -> Void = {}
    private var topCounter = Int.zero
    private var appendToBottom: () -> Void = {}
    private var bottomCounter = Int.zero
    private var moveByStep = false
    private var yStep = CGFloat.zero
    private var cachedColumnsCount: Int?

    init(size: CGSize, cellSize: CGSize, indent: Indent = Indent(1)) {
        self.cellSize = cellSize
        self.size = size
        self.indent = indent
        super.init()
        addChild(gridNode)
        
        // MARK: Experiment shape
        /*
        let shape = SKShapeNode(rectOf: size)
        shape.position.x = size.width * 0.5
        shape.position.y = size.height * 0.5
        shape.fillColor = .red
        shape.lineWidth = .zero
        shape.alpha = 0.2
        shape.zPosition = 99
        addChild(shape)
        */
    }
    
    @MainActor required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @discardableResult
    func build() -> Bool {
        guard !isFilled else {
            return false
        }

        reset()
        return true
    }
    
    func destroy() {
        guard isFilled else {
            return
        }
        
        willDestroyed()
        stopAndReset()
        isFilled = false
        didDestroyed()
    }
    
    func cellPositionForRow(_ row: Int, andColumn column: Int) -> CGPoint {
        return CGPoint(x: CGFloat(column) * cellSize.width, y: CGFloat(row) * cellSize.height)
    }
    
    private var maxColumns: Int {
        var columns = Int.zero
        var xPosPrev = CGFloat.zero
        var xPos = CGFloat.zero
        
        while xPos < size.width {
            let step = self.cellPositionForRow(.zero, andColumn: columns)
            xPos += step.x - xPosPrev
            xPosPrev = xPos
            columns += 1
        }

        return max(.zero, columns - 1)
    }
    
    func columnsForRow(_ row: Int) -> Int {
        return cachedColumnsCount ?? maxColumns
    }

    func reset() {
        stopAndReset()

        if isFilled {
            willResetted()
        } else {
            willBuilt()
        }
    
        var rowsCount = Int.zero
        var yPosPrev = CGFloat.zero
        var yPos = CGFloat.zero
        
        while yPos < size.height {
            let step = cellPositionForRow(rowsCount, andColumn: .zero)
            yPos += step.y - yPosPrev
            yPosPrev = yPos
            rowsCount += 1
        }
        
        rowsCount -= 1
        
        self.yStep = yPos / CGFloat(rowsCount)
        cachedColumnsCount = maxColumns
        topCounter = -indent.bottom
    
        appendToTop = {
            var row = [Cell]()
            let toColumn = self.columnsForRow(self.topCounter) + self.indent.right
            
            for column in -self.indent.left...toColumn {
                let position = self.cellPositionForRow(self.topCounter, andColumn: column)
                let cell = Cell(row: self.topCounter, column: column, position: position)
                row.append(cell)
                self.didAppendCell(cell)
            }

            self.cells.append(row)
            self.didAppendRow(self.topCounter, cellsOfRow: row)
            self.topCounter += 1
        }
        
        bottomCounter = topCounter - 1
        
        appendToBottom = {
            var row = [Cell]()
            let toColumn = self.columnsForRow(self.bottomCounter) + self.indent.right
            
            for column in -self.indent.left...toColumn {
                let position = self.cellPositionForRow(self.bottomCounter, andColumn: column)
                let cell = Cell(row: self.bottomCounter, column: column, position: position)
                row.append(cell)
                self.didAppendCell(cell)
            }
            
            self.cells.insert(row, at: .zero)
            self.didAppendRow(self.bottomCounter, cellsOfRow: row)
            self.bottomCounter -= 1
        }

        for _ in -indent.bottom...rowsCount + indent.top  {
            appendToTop()
        }
        
        if isFilled {
            didReseted()
        } else {
            isFilled = true
            didBuilt()
        }
    }

    func moveByStep(duration: TimeInterval, steps: CGFloat? = nil) {
        var moveDistance = yStep
        var moveDuration = duration
        
        if let unwrappedSteps = steps {
            moveDistance *= unwrappedSteps
            moveDuration *= unwrappedSteps
        } else {
            moveByStep = true
        }
        
        move(distance: moveDistance, duration: moveDuration)
        moveByStep = false
    }
    
    func move(distance: CGFloat, duration: TimeInterval? = nil) {
        stop()
        build()
        
        guard distance > .zero else {
            return
        }
        
        var distanceRemainder = distance
        let startDistance = yStep - abs(position.y.truncatingRemainder(dividingBy: yStep))
        let needEndStep = startDistance > .zero
        
        guard let unwrappedDuration = duration else {
            if needEndStep {
                distanceRemainder -= startDistance
                willMove(distance: startDistance, duration: .zero)
                
                if distanceRemainder >= .zero {
                    shiftBottom()
                }
            }
            
            if distanceRemainder > .zero {
                let stepsCount = Int(floor(distanceRemainder / yStep))
                
                for _ in .zero..<stepsCount {
                    willMove(distance: yStep, duration: .zero)
                    shiftBottom()
                }
            }

            gridNode.position.y -= distance
            return
        }

        let absDuration = abs(unwrappedDuration)
        var durationRemainder = absDuration
        let stepper: () -> Void
        
        if moveByStep {
            stepper = {
                self.willMove(distance: distance, duration: absDuration)
                
                self.gridNode.run(SKAction.repeatForever(SKAction.sequence([
                    SKAction.moveBy(x: .zero, y: -distance, duration: absDuration),
                    SKAction.run {
                        self.shiftBottom()
                        self.willMove(distance: distance, duration: absDuration)
                    }
                ])), withKey: Self.moveActionKey)
            }
        } else {
            stepper = {
                let factor = self.cellSize.height / distanceRemainder
                let stepDistance = distanceRemainder * factor
                let stepDuration = durationRemainder * factor
                let repeatsCount = floor(durationRemainder / stepDuration)
                var action: SKAction?
                
                if repeatsCount > .zero {
                    distanceRemainder -= stepDistance * repeatsCount
                    durationRemainder -= durationRemainder * repeatsCount
                    self.willMove(distance: stepDistance, duration: stepDuration)

                    action = SKAction.repeat(SKAction.sequence([
                        SKAction.moveBy(x: .zero, y: -stepDistance, duration: stepDuration),
                        SKAction.run {
                            self.shiftBottom()
                            self.willMove(distance: stepDistance, duration: stepDuration)
                        }
                    ]), count: Int(repeatsCount))
                }

                if distanceRemainder > .zero {
                    let endAction = SKAction.moveBy(x: .zero, y: -distanceRemainder, duration: durationRemainder)
                    self.willMove(distance: distanceRemainder, duration: durationRemainder)

                    if let unwrappedAction = action {
                        action = SKAction.sequence([
                            unwrappedAction,
                            endAction
                        ])
                    } else {
                        action = endAction
                    }
                }
                
                if let unwrappedAction = action {
                    self.gridNode.run(unwrappedAction, withKey: Self.moveActionKey)
                }
            }
        }
        
        if needEndStep {
            let startDuration = durationRemainder * (startDistance / distanceRemainder)
            self.willMove(distance: startDistance, duration: startDuration)
            
            gridNode.run(SKAction.sequence([
                SKAction.moveBy(x: .zero, y: -startDistance, duration: startDuration),
                SKAction.run {
                    distanceRemainder -= startDistance
                    durationRemainder -= startDuration
                    
                    if distanceRemainder >= .zero {
                        self.shiftBottom()
                    }

                    stepper()
                }
            ]), withKey: Self.moveActionKey)
        } else {
            stepper()
        }
    }
    
    var isMoving: Bool {
        return gridNode.action(forKey: Self.moveActionKey) != nil
    }
    
    var columns: Int {
        return Int(ceil(size.width / cellSize.width))
    }
    
    var rows: Int {
        return Int(ceil(size.height / cellSize.height))
    }
    
    final func resetIfChanges<T: Equatable>(old: T, current: T) {
        guard old != current else {
            return
        }

        if isFilled {
            reset()
        }
    }
    
    func stop() {
        gridNode.removeAction(forKey: Self.moveActionKey)
    }
    // MARK: - Cell methods

    func cell(atRow row: Int, column: Int) -> Cell? {
        guard let rowCells = cells(atRow: row) else {
            return nil
        }
        
        guard rowCells.indices.contains(column) else {
            return nil
        }
        
        return rowCells[column]
    }
    
    func cells(atRow row: Int) -> [Cell]? {
        let rowIndex = row - bottomCounter
        
        guard cells.indices.contains(rowIndex) else {
            return nil
        }
        
        return cells[rowIndex]
    }
    
    func cellNeighbour(atRow row: Int, column: Int, direction: Direction) -> Cell? {
        return cell(atRow: row + direction.row, column: column + direction.column)
    }
    
    func cellNeighbour(forCell cell: Cell, direction: Direction) -> Cell? {
        return self.cell(atRow: cell.point.row + direction.row, column: cell.point.column + direction.column)
    }
    
    // MARK: - Private methods
    
    private func shiftTop() {
        let cellsOfRow: [Cell]

        if let row = cells.last {
            cellsOfRow = row
            row.forEach(didRemoveCell)
            cells.removeLast()
        } else {
            cellsOfRow = []
        }
        
        appendToBottom()
        topCounter -= 1
        didRemoveRow(topCounter, cellsOfRow: cellsOfRow)
        didStepped()
    }

    private func shiftBottom() {
        let cellsOfRow: [Cell]

        if let row = cells.first {
            cellsOfRow = row
            row.forEach(didRemoveCell)
            cells.removeFirst()
        } else {
            cellsOfRow = []
        }

        appendToTop()
        bottomCounter += 1
        didRemoveRow(bottomCounter, cellsOfRow: cellsOfRow)
        didStepped()
    }
    
    private func stopAndReset() {
        stop()
        gridNode.position = .zero
        bottomCounter = .zero
        topCounter = .zero
        appendToBottom = {}
        appendToTop = {}
        yStep = .zero
        cachedColumnsCount = nil
        
        cells.forEach { row in
            if let firstCell = row.first {
                row.forEach { cell in
                    didRemoveCell(cell)
                }
                
                didRemoveRow(firstCell.point.row, cellsOfRow: row)
            }
        }
        
        cells = []
    }
}
