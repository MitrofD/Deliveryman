//
//  TexturedMap.swift
//  Deliveryman
//
//  Created by Dmitriy Mitrofansky on 22.06.25.
//

import SpriteKit

class TexturedMap: TiledIsometricPathGrid {
    private var isLoadedTextureAtlas: Bool = false
    let textureAtlas: SKTextureAtlas
    let groundNode: SKSpriteNode
    let leftPathNode: SKSpriteNode
    let leftPathTurnNode: SKSpriteNode
    let rightPathNode: SKSpriteNode
    let rightPathTurnNode: SKSpriteNode
    var onReady: () -> Void = {}

    required init(textureAtlas: SKTextureAtlas, size: CGSize) {
        self.textureAtlas = textureAtlas
        let cellTexture = textureAtlas.textureNamed("base")
        let cellTextureSize = cellTexture.size()
        let cellWidth = size.width / (CGFloat(5))
        let cellHeigth = cellWidth * (cellTextureSize.height / cellTextureSize.width)
        let cellSize = CGSize(width: cellWidth, height: cellHeigth)

        groundNode = SKSpriteNode(texture: cellTexture, size: cellSize)
        leftPathNode = SKSpriteNode(texture: textureAtlas.textureNamed("left-path"), size: cellSize)
        leftPathTurnNode = SKSpriteNode(texture: textureAtlas.textureNamed("left-path-turn"), size: cellSize)
        rightPathNode = SKSpriteNode(texture: textureAtlas.textureNamed("right-path"), size: cellSize)
        rightPathTurnNode = SKSpriteNode(texture: textureAtlas.textureNamed("right-path-turn"), size: cellSize)
        super.init(size: size, cellSize: cellSize)
        
        textureAtlas.preload { [weak self] in
            if let self = self {
                self.isLoadedTextureAtlas = true
                self.triggerOnReadyIfNeeded()
            }
        }
    }
    
    @MainActor required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func pathNodeForStep(_ step: IsometricPathGrid.Step) -> SKNode {
        var node: SKNode
        
        if step.isTurn {
            node = step.side == .right ? leftPathTurnNode : rightPathTurnNode
        } else {
            node = step.side == .left ? leftPathNode : rightPathNode
        }

        let nodeClone = node.clone()
        nodeClone.position = step.position

        return nodeClone
    }
    
    override func groundNodeForCell(_ cell: Grid.Cell) -> SKNode {
        let node = groundNode.clone()
        node.position = cell.position
        node.zPosition = -CGFloat(cell.point.row)

        return node
    }
    
    override func didBuilt() {
        super.didBuilt()
        triggerOnReadyIfNeeded()
    }
    
    override func didReseted() {
        super.didReseted()
        triggerOnReadyIfNeeded()
    }
    
    private func triggerOnReadyIfNeeded() {
        if isFilled && isLoadedTextureAtlas {
            onReady()
        }
    }
}
