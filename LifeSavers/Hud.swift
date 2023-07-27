//
//  Hud.swift
//  LifeSaver
//
//  Created by Phil Stern on 4/24/21.
//
//  Hud is set up in GameViewController.setupHud to take up the whole screen.  Hud has circular arrow
//  nodes to rotate the selected life saver node, and an arrow node to drop the selected life saver
//  onto the stack.  The actual movement is handled by GameViewController when the nodes are touched,
//  by calling a corresponding callback handler below.
//

import Foundation
import SpriteKit

class Hud: SKScene {
    var rotateControlHandler: (() -> Void)?
    var flipControlHandler: (() -> Void)?
    var dropControlHandler: (() -> Void)?
    
    var rotateSelectionNode = SKSpriteNode()
    var flipSelectionNode = SKSpriteNode()
    var dropSelectionNode = SKSpriteNode()
    
    let horizontalCircleTexture = SKTexture(imageNamed: "horizontal circle")
    let verticalCircleTexture = SKTexture(imageNamed: "vertical circle")
    let downArrowTexture = SKTexture(imageNamed: "down arrow")

    var orientationControlIsHidden: Bool = true {
        didSet {
            rotateSelectionNode.isHidden = orientationControlIsHidden
            flipSelectionNode.isHidden = orientationControlIsHidden
            dropSelectionNode.isHidden = orientationControlIsHidden
        }
    }
    
    func setup(rotateControlHandler: @escaping () -> Void, flipControlHandler: @escaping () -> Void, dropControlHandler: @escaping () -> Void) {
        self.rotateControlHandler = rotateControlHandler
        self.flipControlHandler = flipControlHandler
        self.dropControlHandler = dropControlHandler
        
        rotateSelectionNode = SKSpriteNode(texture: horizontalCircleTexture)
        rotateSelectionNode.position = CGPoint(x: frame.midX, y: 0.73 * frame.height)  // above holding point
        addChild(rotateSelectionNode)
        
        flipSelectionNode = SKSpriteNode(texture: verticalCircleTexture)
        flipSelectionNode.position = CGPoint(x: 0.65 * frame.width, y: 0.65 * frame.height)  // right of holding point
        addChild(flipSelectionNode)
        
        dropSelectionNode = SKSpriteNode(texture: downArrowTexture)
        dropSelectionNode.position = CGPoint(x: frame.midX, y: 0.58 * frame.height)  // below holding point
        addChild(dropSelectionNode)
        
        orientationControlIsHidden = true
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first!
        let location = touch.location(in: self)
        if rotateSelectionNode.contains(location) {
            rotateControlHandler?()
        }
        if flipSelectionNode.contains(location) {
            flipControlHandler?()
        }
        if dropSelectionNode.contains(location) {
            dropControlHandler?()
        }
    }
}
