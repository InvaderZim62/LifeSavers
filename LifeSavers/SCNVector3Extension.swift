//
//  SCNVector3Extension.swift
//  DominoDraw
//
//  Created by Phil Stern on 4/30/21.
//

import SceneKit

extension SCNVector3: CustomStringConvertible {
    public var description: String {
        String(format: "(x: %.3f, y: %.3f, z: %.3f)", x, y, z)
    }
    
    static func +(lhs: SCNVector3, rhs: SCNVector3) -> SCNVector3 {
        return SCNVector3(x: lhs.x + rhs.x, y: lhs.y + rhs.y, z: lhs.z + rhs.z)
    }
    
    static func -(lhs: SCNVector3, rhs: SCNVector3) -> SCNVector3 {
        return SCNVector3(x: lhs.x - rhs.x, y: lhs.y - rhs.y, z: lhs.z - rhs.z)
    }
    
    static func *(lhs: SCNVector3, rhs: Double) -> SCNVector3 {
        return SCNVector3(x: lhs.x * Float(rhs), y: lhs.y * Float(rhs), z: lhs.z * Float(rhs))
    }
    
    // dot product
    static func *(lhs: SCNVector3, rhs: SCNVector3) -> Float {
        return lhs.x * rhs.x + lhs.y * rhs.y + lhs.z * rhs.z
    }
    
    var magnitude: Float {
        return sqrt(x * x + y * y + z * z)
    }
    
    // if magnitude > mag, scale all vector elements to give magnitude = mag
    func limitMagnitude(to mag: Double) -> SCNVector3 {
        let scale = Float(mag) / magnitude
        if scale < 1 {
            return SCNVector3(x * scale, y * scale, z * scale)
        } else {
            return self
        }
    }
    
    func removeXZ() -> SCNVector3 {
        return SCNVector3(0, y, 0)
    }
    
    func removeAllButMax() -> SCNVector3 {
        let absX = abs(x)
        let absY = abs(y)
        let absZ = abs(z)
        if absX > absY && absX > absZ {
            return SCNVector3(x, 0, 0)
        } else if absY > absX && absY > absZ {
            return SCNVector3(0, y, 0)
        } else if absZ > absX && absZ > absY {
            return SCNVector3(0, 0, z)
        } else {
            return SCNVector3(0, 0, 0)
        }
    }

    func distance(from: SCNVector3) -> Float {
        return sqrt(pow(from.x - self.x, 2) + pow(from.y - self.y, 2) + pow(from.z - self.z, 2))
    }
    
    func bearing(from: SCNVector3) -> Double {
        let deltaLat = self.z - from.z
        let deltaLon = self.x - from.x
        return Double(atan2(-deltaLat, deltaLon))
    }
}
