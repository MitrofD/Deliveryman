//
//  call-if-cahnged.swift
//  Deliveryman
//
//  Created by Dmitriy Mitrofansky on 29.09.24.
//

import Foundation

func callIfChanged<T: Equatable>(old: T, current: T, handler: () -> Void) {
    guard old != current else {
        return
    }

    handler()
}
