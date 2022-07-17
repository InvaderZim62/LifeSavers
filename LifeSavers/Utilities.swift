//
//  Utilities.swift
//  LifeSavers
//
//  Created by Phil Stern on 2/22/20.
//  Copyright © 2020 Phil Stern. All rights reserved.
//

import Foundation
import SceneKit

func mod(_ a: Int, _ n: Int) -> Int {  // handles mod of negative numbers (a)
    let r = a % n
    return r >= 0 ? r : r + n
}

func +(lhs: SCNVector3, rhs: SCNVector3) -> SCNVector3 {
    return SCNVector3(lhs.x + rhs.x, lhs.y + rhs.y, lhs.z + rhs.z)
}

extension Float {
    var rads: CGFloat {
        return CGFloat(self) * CGFloat.pi / 180.0
    }
    
    // converts angle to 0 - 2 * pi
    var wrap2Pi: Float {
        var wrappedAngle = self
        if self >= 2 * .pi {
            wrappedAngle -= 2 * .pi
        } else if self < 0 {
            wrappedAngle += 2 * .pi
        }
        return wrappedAngle
    }
}
