//
//  GameViewController.swift
//  LifeSavers
//
//  Created by Phil Stern on 6/26/22.
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
            lifeSaverNode.eulerAngles.y = [0, .pi / 2, .pi, 3 * .pi / 2].randomElement()!
            lifeSaverNode.eulerAngles.x = [0, .pi].randomElement()!
            lifeSaverNodes.append(lifeSaverNode)
            scnScene.rootNode.addChildNode(lifeSaverNode)
        }
    }
    
    // MARK: - Orientation changes
    
    private func rotateSelectedLifeSaver() {
        if let selectedLifeSaverNode = selectedLifeSaverNode {
            selectedLifeSaverNode.runAction(SCNAction.rotateBy(x: 0, y: .pi / 2, z: 0, duration: Constants.moveDuration)) {
                // state not changed until action complete
            }
        }
    }
    
    private func flipSelectedLifeSaver() {
        if let selectedLifeSaverNode = selectedLifeSaverNode {
            selectedLifeSaverNode.runAction(SCNAction.rotateBy(x: .pi, y: 0, z: 0, duration: Constants.moveDuration)) {
            }
        }
    }
    
    private func dropSelectedLifeSaver() {
        scnView.gestureRecognizers?.forEach { $0.isEnabled = false }  // temporarily disable gestures, to prevent simultaneous drop and tap (return to holding)
        if let selectedLifeSaverNode = selectedLifeSaverNode {
            let gapSize = stackGap  // store it to avoid re-computing at each use
            selectedLifeSaverNode.runAction(SCNAction.move(to: stackPositions[positionIndex + gapSize], duration: Constants.moveDuration))
            selectedLifeSaverNode.isPlayed = true
            selectedLifeSaverNode.stackPosition = positionIndex + gapSize
            self.selectedLifeSaverNode = nil
            positionIndex += (1 + gapSize)
        }
        scnView.gestureRecognizers?.forEach { $0.isEnabled = true }
    }
    
    // determine number of stack spaces that will be left open if selected
    // life saver is dropped onto stack (due to pegs not aligning with holes)
    private var stackGap: Int {
        var gapSize = 0
        if stack.count > 0 {
            let stackTop = stack.last!
            // check if pegs on bottom of selected life saver fit holes in top of stack
            if let selectShortPegIndex = selectedLifeSaverNode!.isFlipped ? selectedLifeSaverNode!.front.firstIndex(of: .shortPeg) : selectedLifeSaverNode!.back.firstIndex(of: .shortPeg) {
                let stackIndex = indexOnNode(stackTop, alignedWithNode: selectedLifeSaverNode!, atIndex: selectShortPegIndex)
                if stackTop.front[stackIndex] != .hole {
                    gapSize += 1
                }
            } else if let selectLongPegIndex = selectedLifeSaverNode!.isFlipped ? selectedLifeSaverNode!.front.firstIndex(of: .longPeg) : selectedLifeSaverNode!.back.firstIndex(of: .longPeg) {
                let stackIndex = indexOnNode(stackTop, alignedWithNode: selectedLifeSaverNode!, atIndex: selectLongPegIndex)
                if stackTop.front[stackIndex] != .hole {
                    gapSize += 1
                } else if stack.count > 1 {
                    // check if long peg fits hole in second-from-top of stack
                    let secondFromTop = stack[stack.count - 2]
                    let stackIndex = indexOnNode(secondFromTop, alignedWithNode: selectedLifeSaverNode!, atIndex: selectLongPegIndex)
                    if secondFromTop.front[stackIndex] != .hole {
                        gapSize += 1
                    }
                }
            }
            if gapSize > 0 { return gapSize }
            
            // check if pegs on top of stack fit holes in selected life saver
            if let stackShortPegIndex = stackTop.isFlipped ? stackTop.back.firstIndex(of: .shortPeg) : stackTop.front.firstIndex(of: .shortPeg) {
                let selectIndex = indexOnNode(selectedLifeSaverNode!, alignedWithNode: stackTop, atIndex: stackShortPegIndex)
                if selectedLifeSaverNode!.front[selectIndex] != .hole {
                    gapSize += 1
                }
            } else if let stackLongPegIndex = stackTop.isFlipped ? stackTop.back.firstIndex(of: .longPeg) : stackTop.front.firstIndex(of: .longPeg) {
                let selectIndex = indexOnNode(selectedLifeSaverNode!, alignedWithNode: stackTop, atIndex: stackLongPegIndex)
                if selectedLifeSaverNode!.front[selectIndex] != .hole {
                    gapSize += 1
                }
            }
        }
        return gapSize
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
