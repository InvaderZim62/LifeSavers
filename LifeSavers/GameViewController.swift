//
//  GameViewController.swift
//  LifeSavers
//
//  Created by Phil Stern on 6/26/22.
//
//  To do...
//  - shuffle lifeSaverNodes array
//  - arbitrarily rotate lifeSaverNodes about z-axis (default gives away part of puzzle solution)
//

import UIKit
import QuartzCore
import SceneKit

struct Constants {
    static let lifeSaverCount = 12         // don't change this number
    static let cameraDistance: Float = 6
    static let tapZoomFactor: Float = 0.9  // percent of distance to camera offset a node moves when tapped
    static let tapZoomOffset: Float = 2    // distance in front of camera a node moves toward when tapped
    static let moveDuration = 0.3          // seconds
}

class GameViewController: UIViewController {
    
    var scnScene: SCNScene!
    var cameraNode: SCNNode!
    var scnView: SCNView!
    
    var lifeSaverNodes = [LifeSaverNode]()
    var startingPositions = [SCNVector3]()
    var pastAngle: Float = 0.0
    
    // move selected node closer to camera, move all others back (animated)
    var selectedLifeSaverNode: LifeSaverNode? {
        didSet {
            lifeSaverNodes.forEach { $0.runAction(SCNAction.move(to: startingPositions[$0.number], duration: Constants.moveDuration)) }  // move all nodes back
            if let selectedLifeSaverNode = selectedLifeSaverNode {
                let startingPosition = startingPositions[selectedLifeSaverNode.number]
                let forwardPosition = SCNVector3(startingPosition.x * (1 - Constants.tapZoomFactor),
                                                 startingPosition.y * (1 - Constants.tapZoomFactor),
                                                 (Constants.cameraDistance - Constants.tapZoomOffset) * Constants.tapZoomFactor)
                selectedLifeSaverNode.runAction(SCNAction.move(to: forwardPosition, duration: Constants.moveDuration))
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupScene()
        setupCamera()
        setupView()
        computeStartingPositions()
        createLifeSaverNodes()

        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        scnView.addGestureRecognizer(pan)
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        scnView.addGestureRecognizer(tap)
    }
    
    // compute 12 equally-spaced positions around an ellipse
    func computeStartingPositions() {
        let a = 1.3  // horizontal radius
        let b = 2.4  // vertical radius
        let circumference = 1.85 * Double.pi * sqrt((a * a + b * b) / 2) // reasonable approximation (no exact solution)
        // Note: will have less than 12 life savers, if circumference is over-estimated
        let desiredSpacing = circumference / Double(Constants.lifeSaverCount)
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
                startingPositions.append(SCNVector3(radius * cos(theta), radius * sin(theta), 0))
                count += 1
                if count == Constants.lifeSaverCount { break }
                pastX = x
                pastY = y
            }
        }
    }
    
    func createLifeSaverNodes() {
        for (index, startingPosition) in startingPositions.enumerated() {
            let lifeSaverNode = LifeSaverNode(number: index)
            lifeSaverNode.position = startingPosition
            lifeSaverNode.transform = SCNMatrix4Rotate(lifeSaverNode.transform, .pi / 2, 1, 0, 0)  // rotate perpendicular to screen, before spinning
            lifeSaverNodes.append(lifeSaverNode)
            scnScene.rootNode.addChildNode(lifeSaverNode)
        }
    }
    
    // MARK: - Gesture actions

    // select/deselect domino node
    @objc func handleTap(recognizer: UITapGestureRecognizer) {  // Note: panning always starts with a tap
        let location = recognizer.location(in: scnView)
        if let tappedLifeSaver = getLifeSaverNodeAt(location) {
            if tappedLifeSaver == selectedLifeSaverNode {
                selectedLifeSaverNode = nil
            } else {
                selectedLifeSaverNode = tappedLifeSaver
            }
        } else {
            selectedLifeSaverNode = nil
        }
    }
    
    // get life saver node at location provided by tap gesture
    private func getLifeSaverNodeAt(_ location: CGPoint) -> LifeSaverNode? {
        var lifeSaverNode: LifeSaverNode?
        let hitResults = scnView.hitTest(location, options: nil)  // nil returns closest hit
        if let result = hitResults.first(where: { $0.node.name == "Life Saver" }) {
            lifeSaverNode = result.node as? LifeSaverNode
        }
        return lifeSaverNode
    }

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
        cameraNode.position = SCNVector3(0, 0, Constants.cameraDistance)
        scnScene.rootNode.addChildNode(cameraNode)
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
