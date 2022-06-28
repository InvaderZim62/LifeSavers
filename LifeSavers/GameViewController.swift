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

        // add gestures to scnView
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        pan.maximumNumberOfTouches = 1  // prevents panning during rotation
        scnView.addGestureRecognizer(pan)

        let lifeSaverNode1 = LifeSaverNode()
        lifeSaverNode1.position = SCNVector3(0, 0.5, 0)
        scnScene.rootNode.addChildNode(lifeSaverNode1)
        
        let lifeSaverNode2 = LifeSaverNode()
        lifeSaverNode2.position = SCNVector3(0, -0.5, 0)
        scnScene.rootNode.addChildNode(lifeSaverNode2)
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
        rotateCameraAroundBoardCenter(deltaAngle: 0)  // move up 45 deg (looking down)
        scnScene.rootNode.addChildNode(cameraNode)
    }

    // rotate camera around scene x-axis, while continuing to point at scene center
    private func rotateCameraAroundBoardCenter(deltaAngle: CGFloat) {
        cameraNode.transform = SCNMatrix4Rotate(cameraNode.transform, Float(deltaAngle), 1, 0, 0)
        let cameraAngle = CGFloat(cameraNode.eulerAngles.x)
        let cameraDistance = CGFloat(3)
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
