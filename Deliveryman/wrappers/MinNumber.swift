//
//  MinNumber.swift
//  Deliveryman
//
//  Created by Dmitriy Mitrofansky on 06.12.23.
//

import Foundation

@propertyWrapper
struct MinNumber<T: Comparable> {
    private var value: T
    private let min: T
    
    init(_ min: T) {
        self.min = min
        value = min
    }
    
    var wrappedValue: T {
        get {
            return value
        }
        
        set {
            value = max(min, newValue)
        }
    }
}
