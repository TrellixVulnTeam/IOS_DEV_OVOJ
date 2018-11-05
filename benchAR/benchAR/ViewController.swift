//
//  ViewController.swift
//  benchAR
//
//  Created by Odhrán Daly on 21/11/2017.
//  Copyright © 2017 Odhrán Daly. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

enum BodyType : Int {
    case box = 1
    case plane = 2
    case car = 3
}

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    var planes = [OverlayPlane]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene
        let scene = SCNScene()
        
        // Set the scene to the view
        sceneView.scene = scene
        
        registerGestureRecognizers()
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        
        let estimate = self.sceneView.session.currentFrame?.lightEstimate
        if(estimate == nil){
            return
        }
        
        let intensity = (estimate?.ambientIntensity)! / 1000.0
        self.sceneView.scene.lightingEnvironment.intensity = intensity
    }
    
    private func registerGestureRecognizers(){
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapped))
        tapGestureRecognizer.numberOfTapsRequired = 1
        
        let doubleTappedGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(doubleTapped))
        doubleTappedGestureRecognizer.numberOfTapsRequired = 2
        
        tapGestureRecognizer.require(toFail: doubleTappedGestureRecognizer)
        
        self.sceneView.addGestureRecognizer(doubleTappedGestureRecognizer)
    }
    
    @objc func doubleTapped(recognizer :UITapGestureRecognizer){
        
        print("doubleTapped")
        self.sceneView.debugOptions = []
        
        let configuation = self.sceneView.session.configuration as! ARWorldTrackingConfiguration
        
        configuation.planeDetection = []
        self.sceneView.session.run(configuation, options:[])
        
        // turn off the grid
        for plane in self.planes {
            plane.planeGeometry.materials.forEach { material in
                material.diffuse.contents = UIColor.clear
            }
        }
    }
    
    @objc func tapped(recognizer :UIGestureRecognizer){
        
        let sceneView = recognizer.view as! ARSCNView
        let touch = recognizer.location(in: sceneView)
        
        let hitResults = sceneView.hitTest(touch, types: .existingPlaneUsingExtent)
        
        if !hitResults.isEmpty{
            guard let hitResult = hitResults.first else {
                return
            }
            
            addBench(hitResult :hitResult)
        }
    }
    
    private func addBench(hitResult : ARHitTestResult){
        
        let scene = SCNScene(named: "art.scnassets/bench.dae")!
        
        let benchNode = scene.rootNode.childNode(withName: "SketchUp", recursively: true)
        
        benchNode?.position = SCNVector3(hitResult.worldTransform.columns.3.x,hitResult.worldTransform.columns.3.y ,hitResult.worldTransform.columns.3.z)
        benchNode?.scale = SCNVector3(0.5,0.5,0.5)
        
        self.sceneView.scene.rootNode.addChildNode(benchNode!)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        
        if !(anchor is ARPlaneAnchor){
            return
        }
        
        let plane = OverlayPlane(anchor: anchor as! ARPlaneAnchor)
        self.planes.append(plane)
        node.addChildNode(plane)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        
        let plane = self.planes.filter { plane in
            return plane.anchor.identifier == anchor.identifier
        }.first
        
        if plane == nil {
            return
        }
        
        plane?.update(anchor: anchor as! ARPlaneAnchor)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        configuration.isLightEstimationEnabled = true

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
}
