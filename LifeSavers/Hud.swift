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
    var rotationSelectionNode = SKSpriteNode()
    let whiteArrowTexture = SKTexture(imageNamed: "turn arrow")
    
    var rotationalControlIsHidden: Bool = true {
        didSet {
            rotationSelectionNode.isHidden = rotationalControlIsHidden
        }
    }
    
    func setup(rotationControlHandler: @escaping () -> Void) {
        self.nodeRotationHandler = rotationControlHandler
        rotationSelectionNode = SKSpriteNode(texture: whiteArrowTexture)
        rotationSelectionNode.position = CGPoint(x: frame.midX, y: 0.7 * frame.height)  // near top center
        addChild(rotationSelectionNode)
        rotationalControlIsHidden = true
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first!
        let location = touch.location(in: self)
        if rotationSelectionNode.contains(location) {
            nodeRotationHandler?()
        }
    }
}
