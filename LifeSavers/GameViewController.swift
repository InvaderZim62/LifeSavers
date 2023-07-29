//
//  GameViewController.swift
//  LifeSavers
//
//  Created by Phil Stern on 6/26/22.
//
//  LifeSaverNodes use scenes created in Blender (see "art" folder).  They do not have physics bodies.
//  Logic is use to determine if LifeSaverNodes fit together, rather than "contacts" created by the
//  physics engine.
//
//  Importing model from Blender
//  ----------------------------
//  - Add "life saver 0.dae" to art folder
//  - Select the life saver in the Scene graph
//    - Material inspector | + | Shading: Lambert | Diffuse: pick a color (R: 255, G: 253, B: 216)
//    - Node inspector | Identity | Name: LifeSaver
//    - Editor (top menu) | Convert to SceneKit file format (.scn)
//    - Delete "life saver 0.dae" (blue wire-frame cube icon)
//
//  Blender axes     SceneKit axes
//   blue               green
//     z  y green         y
//     | /                |
//     |/___ x red        |___ x red
//                       /
//                      z blue
//

import UIKit
import QuartzCore
import SceneKit

struct Constants {
    static let lifeSaverCount = 12   // don't change this number
    static let lifeSaverWidth = 0.1  // in screen units
    static let cameraDistance = 5.0
    static let moveDuration = 0.3    // seconds
}

class GameViewController: UIViewController {
    
    var scnScene: SCNScene!
    var cameraNode: SCNNode!
    var scnView: SCNView!
    
    var hud = Hud()
    var lifeSaverNodes = [LifeSaverNode]()
    var startingPositions = [SCNVector3]()
    var stackPositions = [SCNVector3]()
    var holdingPosition = SCNVector3(0, 0.85, 0)
    var positionIndex = 0
    var pastAngle: Float = 0.0
    
    var stack: [LifeSaverNode] {
        lifeSaverNodes.filter { $0.isPlayed }.sorted(by: { $0.stackPosition < $1.stackPosition })
    }

