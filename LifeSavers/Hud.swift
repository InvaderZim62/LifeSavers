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
        rotateSelectionNode.position = CGPoint(x: frame.midX, y: 0.73 * frame.height)  // near top, center
        addChild(rotateSelectionNode)
        
        flipSelectionNode = SKSpriteNode(texture: verticalCircleTexture)
        flipSelectionNode.position = CGPoint(x: 0.65 * frame.width, y: 0.65 * frame.height)  // near top, right
        addChild(flipSelectionNode)
        
        dropSelectionNode = SKSpriteNode(texture: downArrowTexture)
        dropSelectionNode.position = CGPoint(x: frame.midX, y: 0.58 * frame.height)  // near top, left
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
