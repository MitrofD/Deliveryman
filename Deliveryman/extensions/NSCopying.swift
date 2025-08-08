//
//  File.swift
//  Deliveryman
//
//  Created by Dmitriy Mitrofansky on 05.10.23.
//

import Foundation

extension NSCopying {
    func clone() -> Self {
        return copy() as! Self
    }
}
