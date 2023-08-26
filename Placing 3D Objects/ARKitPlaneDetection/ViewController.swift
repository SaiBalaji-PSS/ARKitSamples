//
//  ViewController.swift
//  ARKitPlaneDetection
//
//  Created by Sai Balaji on 22/08/23.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController{

    @IBOutlet var sceneView: ARSCNView!
  

    private let scene = SCNScene()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        sceneView.debugOptions = [.showFeaturePoints,.showWorldOrigin]
        // Create a new scene
      
        // Set the scene to the view
        sceneView.autoenablesDefaultLighting = true
        sceneView.scene = scene
   
       // sceneView.delegate = self
        sceneView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapped)))
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
    
    
    
    @IBAction func renderAsWireFrame(_ sender: UIButton){
        sender.isSelected.toggle()
        if sender.isSelected == true{
            self.sceneView.debugOptions = [.renderAsWireframe,.showBoundingBoxes]
            
        }
        else{
            self.sceneView.debugOptions = []
        }
       
       
    }
    
    
    
    
    
    
    
    
    
    
    
    
    @objc func tapped(recognizer: UITapGestureRecognizer){
        let tappedLocation = recognizer.location(in: self.sceneView)
        let hitResult = sceneView.session.raycast(sceneView.raycastQuery(from: tappedLocation, allowing: .estimatedPlane, alignment: .horizontal)!)
        if !hitResult.isEmpty{
            self.addTeaPot(result: hitResult.first!)
        }
    }
    
    func addTeaPot(result: ARRaycastResult){
        print(result.worldTransform)
        print(result.worldTransform.columns.3.y)
        print(result.worldTransform.columns.3.z)
        let teaPotScene = SCNScene(named: "art.scnassets/teapot copy.scn")!
        let teaPotNode = teaPotScene.rootNode.childNode(withName: "teapot", recursively: true)!
        teaPotNode.position = SCNVector3(x: result.worldTransform.columns.3.x, y: result.worldTransform.columns.3.y, z: result.worldTransform.columns.3.z)
        teaPotNode.scale = SCNVector3(x: 0.002, y: 0.002, z: 0.002)
        scene.rootNode.addChildNode(teaPotNode)
    }

}


extension ViewController: ARSCNViewDelegate{
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        print("Add")
        guard let planeAnchor = anchor as? ARPlaneAnchor else{return }
        self.createPlane(planeAnchor: planeAnchor, node: node)
    }
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else{return }
        print(planeAnchor.center)
        print(planeAnchor.extent)
        self.updatePlane(planeAnchor: planeAnchor, node: node)
    }
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        node.enumerateChildNodes { childNode, _ in
            childNode.removeFromParentNode()
        }
        
    }
    
    func createPlane(planeAnchor: ARPlaneAnchor,node: SCNNode){
        let planeGeomentry = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))
        planeGeomentry.materials.first?.diffuse.contents = #colorLiteral(red: 0.3411764801, green: 0.6235294342, blue: 0.1686274558, alpha: 0.6022350993)
        planeGeomentry.materials.first?.isDoubleSided = true
        var planeNode = SCNNode(geometry: planeGeomentry)
        planeNode.position = SCNVector3(x: planeAnchor.center.x, y: 0.0, z: planeAnchor.center.z)
        planeNode.eulerAngles = SCNVector3(x: Float(Double.pi) / 2, y: 0, z: 0)
        node.addChildNode(planeNode)
    }
    
    func updatePlane(planeAnchor: ARPlaneAnchor, node: SCNNode){
        if let planeNode = node.childNodes.first{
            if let planeGeomentry = node.childNodes.first?.geometry as? SCNPlane{
                planeGeomentry.width = CGFloat(planeAnchor.extent.x)
                planeGeomentry.height = CGFloat(planeAnchor.extent.z)
                planeNode.position = SCNVector3(x: planeAnchor.center.x, y: 0.0, z: planeAnchor.center.z)
            }
        }
    }
}
