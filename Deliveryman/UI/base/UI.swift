//
//  UI.swift
//  Deliveryman
//
//  Created by Dmitriy Mitrofansky on 04.06.23.
//

import SpriteKit

class UI: SKNode {
    enum State {
        case start
        // case game
        // case pause
    }
    
    weak var delegate: UIDelegate?
    let textureAtlas: SKTextureAtlas
    
    private(set) var isFirstTimeChangingState = true
    private(set) var prevState: State?
    
    var state: State? {
        didSet {
            guard oldValue != state else {
                return
            }

            prevState = oldValue
            didChangeState()
            isFirstTimeChangingState = false
        }
    }

    var size: CGSize

    var playButton: SKNode
    
    required init(size: CGSize) {
        let className = String(describing: Self.self)
        let textureAtlas = SKTextureAtlas(named: className)
        self.textureAtlas = textureAtlas
        self.playButton = SKSpriteNode(texture: textureAtlas.textureNamed("play-button"))
        self.size = size
        super.init()
        isUserInteractionEnabled = true
        addChild(self.playButton)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func didChangeState() {
        if let prevState = self.prevState {
            switch prevState {
                case .start:
                    hidePlayButton()
            }
        }
        
        if let state = self.state {
            switch state {
                case .start:
                    showPlayButton()
            }
        }
    }
    
    func hidePlayButton() {
        playButton.isHidden = true
    }
    
    func showPlayButton() {
        playButton.isHidden = false
    }
    
    /*
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let firstTouch = touches.first else {
            return
        }
        
        let touchNode = atPoint(firstTouch.location(in: self))
        
        if let playButton = self.playButton {
            if touchNode == playButton || touchNode.hasParent(playButton) {
                hide()
            }
        }
    }
    
    func show() {
        let playButton = SKSpriteNode(texture: textureAtlas.textureNamed("play"), color: .clear, size: size)
        addChild(playButton)

        showPlayButton(playButton) {
            self.playButton = playButton
        }
    }
    
    func hide() {
        guard let playButton = self.playButton else {
            return
        }

        hidePlayButton(playButton, completion: removePlayButtonIfNeeded)
    }
    
    private func removePlayButtonIfNeeded() {
        guard let playButton = self.playButton else {
            return
        }
        
        playButton.removeFromParent()
        self.playButton = nil
    }
    
    private func showPlayButton(_ button: SKNode, completion: (() -> Void)? = nil) {
        let centerPosition = size.center

        button.position = CGPoint(
            x: centerPosition.x,
            y: size.height + button.frame.height * 0.5
        )

        let rotationAngleOffset = CGFloat(0.61)
        let scaleDuration = TimeInterval(0.8)
        button.zRotation = CGFloat.random(in: -rotationAngleOffset...rotationAngleOffset)
        
        var moveAction = SKEase.moveToWithNode(
            button,
            easeFunction: .curveTypeElastic,
            easeType: .easeTypeOut,
            time: 1,
            to: centerPosition
        )
        
        moveAction.timingMode = .easeIn
        
        if let unwrappedCompletion = completion {
            moveAction = SKAction.sequence([
                moveAction,
                SKAction.run(unwrappedCompletion)
            ])
        }
        
        let action = SKAction.group([
            moveAction,
            SKAction.repeatForever(SKAction.sequence([
                SKAction.scale(
                    to: 1.2,
                    duration: scaleDuration
                ),
                SKAction.scale(
                    to: 1,
                    duration: scaleDuration
                ),
            ]))
        ])

        button.run(action)
    }
    
    private func hidePlayButton(_ button: SKNode, completion: (() -> Void)? = nil) {
        let maxSide = max(size.width, size.height)
        let minButtonSide = min(button.frame.width, button.frame.height)
        let needScale = maxSide * 1.5 / minButtonSide
        let actionDuration = TimeInterval(1)
        let fadeDelay = actionDuration * 0.35
        
        let action = SKAction.group([
            SKAction.scale(
                to: needScale,
                duration: actionDuration
            ),
            SKAction.rotate(
                toAngle: -9.42477,
                duration: actionDuration
            ),
            SKAction.sequence([
                SKAction.wait(forDuration: fadeDelay),
                SKAction.fadeOut(withDuration: actionDuration - fadeDelay)
            ])
        ])
        
        action.timingMode = .easeOut
        
        guard let unwrappedCompletion = completion else {
            button.run(action)
            return
        }
        
        button.run(action, completion: unwrappedCompletion)
    }
    
    private func clean() {
        if let playButton = self.playButton {
            playButton.removeFromParent()
            self.playButton = nil
        }
    }
    
    private func didChangeSize() {
        
    }
    */
}
