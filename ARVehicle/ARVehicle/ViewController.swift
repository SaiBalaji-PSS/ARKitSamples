//
//  ViewController.swift
//  ARVehicle
//
//  Created by Sai Balaji on 24/08/23.
//

import UIKit
import SceneKit
import ARKit
import GameController

class ViewController: UIViewController{
    
    @IBOutlet var sceneView: ARSCNView!
    private var carNode = SCNNode()
    private var scene = SCNScene()
    private var carScene = SCNScene()
    private var physicsVehicle = SCNPhysicsVehicle()
    private var gameController: GCVirtualController!
    
    var engineForce: Float = 0.0 // Force in newtons
    var brakingForce: Float = 0.0 // Force in newtons
    var steeringValue: Float = 0.0
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene
        carScene = SCNScene(named: "art.scnassets/Car.scn")!
    
        // Set the scene to the view
        
        sceneView.scene = self.scene
        sceneView.autoenablesDefaultLighting = true
        sceneView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTap)))
        sceneView.scene.physicsWorld.gravity = SCNVector3Make(0.0, -0.5, 0.0)
        self.configureGamePad()
        carNode = carScene.rootNode.childNode(withName: "chassi", recursively: false)!
        
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
    
    
    
    func configureGamePad(){
        let configuration = GCVirtualController.Configuration()
        configuration.elements = [GCInputDirectionPad,GCInputButtonA,GCInputButtonB,GCInputButtonY]
        gameController = GCVirtualController(configuration: configuration)
        gameController.connect()
        NotificationCenter.default.addObserver(self, selector: #selector(controllerDidConnect), name: NSNotification.Name.GCControllerDidConnect, object: nil)
        
    }
    
    
    
    
    @objc func controllerDidConnect(_ notification: NSNotification){
         print("Connect")
        if let controller = gameController.controller{
            registerController(controller: controller)
        }
        
    }
    
    func registerController(controller : GCController){
        if let gamePad = controller.extendedGamepad{
            gamePad.dpad.valueChangedHandler = { (_pad: GCControllerDirectionPad, xvalue: Float, yvalue: Float) -> Void in
                print("X: \(xvalue) Y: \(yvalue)")
                self.steeringValue = xvalue
            }
            gamePad.buttonA.pressedChangedHandler = {(button: GCControllerButtonInput, value
                                                      : Float, pressed: Bool) in
                print(value)
            //    print("BEFORE APPLYING ENGINE FORCE \(self.engineForce)")
                self.engineForce = value * 2.0
              
             
                print("APPLYING ENGINE FORCE \(self.engineForce)")
            }
            gamePad.buttonB.pressedChangedHandler = {(button: GCControllerButtonInput, value
                                                      : Float, pressed: Bool) in
                self.brakingForce = value * 0.5
                print("APPLYING BRAKE FORCE \(self.engineForce)")
            }
            gamePad.buttonY.pressedChangedHandler = {(button: GCControllerButtonInput, value
                                                      : Float, pressed: Bool) in
                
                self.engineForce = -2.0 * value
                
            }
        }
        
    }
    
    @objc func didTap(recognizer: UITapGestureRecognizer){
        let tapLocation = recognizer.location(in: self.sceneView)
        let hitResult = sceneView.session.raycast(sceneView.raycastQuery(from: tapLocation, allowing: .estimatedPlane, alignment: .horizontal)!)
        if !hitResult.isEmpty{
            self.placeCar(result: hitResult.first!)
//            let cube = SCNBox(width: 0.08, height: 0.08, length: 0.08, chamferRadius: 0.0)
//            cube.materials.first?.diffuse.contents = UIColor.red
//            let cubeNode = SCNNode(geometry: cube)
//            cubeNode.position = SCNVector3(x: hitResult.first!.worldTransform.columns.3.x, y: hitResult.first!.worldTransform.columns.3.y + 0.2, z: hitResult.first!.worldTransform.columns.3.z)
//            cubeNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
//            cubeNode.physicsBody?.isAffectedByGravity = true
//            scene.rootNode.addChildNode(cubeNode)
            
        }
    }
    
    func placeCar(result: ARRaycastResult){
       
        
        let frontLeftWheelNode = self.carNode.childNode(withName: "frontLeftParent", recursively: false)!
        let frontRightWheelNode = self.carNode.childNode(withName: "frontRightParent", recursively: false)!
        let backLeftNode = self.carNode.childNode(withName: "rearLeftParent", recursively: false)!
        let backRightNode = self.carNode.childNode(withName: "rearRightParent", recursively: false)!
        
        
        let frontLeftWheel = SCNPhysicsVehicleWheel(node: frontLeftWheelNode)
        let frontRightWheel = SCNPhysicsVehicleWheel(node: frontRightWheelNode)
        let backLeftWheel = SCNPhysicsVehicleWheel(node: backLeftNode)
        let backRightWheel = SCNPhysicsVehicleWheel(node: backRightNode)
        
        
        
        
        carNode.position = SCNVector3(x: result.worldTransform.columns.3.x, y: result.worldTransform.columns.3.y + 0.5, z: result.worldTransform.columns.3.z)
        carNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(node: self.carNode,options:[SCNPhysicsShape.Option.keepAsCompound: true]))
        carNode.physicsBody?.mass = 1
        self.physicsVehicle = SCNPhysicsVehicle(chassisBody: self.carNode.physicsBody!, wheels: [frontLeftWheel,frontRightWheel,backLeftWheel,backRightWheel])
        self.scene.physicsWorld.addBehavior(self.physicsVehicle)
        
        
        self.scene.rootNode.addChildNode(carNode)
    }
}


