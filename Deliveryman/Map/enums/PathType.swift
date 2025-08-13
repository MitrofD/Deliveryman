//
//  PathType.swift
//  Deliveryman
//
//  Created by Dmitriy Mitrofansky on 13.08.25.
//

enum PathType: String, CaseIterable {
    init(step: MapGrid.Step) {
        if step.isTurn {
            self = step.side == .left ? .turnRight : .turnLeft
        } else {
            self = step.side == .left ? .straightLeft : .straightRight
        }
    }

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
    
    // MARK: - Helper Methods
    
    /// Возвращает соответствующий тип окончания ветки
    var correspondingBranchEnd: PathType? {
        switch self {
        case .branchAfterLeft:
            return .branchAfterLeftEnd
        case .branchAfterRight:
            return .branchAfterRightEnd
        case .branchBeforeLeft:
            return .branchBeforeLeftEnd
        case .branchBeforeRight:
            return .branchBeforeRightEnd
        default:
            return nil
        }
    }
    
    /// Возвращает соответствующий тип начала ветки
    var correspondingBranchStart: PathType? {
        switch self {
        case .branchAfterLeftEnd:
            return .branchAfterLeft
        case .branchAfterRightEnd:
            return .branchAfterRight
        case .branchBeforeLeftEnd:
            return .branchBeforeLeft
        case .branchBeforeRightEnd:
            return .branchBeforeRight
        default:
            return nil
        }
    }
    
    /// Возвращает все возможные типы веток для данной стороны и периода
    static func branchTypes(for side: MapGrid.Side, isAfterTurn: Bool) -> [PathType] {
        switch (side, isAfterTurn) {
        case (.left, true):
            return [.branchAfterLeft, .branchAfterLeftEnd]
        case (.left, false):
            return [.branchBeforeLeft, .branchBeforeLeftEnd]
        case (.right, true):
            return [.branchAfterRight, .branchAfterRightEnd]
        case (.right, false):
            return [.branchBeforeRight, .branchBeforeRightEnd]
        }
    }
    
    /// Возвращает начальную ветку для данной стороны и периода
    static func branchStart(for side: MapGrid.Side, isAfterTurn: Bool) -> PathType {
        switch (side, isAfterTurn) {
        case (.left, true):
            return .branchAfterLeft
        case (.left, false):
            return .branchBeforeLeft
        case (.right, true):
            return .branchAfterRight
        case (.right, false):
            return .branchBeforeRight
        }
    }
    
    /// Возвращает окончание ветки для данной стороны и периода
    static func branchEnd(for side: MapGrid.Side, isAfterTurn: Bool) -> PathType {
        switch (side, isAfterTurn) {
        case (.left, true):
            return .branchAfterLeftEnd
        case (.left, false):
            return .branchBeforeLeftEnd
        case (.right, true):
            return .branchAfterRightEnd
        case (.right, false):
            return .branchBeforeRightEnd
        }
    }
}
