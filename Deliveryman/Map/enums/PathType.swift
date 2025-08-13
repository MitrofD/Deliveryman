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

    // MARK: - Прямые пути
    case straightLeft = "left"
    case straightRight = "right"
    
    // MARK: - Повороты
    case turnLeft = "turn_left"
    case turnRight = "turn_right"
    
    // MARK: - Ветки после поворота
    case branchAfterTurnLeft = "branch_after_turn_left"
    case branchAfterTurnRight = "branch_after_turn_right"
    
    // MARK: - Ветки до поворота
    case branchBeforeTurnLeft = "branch_before_turn_left"
    case branchBeforeTurnRight = "branch_before_turn_right"
    
    // MARK: - Computed Properties
    
    /// Сторона движения
    var side: MapGrid.Side {
        switch self {
        case .straightLeft, .turnLeft, .branchAfterTurnLeft, .branchBeforeTurnLeft:
            return .left
        case .straightRight, .turnRight, .branchAfterTurnRight, .branchBeforeTurnRight:
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
    
    /// Является ли веткой
    var isBranch: Bool {
        switch self {
        case .branchAfterTurnLeft, .branchAfterTurnRight, .branchBeforeTurnLeft, .branchBeforeTurnRight:
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
}
