//
//  LifeSaverNode.swift
//  LifeSavers
//
//  Created by Phil Stern on 6/27/22.
//

import UIKit
import SceneKit

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
    
    var number = 0
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
    }
}
