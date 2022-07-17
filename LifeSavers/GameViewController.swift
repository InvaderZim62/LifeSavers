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
    var playedCount = 0
    var pastAngle: Float = 0.0
    
    // move selected/tapped node to holding position, move all others back to starting position
    var selectedLifeSaverNode: LifeSaverNode? {
        didSet {
            hud.orientationControlIsHidden = selectedLifeSaverNode == nil
            moveUnplayedLifeSaversToStartingPositions()
            if let selectedLifeSaverNode = selectedLifeSaverNode {
                selectedLifeSaverNode.runAction(SCNAction.move(to: holdingPosition, duration: Constants.moveDuration))
                canDrop()
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
            lifeSaverNodes.append(lifeSaverNode)
            scnScene.rootNode.addChildNode(lifeSaverNode)
        }
    }
    
    // MARK: - Orientation changes
    
    private func rotateSelectedLifeSaver() {
        if let selectedLifeSaverNode = selectedLifeSaverNode {
            selectedLifeSaverNode.runAction(SCNAction.rotateBy(x: 0, y: .pi / 2, z: 0, duration: Constants.moveDuration)) {
                // state not changed until action complete
                self.canDrop()
            }
        }
    }
    
    private func flipSelectedLifeSaver() {
        if let selectedLifeSaverNode = selectedLifeSaverNode {
            selectedLifeSaverNode.runAction(SCNAction.rotateBy(x: .pi, y: 0, z: 0, duration: Constants.moveDuration)) {
                self.canDrop()
            }
        }
    }
    
    private func dropSelectedLifeSaver() {
        if let selectedLifeSaverNode = selectedLifeSaverNode {
            selectedLifeSaverNode.runAction(SCNAction.move(to: stackPositions[playedCount], duration: Constants.moveDuration))
            selectedLifeSaverNode.isPlayed = true
            selectedLifeSaverNode.stackPosition = playedCount
            self.selectedLifeSaverNode = nil
            playedCount += 1
        }
    }
    
    var stack: [LifeSaverNode] {
        lifeSaverNodes.filter { $0.isPlayed }.sorted(by: { $0.stackPosition < $1.stackPosition })
    }
    
    private func canDrop() {
        var canDrop = true
        if stack.count > 0 {
            let stackTop = stack.last!
//            print()
//            print("selected: \(selectedLifeSaverNode!)")
//            print("          \(selectedLifeSaverNode!.eulerAngles)")
//            print("stackTop: \(stackTop)")
//            print("          \(stackTop.eulerAngles)")
            
            // check if pegs on bottom of selected life saver fit holes in top of stack
            if let selectShortPegIndex = selectedLifeSaverNode!.isFlipped ? selectedLifeSaverNode!.front.firstIndex(of: .shortPeg) : selectedLifeSaverNode!.back.firstIndex(of: .shortPeg) {
                let stackIndex = indexOn(node: stackTop, alignedWith: selectedLifeSaverNode!, index: selectShortPegIndex)
                if stackTop.front[stackIndex] != .hole {
                    canDrop = false
                }
            }
            if let selectLongPegIndex = selectedLifeSaverNode!.isFlipped ? selectedLifeSaverNode!.front.firstIndex(of: .longPeg) : selectedLifeSaverNode!.back.firstIndex(of: .longPeg) {
                let stackIndex = indexOn(node: stackTop, alignedWith: selectedLifeSaverNode!, index: selectLongPegIndex)
                if stackTop.front[stackIndex] != .hole {
                    canDrop = false
                }
            }
            // check if pegs on top of stack fit holes in selected life saver
            if let stackShortPegIndex = stackTop.isFlipped ? stackTop.back.firstIndex(of: .shortPeg) : stackTop.front.firstIndex(of: .shortPeg) {
                let selectIndex = indexOn(node: selectedLifeSaverNode!, alignedWith: stackTop, index: stackShortPegIndex)
                if selectedLifeSaverNode!.front[selectIndex] != .hole {
                    canDrop = false
                }
            }
            if let stackLongPegIndex = stackTop.isFlipped ? stackTop.back.firstIndex(of: .longPeg) : stackTop.front.firstIndex(of: .longPeg) {
                let selectIndex = indexOn(node: selectedLifeSaverNode!, alignedWith: stackTop, index: stackLongPegIndex)
                if selectedLifeSaverNode!.front[selectIndex] != .hole {
                    canDrop = false
                }
            }
        }
        print("can drop: \(canDrop)")
    }
    
    private func indexOn(node: LifeSaverNode, alignedWith node2: LifeSaverNode, index: Int) -> Int {
        let vector2 = vectorFrom(index: index)
        let vector = node2.convertVector(vector2, to: node)
        return indexFrom(vector: vector)
    }

    // MARK: - Gesture actions

    // select/deselect life saver node (causes it to move closer to camera)
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
                } else if tappedLifeSaver.stackPosition == playedCount - 1 {
                    tappedLifeSaver.isPlayed = false
                    playedCount -= 1
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

    // rotate all life savers, if panning screen
    @objc private func handlePan(recognizer: UIPanGestureRecognizer) {
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

    // compute 12 equally-spaced positions around an ellipse
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
    }
}
