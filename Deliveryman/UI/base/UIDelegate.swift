//
//  UIDelegate.swift
//  Deliveryman
//
//  Created by Dmitriy Mitrofansky on 04.06.23.
//

import SpriteKit

@objc protocol UIDelegate: AnyObject {
    @objc optional func uiPlayButtonDown(ui: UI)
    @objc optional func uiPlayButtonUp(ui: UI)
    @objc optional func uiPlayButtonPress(ui: UI)
}