    // move selected/tapped node to holding position, move all others back to starting position
    var selectedLifeSaverNode: LifeSaverNode? {
        didSet {
            hud.orientationControlIsHidden = selectedLifeSaverNode == nil
            moveUnplayedLifeSaversToStartingPositions()
            if let selectedLifeSaverNode = selectedLifeSaverNode {
                selectedLifeSaverNode.runAction(SCNAction.move(to: holdingPosition, duration: Constants.moveDuration))
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupScene()
        setupCamera()
        setupView()
        setupHud()
        computeStartingPositions()
        computeStackPositions()
        createLifeSaverNodes()

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        scnView.addGestureRecognizer(tap)
    }
    
    private func moveUnplayedLifeSaversToStartingPositions() {
        lifeSaverNodes.forEach {
            if !$0.isPlayed {
                $0.runAction(SCNAction.move(to: startingPositions[$0.number], duration: Constants.moveDuration))  // move unplayed nodes to start
            }
        }
    }
    
    private func createLifeSaverNodes() {
        for (index, startingPosition) in startingPositions.enumerated() {
            let lifeSaverNode = LifeSaverNode(number: index)
            lifeSaverNode.position = startingPosition
            lifeSaverNode.eulerAngles.y = [0, .pi / 2, .pi, 3 * .pi / 2].randomElement()!  // rotation around center hole
            lifeSaverNode.eulerAngles.x = [0, .pi].randomElement()!  // flip front or back up
            lifeSaverNodes.append(lifeSaverNode)
            scnScene.rootNode.addChildNode(lifeSaverNode)
        }
    }
    
    // MARK: - Orientation changes
    
    // called by touching hud upper circle-arrow
    private func rotateSelectedLifeSaver() {
        guard let selectedLifeSaverNode = selectedLifeSaverNode else { return }
        selectedLifeSaverNode.runAction(SCNAction.rotateBy(x: 0, y: .pi / 2, z: 0, duration: Constants.moveDuration)) {
            // state not changed until action complete
        }
    }
    
    // called by touching hud side circle-arrow
    private func flipSelectedLifeSaver() {
        guard let selectedLifeSaverNode = selectedLifeSaverNode else { return }
        selectedLifeSaverNode.runAction(SCNAction.rotateBy(x: .pi, y: 0, z: 0, duration: Constants.moveDuration)) {
        }
    }
    
    // called by touching hud down-arrow
    private func dropSelectedLifeSaver() {
        guard let selectedLifeSaverNode = selectedLifeSaverNode else { return }
        let gapSize = stackGap  // store it to avoid re-computing at each use
        selectedLifeSaverNode.runAction(SCNAction.move(to: stackPositions[positionIndex + gapSize], duration: Constants.moveDuration))
        selectedLifeSaverNode.isPlayed = true
        selectedLifeSaverNode.stackPosition = positionIndex + gapSize
        self.selectedLifeSaverNode = nil
        positionIndex += (1 + gapSize)
    }
    
    // determine number of stack spaces that will be left open if selected life saver is dropped
    // onto stack (due to pegs not aligning with holes, or holes not deep enough for long pegs)
    private var stackGap: Int {
        let currentStack = stack  // store it to avoid re-computing at each use
        guard currentStack.count > 0 else { return 0 }  // no gap for first life saver dropped onto stack
        
        let stackTop = currentStack[currentStack.count - 1]
        var maxGap = -2
        
        for selectedIndex in 0..<4 {
            let stackTopIndex = indexOnNode(stackTop, alignedWithNode: selectedLifeSaverNode!, atIndex: selectedIndex)
            let stackTopFeature = stackTop.upperFeatureAt(index: stackTopIndex)
            var stackTopPenetration = stackTopFeature.penetration
            if currentStack.count > 1 && stackTopFeature == .hole {
                // consider effect on penetration of second-from-top life saver, if top life saver has hole
                let secondFromTop = currentStack[currentStack.count - 2]
                let secondFromTopIndex = indexOnNode(secondFromTop, alignedWithNode: selectedLifeSaverNode!, atIndex: selectedIndex)
                let secondFromTopFeature = secondFromTop.upperFeatureAt(index: secondFromTopIndex)
                let secondFromTopPenetration = secondFromTopFeature.penetration
                stackTopPenetration = secondFromTopPenetration - 1
            }
            let selectedFeature = selectedLifeSaverNode!.lowerFeatureAt(index: selectedIndex)
            let gap = max(selectedFeature.penetration + stackTopPenetration, 0)
            if gap > maxGap {
                maxGap = gap
            }
        }
        return maxGap
    }
    
    // determine which index of node1 aligns with the provided index of node2, by first computing a unit
    // vector from the center of node2 to the index position, converting the vector to node1's frame (in
    // whatever orientation node1 may be), then computing the index position of that vector on node1
    private func indexOnNode(_ node1: LifeSaverNode, alignedWithNode node2: LifeSaverNode, atIndex: Int) -> Int {
        let vector2 = vectorFrom(index: atIndex)
        let vector = node2.convertVector(vector2, to: node1)
        return indexFrom(vector: vector)
    }

    // MARK: - Gesture actions

    // select/deselect life saver node (causing it to move back and forth from the holding position)
    @objc private func handleTap(recognizer: UITapGestureRecognizer) {
        let location = recognizer.location(in: scnView)
        if let tappedLifeSaver = getLifeSaverNodeAt(location) {
            if tappedLifeSaver == selectedLifeSaverNode {
                // deselect life saver if tapped while selected
                selectedLifeSaverNode = nil
            } else {
                // select life saver if not yet played or if top of stack
                if !tappedLifeSaver.isPlayed {
                    selectedLifeSaverNode = tappedLifeSaver
                } else if tappedLifeSaver.stackPosition == positionIndex - 1 {
                    tappedLifeSaver.isPlayed = false
                    positionIndex -= stack.count > 0 ? (tappedLifeSaver.stackPosition - stack.last!.stackPosition) : 1
                    selectedLifeSaverNode = tappedLifeSaver
                }
            }
        }
    }
    
    // get life saver node at location provided by tap gesture (nil if none tapped)
    private func getLifeSaverNodeAt(_ location: CGPoint) -> LifeSaverNode? {
        var lifeSaverNode: LifeSaverNode?
        let hitResults = scnView.hitTest(location, options: nil)  // nil returns closest hit
        if let result = hitResults.first(where: { $0.node.name == "Life Saver" }) {
            lifeSaverNode = result.node as? LifeSaverNode
        }
        return lifeSaverNode
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
        scnView.allowsCameraControl = true  // true: allow standard camera controls with swiping
        scnView.showsStatistics = true
        scnView.autoenablesDefaultLighting = true
        scnView.isPlaying = true  // prevent SceneKit from entering a "paused" state, if there isn't anything to animate
        scnView.scene = scnScene
    }

    private func setupHud() {
        hud = Hud(size: view.bounds.size)
        hud.setup(rotateControlHandler: rotateSelectedLifeSaver,
                  flipControlHandler: flipSelectedLifeSaver,
                  dropControlHandler: dropSelectedLifeSaver)
        scnView.overlaySKScene = hud
    }
    
    // MARK: - Utility functions
    
    // return unit vector along axis of index
    // (0 = -z axis, 1 = +x axis, 2 = +z axis, 3 = -x axis)
    private func vectorFrom(index: Int) -> SCNVector3 {
        let positionAngle = .pi / 2 * Float(index - 1)  // angle of index position (0 along x-axis, pos clockwise)
        return SCNVector3(cos(positionAngle), 0, sin(positionAngle))
    }
    
    private func indexFrom(vector: SCNVector3) -> Int {
        let positionAngle = atan2(vector.z, vector.x).wrap2Pi
        return Int(round(2 * positionAngle / .pi) + 1) % 4
    }

    private func computeStackPositions() {
        for n in 0..<Constants.lifeSaverCount {
            let y =  Constants.lifeSaverWidth * (Double(n - 4) - Double(Constants.lifeSaverCount - 1) / 2)
            stackPositions.append(SCNVector3(0, y, 0))
        }
    }

    // compute 12 equally-spaced (shuffled) positions around an ellipse
    private func computeStartingPositions() {
        let a = 1.0  // horizontal radius
        let b = 2.0  // vertical radius
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
        startingPositions.shuffle()
    }
}
