//
//  LifeSaverNode.swift
//  LifeSavers
//
//  Created by Phil Stern on 6/27/22.
//

import UIKit
import SceneKit
import SpriteKit

enum Position {
    case north
    case south
    case east
    case west
}

enum Feature {
    case hole
    case shortPeg
    case longPeg
    case none
}

class LifeSaverNode: SCNNode {
    
    override var description: String {
        "number: \(number), stackPosition: \(stackPosition), isPlayed: \(isPlayed), quarterTurns: \(quarterTurns), isFlipped: \(isFlipped)"
    }

    var number = 0
    var stackPosition = 0
    var isPlayed = false
    var front = [Feature]()  // north, east, south, west side
    var back = [Feature]()
    
    var quarterTurns: Int {
        Int((eulerAngles.y / (.pi / 2)).rounded()) % 4  // positive: counter-clockwise from front, clockwise from back
    }
    
    var isFlipped: Bool {
        Int((eulerAngles.x / .pi).rounded()) % 2 == 1
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    init(number: Int) {
        super.init()
        name = "Life Saver"
        self.number = number
        let fileName = "art.scnassets/life saver " + String(number) + ".scn"  // ex. art.scnassets/life saver 7.scn"
        let scene = SCNScene(named: fileName)!
        let node = scene.rootNode.childNode(withName: "LifeSaver", recursively: true)!
        geometry = node.geometry
        switch number {
        case 0:
            front = [.hole, .none, .none, .longPeg]
            back = [.none, .none, .none, .none]
        case 1:
            front = [.none, .none, .hole, .hole]
            back = [.shortPeg, .none, .hole, .hole]
        case 2:
            front = [.none, .hole, .shortPeg, .hole]
            back = [.none, .hole, .shortPeg, .hole]
        case 3:
            front = [.none, .hole, .hole, .shortPeg]
            back = [.none, .hole, .hole, .none]
        case 4:
            front = [.hole, .shortPeg, .none, .hole]
            back = [.hole, .longPeg, .none, .hole]
        case 5:
            front = [.longPeg, .hole, .hole, .none]
            back = [.shortPeg, .hole, .hole, .none]
        case 6:
            front = [.hole, .longPeg, .none, .none]
            back = [.hole, .none, .shortPeg, .none]
        case 7:
            front = [.hole, .hole, .none, .hole]
            back = [.hole, .hole, .none, .hole]
        case 8:
            front = [.none, .hole, .hole, .shortPeg]
            back = [.none, .hole, .hole, .shortPeg]
        case 9:
            front = [.shortPeg, .hole, .none, .hole]
            back = [.none, .hole, .shortPeg, .hole]
        case 10:
            front = [.hole, .hole, .shortPeg, .none]
            back = [.hole, .hole, .none, .none]
        case 11:
            front = [.none, .none, .hole, .none]
            back = [.none, .longPeg, .hole, .none]
        default:
            break
        }
//        addLabel(text: String(number))  // use for debugging
    }

    // add text to top of face of life saver
    // label position was set by trial and error (starting with very large font), since surface is wrapped around whole shape
    // from: https://stackoverflow.com/questions/49600303 (also see roulette)
    private func addLabel(text: String) {
        let size = 300.0  // bigger gives higher resolution (smaller font size)
        let scene = SKScene(size: CGSize(width: size, height: size))

        let rectangle = SKShapeNode(rect: CGRect(x: 0, y: 0, width: size, height: size), cornerRadius: 0)
        rectangle.fillColor = UIColor.white

        let label = SKLabelNode(text: text)
        label.fontSize = 18
        label.numberOfLines = 0
        label.fontColor = UIColor.black
        label.fontName = "Helvetica-Bold"
        label.position = CGPoint(x: 0.25 * size, y: 0.43 * size)  // origin at bottom left corner (x pos right, y pos up)
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .center

        scene.addChild(rectangle)
        scene.addChild(label)

        let material = SCNMaterial()
        material.diffuse.contents = scene
        geometry?.materials = [material]
        geometry?.firstMaterial?.diffuse.contentsTransform = SCNMatrix4Translate(SCNMatrix4MakeScale(1, -1, 1), 0, 1, 0)
    }
}
