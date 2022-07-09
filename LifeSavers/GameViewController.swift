//
//  GameViewController.swift
//  LifeSavers
//
//  Created by Phil Stern on 6/26/22.
//

import UIKit
import QuartzCore
import SceneKit

class GameViewController: UIViewController {
    
    var scnScene: SCNScene!
    var cameraNode: SCNNode!
    var scnView: SCNView!
    
    var lifeSaverNodes = [LifeSaverNode]()
    var pastAngle: Float = 0.0

    override func viewDidLoad() {
        super.viewDidLoad()
        setupScene()
        setupCamera()
        setupView()
        createLifeSaverNodes()

        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        scnView.addGestureRecognizer(pan)
    }
    
    // equally space 12 life savers around an ellipse
    func createLifeSaverNodes() {
        let a = 1.3
        let b = 2.4
        let lifeSaverCount = 12
        let circumference = 1.85 * Double.pi * sqrt((a * a + b * b) / 2) // reasonable approximation (no exact solution)
        let desiredSpacing = circumference / Double(lifeSaverCount)
        let testCount = 200
        var pastX = 10.0
        var pastY = 10.0
        var count = 0
        for n in 0..<testCount {
            let theta = Double(n) * 2 * Double.pi / Double(testCount)
            let sinT2 = pow(sin(theta), 2)
            let cosT2 = pow(cos(theta), 2)
            let radius = a * b / sqrt(a * a * sinT2 + b * b * cosT2)
            let x = radius * cos(theta)
            let y = radius * sin(theta)
            let spacing = sqrt(pow((x - pastX), 2) + pow(y - pastY, 2))
            if spacing > desiredSpacing {
                let lifeSaverNode = LifeSaverNode(number: count)
                lifeSaverNode.position = SCNVector3(radius * cos(theta), radius * sin(theta), 0)
                lifeSaverNode.transform = SCNMatrix4Rotate(lifeSaverNode.transform, .pi / 2, 1, 0, 0)  // rotate perpendicular to screen, before spinning
                lifeSaverNodes.append(lifeSaverNode)
                scnScene.rootNode.addChildNode(lifeSaverNode)
                count += 1
                if count == lifeSaverCount { break }
                pastX = x
                pastY = y
            }
        }
    }

    // MARK: - Gesture actions
    
    // rotate all life savers, if panning screen
    @objc func handlePan(recognizer: UIPanGestureRecognizer) {
        switch recognizer.state {
        case .changed:
            let location = recognizer.translation(in: recognizer.view)
            let angle = Float(location.x) / 70  // scale screen coordinates to give good rotation rate
            lifeSaverNodes.forEach { $0.eulerAngles.y = pastAngle + angle }
        case .ended, .cancelled:
            pastAngle = lifeSaverNodes[0].eulerAngles.y  // just use [0], since all nodes rotate together
        default:
            break
        }
    }

    // MARK: - Setup functions
    
    private func setupScene() {
        scnScene = SCNScene()
        scnScene.background.contents = "Background_Diffuse.png"
    }
    
    private func setupCamera() {
        cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
//        rotateCameraAroundBoardCenter(deltaAngle: -.pi/4)  // move up 45 deg (looking down)
        rotateCameraAroundBoardCenter(deltaAngle: 0)  // look at front
        scnScene.rootNode.addChildNode(cameraNode)
    }

    // rotate camera around scene x-axis, while continuing to point at scene center
    private func rotateCameraAroundBoardCenter(deltaAngle: CGFloat) {
        cameraNode.transform = SCNMatrix4Rotate(cameraNode.transform, Float(deltaAngle), 1, 0, 0)
        let cameraAngle = CGFloat(cameraNode.eulerAngles.x)
        let cameraDistance = CGFloat(6)
        cameraNode.position = SCNVector3(0, -cameraDistance * sin(cameraAngle), cameraDistance * cos(cameraAngle))
    }

    private func setupView() {
        scnView = self.view as? SCNView
        scnView.allowsCameraControl = false  // true: allow standard camera controls with swiping
        scnView.showsStatistics = true
        scnView.autoenablesDefaultLighting = true
        scnView.isPlaying = true  // prevent SceneKit from entering a "paused" state, if there isn't anything to animate
        scnView.scene = scnScene
    }
}
