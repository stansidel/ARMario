//
//  ViewController.swift
//  ARMario
//
//  Created by Roman Sentsov on 16.02.2018.
//  Copyright © 2018 Roman Sentsov. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet private weak var joystickView: JoyStickView!
    @IBOutlet private weak var jumpButtonView: UIView!
    
    @IBOutlet private weak var resetButton: UIButton!
    @IBOutlet private weak var keepButton: UIButton!
    
    var sessionConfig = ARWorldTrackingConfiguration()
    private weak var marioNode: SCNNode?
    private var positionManager: NodePositionManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
    }
    
    private func configure() {
        joystickView.movable = false
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Tell the session to automatically detect horizontal planes
        sessionConfig.planeDetection = .horizontal

        // Run the view's session
        sceneView.session.run(sessionConfig)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    @IBAction func jumpClicked(_ sender: Any) {
        print("Jump!")
    }
    
    func createPlaneNode(anchor: ARPlaneAnchor) -> SCNNode {
        // Create a SceneKit plane to visualize the node using its position and extent.
        // Create the geometry and its materials
        let plane = SCNPlane(width: CGFloat(anchor.extent.x), height: CGFloat(anchor.extent.z))
        
        let planeImage = UIImage(named: "plane.png")
        let planeMaterial = SCNMaterial()
        planeMaterial.diffuse.contents = planeImage
        planeMaterial.isDoubleSided = true
        
        plane.materials = [planeMaterial]
        
        // Create a node with the plane geometry we created
        let planeNode = SCNNode(geometry: plane)
        planeNode.position = SCNVector3Make(anchor.center.x, 0, anchor.center.z)
        
        // SCNPlanes are vertically oriented in their local coordinate space.
        // Rotate it to match the horizontal orientation of the ARPlaneAnchor.
        planeNode.transform = SCNMatrix4MakeRotation(-Float.pi / 2, 1, 0, 0)
        
        DispatchQueue.main.async {
            self.keepButton.isHidden = false
            self.resetButton.isHidden = false
        }
        
        return planeNode
    }
    // MARK: - ARSCNViewDelegate
    
    // When a plane is detected, make a planeNode for it
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if marioNode != nil { return }
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        
        sceneView.scene.rootNode.enumerateChildNodes { (node1, stop) in
            if node1 != node {
                node1.removeFromParentNode()
            }
        }
        // Remove existing plane nodes
        node.enumerateChildNodes {
            (childNode, _) in
            childNode.removeFromParentNode()
        }
        let planeNode = createPlaneNode(anchor: planeAnchor)
        // ARKit owns the node corresponding to the anchor, so make the plane a child node.
        node.addChildNode(planeNode)
    }
    
    // When a detected plane is removed, remove the planeNode
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        guard anchor is ARPlaneAnchor else { return }
        
        // Remove existing plane nodes
        node.enumerateChildNodes {
            (childNode, _) in
            childNode.removeFromParentNode()
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        guard let cameraAngle = sceneView.session.currentFrame?.camera.eulerAngles.y else { return }
        
        print("Camera angle: \(cameraAngle)")
        
        if joystickView.displacement.isZero { return }
        
        let radAngle = joystickView.angle * .pi / 180
        marioNode?.position = positionManager.updatePositionFor(angle: radAngle + CGFloat(cameraAngle),
                                                                displacement: joystickView.displacement)
        
        marioNode?.eulerAngles = SCNVector3(0, -radAngle + (CGFloat.pi / 2), 0)
    }

    @IBAction func resetClicked(_ sender: Any) {
        sceneView.scene.rootNode.enumerateChildNodes { (node, stop) in
            node.removeFromParentNode()
        }
        // Create a session configuration
        sessionConfig.planeDetection = .horizontal
        sceneView.session.run(sessionConfig, options: [.resetTracking, .removeExistingAnchors])
        keepButton.isHidden = true
        resetButton.isHidden = true
        joystickView.isHidden = true
        jumpButtonView.isHidden = true
    }
    
    @IBAction func keepClicked(_ sender: Any) {
        guard let firstNode = sceneView.scene.rootNode.childNodes.first else { return }
        
        //let hero = Hero(named: "Bob.dae")!
        let hero = Hero(named: "art.scnassets/panda.scn")!
        hero.position = SCNVector3Make(firstNode.position.x, firstNode.position.y, firstNode.position.z)
        sceneView.scene.rootNode.addChildNode(hero)
        firstNode.removeFromParentNode()
        marioNode = hero
        positionManager = NodePositionManager(position: hero.position)
        
        keepButton.isHidden = true
        joystickView.isHidden = false
        jumpButtonView.isHidden = false
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}