//MARK: - PLANE DETECTION
extension ViewController: ARSCNViewDelegate{
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else{return }
        self.createPlane(anchor: planeAnchor, node: node)
    }
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
      
        node.enumerateChildNodes { childNode, _ in
            childNode.removeFromParentNode()
        }
        guard let planeAnchor = anchor as? ARPlaneAnchor else{return }
    
        self.createPlane(anchor: planeAnchor, node: node)
    }
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        node.enumerateChildNodes { childNode, _ in
            childNode.removeFromParentNode()
        }
    }
    
    func createPlane(anchor: ARPlaneAnchor,node: SCNNode){
        let planeGeometry = SCNPlane(width: CGFloat(anchor.extent.x), height: CGFloat(anchor.extent.z))
        planeGeometry.materials.first?.diffuse.contents = #colorLiteral(red: 0.5725490451, green: 0, blue: 0.2313725501, alpha: 0.6990376656)
        planeGeometry.materials.first?.isDoubleSided = true
        let planeNode = SCNNode(geometry: planeGeometry)
        planeNode.position = SCNVector3(x: anchor.center.x, y: anchor.center.y, z: anchor.center.z)
        planeNode.eulerAngles = SCNVector3(x: Float(Double.pi) / 2, y: 0.0, z: 0.0)
        planeNode.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
        planeNode.physicsBody?.isAffectedByGravity = false
        node.addChildNode(planeNode)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didSimulatePhysicsAtTime time: TimeInterval) {
        // Apply engine force to front wheels
        self.physicsVehicle.applyEngineForce(CGFloat(self.engineForce), forWheelAt: 0)
        self.physicsVehicle.applyEngineForce(CGFloat(self.engineForce), forWheelAt: 1)
        
        //Apply brake force to rear wheels
        self.physicsVehicle.applyBrakingForce(CGFloat(self.brakingForce), forWheelAt: 0)
        self.physicsVehicle.applyBrakingForce(CGFloat(self.brakingForce), forWheelAt: 1)
        
        //Add Steering value
        self.physicsVehicle.setSteeringAngle(CGFloat(self.steeringValue), forWheelAt: 0)
        self.physicsVehicle.setSteeringAngle(CGFloat(self.steeringValue), forWheelAt: 1)
    }
    
    func updatePlane(anchor: ARPlaneAnchor,node: SCNNode){
        if let planeNode = node.childNodes.first{
            if let planeGeometry = planeNode.geometry as? SCNPlane{
                planeGeometry.width = CGFloat(anchor.extent.x)
                planeGeometry.height = CGFloat(anchor.extent.z)
                planeNode.position = SCNVector3(x: anchor.center.x, y: anchor.center.y, z: anchor.center.z)
                print(planeNode.physicsBody)
            }
        }
    }
}


