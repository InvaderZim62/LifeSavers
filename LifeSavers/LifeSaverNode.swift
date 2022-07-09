//
//  LifeSaverNode.swift
//  LifeSavers
//
//  Created by Phil Stern on 6/27/22.
//

import UIKit
import SceneKit

class LifeSaverNode: SCNNode {
    
    var number = 0
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    init(number: Int) {
        super.init()
        name = "Life Saver"
        self.number = number
        let scene = SCNScene(named: "art.scnassets/LifeSaver.scn")!
        let node = scene.rootNode.childNode(withName: "LifeSaver", recursively: true)!
        geometry = node.geometry
    }
}
