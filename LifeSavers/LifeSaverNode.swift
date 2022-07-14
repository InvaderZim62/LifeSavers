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
    case hole(Position)
    case shortPegFront(Position)
    case shortPegBack(Position)
    case longPegFront(Position)
    case longPegBack(Position)
}

class LifeSaverNode: SCNNode {
    
    var number = 0  // pws: may not need to save number
    var isPlayed = false
    var stackPosition = 0
    var features = [Feature]()
    
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
            features = [.hole(.north), .longPegFront(.west)]
        case 1:
            features = [.hole(.south), .hole(.west), .shortPegBack(.north)]
        case 2:
            features = [.hole(.east), .hole(.west), .shortPegFront(.south), .shortPegBack(.south)]
        case 3:
            features = [.hole(.east), .hole(.south), .shortPegFront(.west)]
        case 4:
            features = [.hole(.north), .hole(.west), .shortPegFront(.east), .longPegBack(.east)]
        case 5:
            features = [.hole(.east), .hole(.south), .longPegFront(.north), .shortPegBack(.north)]
        case 6:
            features = [.hole(.north), .longPegFront(.east), .shortPegBack(.south)]
        case 7:
            features = [.hole(.north), .hole(.east), .hole(.west)]
        case 8:
            features = [.hole(.east), .hole(.south), .shortPegFront(.west), .shortPegBack(.west)]
        case 9:
            features = [.hole(.east), .hole(.west), .shortPegFront(.north), .shortPegBack(.south)]
        case 10:
            features = [.hole(.north), .hole(.east), .shortPegFront(.south)]
        case 11:
            features = [.hole(.south), .longPegBack(.east)]
        default:
            break
        }
        addLabel(text: String(number))
    }

    // from: https://stackoverflow.com/questions/49600303 (also see roulette)
    // label position was set by trial and error (starting with very large font), since surface is wrapped around whole shape
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
