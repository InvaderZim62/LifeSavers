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
    
    var pastLocation = CGPoint.zero
    var deltaPanWorld = SCNVector3(0, 0, 0)
    var panningLifeSaverNode: LifeSaverNode?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupScene()
        setupCamera()
        setupView()
        createLifeSaverNodes()

        // add gestures to scnView
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        pan.maximumNumberOfTouches = 1
//        scnView.addGestureRecognizer(pan)
    }
    
    // space 12 life savers equal distances around an ellipse
    func createLifeSaverNodes() {
        let a = 1.3
        let b = 2.4
        let lifeSaverCount = 12
        let circumference = 1.85 * Double.pi * sqrt((a * a + b * b) / 2) // good approximation, if b < 3 * a
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
                let lifeSaverNode = LifeSaverNode()
                lifeSaverNode.position = SCNVector3(radius * cos(theta), radius * sin(theta), 0)
                lifeSaverNode.transform = SCNMatrix4Rotate(lifeSaverNode.transform, .pi / 2, 1, 0, 0)  // rotate perpendicular to screen, before spinning
                let spinAroundYAxis = SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: 2, z: 0, duration: 2))
                lifeSaverNode.runAction(spinAroundYAxis)
                scnScene.rootNode.addChildNode(lifeSaverNode)
                count += 1
                if count == lifeSaverCount { break }
                pastX = x
                pastY = y
            }
        }
    }
    
    // space 12 life savers at equal angles around an ellipse (equal distances between life savers would look better)
    func createLifeSaverNodes2() {
        let a = 1.2
        let b = 2.5
        let lifeSaverCount = 12
        for n in 0..<lifeSaverCount {
            let theta = Double(n) * 2 * Double.pi / Double(lifeSaverCount)
            let sinT2 = pow(sin(theta), 2)
            let cosT2 = pow(cos(theta), 2)
            let radius = a * b / sqrt(a * a * sinT2 + b * b * cosT2)
            let lifeSaverNode = LifeSaverNode()
            lifeSaverNode.position = SCNVector3(radius * cos(theta), radius * sin(theta), 0)
            lifeSaverNode.transform = SCNMatrix4Rotate(lifeSaverNode.transform, .pi / 2, 1, 0, 0)  // rotate perpendicular to screen, before spinning
            let spinAroundYAxis = SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: 2, z: 0, duration: 2))
            lifeSaverNode.runAction(spinAroundYAxis)
            scnScene.rootNode.addChildNode(lifeSaverNode)
        }
    }

    // MARK: - Gesture actions
    
    // if panning on a life saver node, move it with the pan gesture
    @objc func handlePan(recognizer: UIPanGestureRecognizer) {
        let location = recognizer.location(in: scnView)  // screen coordinates
        if let selectedLifeSaverNode = getLifeSaverNodeAt(location) {
            // pan started on a life saver node
            panningLifeSaverNode = selectedLifeSaverNode
        } else {
            // pan started off of a life saver node
            panningLifeSaverNode = nil
            return
        }
        if let panningLifeSaverNode = panningLifeSaverNode {
            // move panning life saver
            switch recognizer.state {
            case .changed:
                // move panningLifeSaverNode to pan location (moves in plane of surface being touched)
                if let lifeSaverCoordinates = getLifeSaverCoordinatesAt(location), let pastLifeSaverCoordinates = getLifeSaverCoordinatesAt(pastLocation) {
                    let deltaPanLocal = (lifeSaverCoordinates.local - pastLifeSaverCoordinates.local)
                    deltaPanWorld = lifeSaverCoordinates.world - pastLifeSaverCoordinates.world  // scene coordinates
                    panningLifeSaverNode.localTranslate(by: deltaPanLocal)  // contacts are prevented in render, below
                }
            default:
                break
            }
        }
        pastLocation = location
    }
    
    // get life saver node at location provided by tap gesture
    private func getLifeSaverNodeAt(_ location: CGPoint) -> LifeSaverNode? {
        var lifeSaverNode: LifeSaverNode?
        let hitResults = scnView.hitTest(location, options: nil)  // options: nil returns top-most hit
        if let result = hitResults.first(where: { $0.node.name == "Life Saver" }) {
            lifeSaverNode = result.node as? LifeSaverNode
        }
        return lifeSaverNode
    }

    // convert location from screen to local (lifeSaverNode) and world (scene) coordinates
    private func getLifeSaverCoordinatesAt(_ location: CGPoint) -> (local: SCNVector3, world: SCNVector3)? {
        var lifeSaverCoordinates: (SCNVector3, SCNVector3)?
        let hitResults = scnView.hitTest(location, options: [.searchMode: SCNHitTestSearchMode.all.rawValue])
        if let result = hitResults.first(where: { $0.node == panningLifeSaverNode }) {  // hit must be on panningLifeSaverNode
            lifeSaverCoordinates = (result.localCoordinates, result.worldCoordinates)
        }
        return lifeSaverCoordinates
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
        scnView.allowsCameraControl = true  // true: allow standard camera controls with swiping
        scnView.showsStatistics = true
        scnView.autoenablesDefaultLighting = true
        scnView.isPlaying = true  // prevent SceneKit from entering a "paused" state, if there isn't anything to animate
        scnView.scene = scnScene
    }
}
