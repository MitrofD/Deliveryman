//
//  GameViewController.swift
//  Deliveryman
//
//  Created by Dmitriy Mitrofansky on 05.10.22.
//

import UIKit
import SpriteKit

class RootViewController: UIViewController {
    let skView = SKView()

    override func viewDidLoad() {
        super.viewDidLoad()
        skViewSettings()
        view = skView
        presentGameScene()
    }
    
    func presentGameScene() {
        let scene = GameScene(size: skView.frame.size)
        skView.presentScene(scene)
    }
    
    private func skViewSettings() {
        skView.frame.size = view.frame.size
        skView.ignoresSiblingOrder = true
        skView.showsFPS = true
        skView.showsNodeCount = true
    }
}
