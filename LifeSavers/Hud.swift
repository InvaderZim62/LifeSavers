//
//  Hud.swift
//  LifeSaver
//
//  Created by Phil Stern on 4/24/21.
//
//  Hud is set up in GameViewController.setupHud to take up the whole screen.
//  It has a circular arrow button to rotate the selected life saver node.
//

import Foundation
import SpriteKit

class Hud: SKScene {
    var nodeRotationHandler: (() -> Void)?
    var nodeFlipHandler: (() -> Void)?
    var nodeDropHandler: (() -> Void)?
    var rotationSelectionNode = SKSpriteNode()
    var flipSelectionNode = SKSpriteNode()
    var dropSelectionNode = SKSpriteNode()
    let horizontalCircleTexture = SKTexture(imageNamed: "horizontal circle")
    let verticalCircleTexture = SKTexture(imageNamed: "vertical circle")
    let downArrowTexture = SKTexture(imageNamed: "down arrow")

    var orientationControlIsHidden: Bool = true {
        didSet {
            rotationSelectionNode.isHidden = orientationControlIsHidden
            flipSelectionNode.isHidden = orientationControlIsHidden
            dropSelectionNode.isHidden = orientationControlIsHidden
        }
    }
    
    func setup(rotationControlHandler: @escaping () -> Void, flipControlHandler: @escaping () -> Void, dropControlHandler: @escaping () -> Void) {
        self.nodeRotationHandler = rotationControlHandler
        self.nodeFlipHandler = flipControlHandler
        self.nodeDropHandler = dropControlHandler
        
        rotationSelectionNode = SKSpriteNode(texture: horizontalCircleTexture)
        rotationSelectionNode.position = CGPoint(x: frame.midX, y: 0.7 * frame.height)  // near top, center
        addChild(rotationSelectionNode)
        
        flipSelectionNode = SKSpriteNode(texture: verticalCircleTexture)
        flipSelectionNode.position = CGPoint(x: 0.65 * frame.width, y: 0.62 * frame.height)  // near top, right
        addChild(flipSelectionNode)
        
        dropSelectionNode = SKSpriteNode(texture: downArrowTexture)
        dropSelectionNode.position = CGPoint(x: frame.midX, y: 0.55 * frame.height)  // near top, left
        addChild(dropSelectionNode)
        
        orientationControlIsHidden = true
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first!
        let location = touch.location(in: self)
        if rotationSelectionNode.contains(location) {
            nodeRotationHandler?()
        }
        if flipSelectionNode.contains(location) {
            nodeFlipHandler?()
        }
        if dropSelectionNode.contains(location) {
            nodeDropHandler?()
        }
    }
}
