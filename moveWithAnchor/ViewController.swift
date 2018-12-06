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
    
    var chairNode: SCNNode!
    var chairID = "chair"
    
    var boxNode: SCNNode!
    var boxID = "box"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        self.sceneView.session.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        sceneView.debugOptions = [.showFeaturePoints]
        
        registerGestureRecognizers()
        initModels()
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
    
    private func initModels(){
        let chairModelScene = SCNScene(named:
            "art.scnassets/chair/chair.scn")!
        chairNode =  chairModelScene.rootNode.childNode(
            withName: chairID, recursively: true)
        chairNode.enumerateChildNodes { (node, _) in
            node.categoryBitMask = BodyType.ObjectModel.rawValue
            node.name = "chairChild"
        }
        // =============================
        let box = SCNBox(width: 0.2, height: 0.2, length: 0.2, chamferRadius: 0)
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.blue
        box.materials=[material]
        boxNode = SCNNode(geometry: box)
        boxNode.categoryBitMask = BodyType.ObjectModel.rawValue
        boxNode.name = boxID
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

        let boxAnchor = ARAnchor(name: boxID, transform: hitTestResult.worldTransform)
        self.sceneView.session.add(anchor: boxAnchor)
        
        let chairAnchor = ARAnchor(name:chairID, transform: hitTestResult.worldTransform)
        self.sceneView.session.add(anchor: chairAnchor)
    }
    
    
    @objc func moved(recognizer :UILongPressGestureRecognizer) {
        guard let recognizerView = recognizer.view as? ARSCNView else { return }
        
        let touch = recognizer.location(in: recognizerView)
        
        let hitTestResult = self.sceneView.hitTest(touch, options: [SCNHitTestOption.categoryBitMask: BodyType.ObjectModel.rawValue])
        guard let collectorNode = getCollectorNode(hitTestResult.first?.node) else { return }
        guard let modelNodeHit = collectorNode.parent else { return }
        var planeHit : ARHitTestResult!
     
        if recognizer.state == .changed {
            
            let hitTestPlane = self.sceneView.hitTest(touch, types: .existingPlane)
            guard hitTestPlane.first != nil else { return }
            planeHit = hitTestPlane.first!
            modelNodeHit.position = SCNVector3(planeHit.worldTransform.columns.3.x,modelNodeHit.position.y,planeHit.worldTransform.columns.3.z)
        
        }else if recognizer.state == .ended || recognizer.state == .cancelled || recognizer.state == .failed{
            
            guard let oldAnchor = sceneView.anchor(for: modelNodeHit) else { return }
            let newAnchor = ARAnchor(name: oldAnchor.name!, transform: modelNodeHit.simdTransform )
            print(oldAnchor.transform.columns.3)        // old position
            sceneView.session.remove(anchor: oldAnchor)
            sceneView.session.add(anchor: newAnchor)
            print(newAnchor.transform.columns.3)        // updated position

        }
    }
    
    //Temporary solution working with 1 kind of advanced object and 1 kind of simple object.
    //Adding more simple objects is easy
    func getCollectorNode(_ nodeFound: SCNNode?) -> SCNNode? {  // TODO: Create method that can handle multiple objects with
        if let node = nodeFound {                               // advanced node hierarchies.
            
            if(node.name == boxID){
                return node
            }

            if node.name == chairID {
                return node
            } else if let parent = node.parent {
                return getCollectorNode(_:)(parent)
            }
        }
        return nil
    }
    

    // MARK: - ARSCNViewDelegate
    
    /* Whenever a new anchor is created, a new node associated with that anchor is created.
     *This function
    */
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if anchor is ARPlaneAnchor {
            print("plane detected")
        }
        if !anchor.isKind(of: ARPlaneAnchor.self) {
            DispatchQueue.main.async {
                switch anchor.name {
                    case self.chairID:
                        let newChairNode = self.chairNode.clone()   //create a new instance of a chair
                        newChairNode.position = SCNVector3Zero
                        // Add model as a child of the newly created node which is located at anchor position
                        node.addChildNode(newChairNode)
                    case self.boxID:
                        let newBoxNode = self.boxNode.clone()
                        newBoxNode.position = SCNVector3Zero
                        node.addChildNode(newBoxNode)
                default:
                    break
                }
            }
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
