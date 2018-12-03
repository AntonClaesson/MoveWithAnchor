//
//  ViewController.swift
//  moveWithAnchor
//
//  Created by Innotact Software on 2018-12-03.
//  Copyright © 2018 Innotact Software. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
    enum BodyType : Int {
        case ObjectModel = 2;
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        self.sceneView.session.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        sceneView.debugOptions = [.showFeaturePoints]
        
        registerGestureRecognizers()
        
    
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    private func registerGestureRecognizers(){
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapped))
        self.sceneView.addGestureRecognizer(tapGestureRecognizer)
        
        let moveGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(moved))
        self.sceneView.addGestureRecognizer(moveGestureRecognizer)
    }
    
    
    @objc func tapped(recognizer: UITapGestureRecognizer) {
        guard let scene = recognizer.view as? ARSCNView else {return}
        
        let touch = recognizer.location(in: scene)
        guard let hitTestResult = scene.hitTest(touch, types: .existingPlane).first else { return }

        let boxAnchor = ARAnchor(name:"box", transform: hitTestResult.worldTransform)
        self.sceneView.session.add(anchor: boxAnchor)
        
    }
    
    
    @objc func moved(recognizer :UILongPressGestureRecognizer) {
        guard let recognizerView = recognizer.view as? ARSCNView else { return }
        
        let touch = recognizer.location(in: recognizerView)
        
        let hitTestResult = self.sceneView.hitTest(touch, options: [SCNHitTestOption.categoryBitMask: BodyType.ObjectModel.rawValue])
        guard let modelNodeHit = hitTestResult.first?.node else { return }
        var planeHit : ARHitTestResult!
        
        if recognizer.state == .changed {
            
            let hitTestPlane = self.sceneView.hitTest(touch, types: .existingPlane)
            guard hitTestPlane.first != nil else { return }
            planeHit = hitTestPlane.first!
            modelNodeHit.position = SCNVector3(planeHit.worldTransform.columns.3.x,modelNodeHit.position.y,planeHit.worldTransform.columns.3.z)
                //print(sceneView.anchor(for: modelNodeHit)?.name)
                //print(sceneView.anchor(for: modelNodeHit)?.transform.columns.3)
        
        }else if recognizer.state == .ended || recognizer.state == .cancelled || recognizer.state == .failed{
            
            guard let oldAnchor = sceneView.anchor(for: modelNodeHit) else { return }
            let newAnchor = ARAnchor(name: oldAnchor.name!, transform: modelNodeHit.simdTransform )
            print(oldAnchor.transform.columns.3)        // old position
            sceneView.session.remove(anchor: oldAnchor)
            sceneView.session.add(anchor: newAnchor)
            print(newAnchor.transform.columns.3)        // updated position

        }
    }
    
    
    
    // MARK: - ARSCNViewDelegate
    

    // Override to create and configure nodes for anchors added to the view's session.
    // Called whenever a new anchor is created and returns a new node associated with that specific anchor.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        // Execute the correct code depending on the name of the newly created anchor.
        // Add more if statesments for new models eg. if(anchor.name == "house")...
        if(anchor.name == "box"){
            let box = SCNBox(width: 0.2, height: 0.2, length: 0.2, chamferRadius: 0)
            let material = SCNMaterial()
            material.diffuse.contents = UIColor.blue
            box.materials=[material]
            
            let boxNode = SCNNode(geometry: box)
            boxNode.categoryBitMask = BodyType.ObjectModel.rawValue
            
            return boxNode
        }
        return SCNNode()
    }

    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if anchor is ARPlaneAnchor {
            print("plane detected")
        }
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
