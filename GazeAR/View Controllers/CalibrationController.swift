//
//  CalibrationController.swift
//  GazeAR
//
//  Created by Cowboy Lynk on 4/2/20.
//  Copyright © 2020 Cowboy Lynk. All rights reserved.
//

import UIKit
import ARKit
import SceneKit

class CalibrationController: UIViewController, ARSCNViewDelegate {
    
    // MARK: Variables
    // 2D ELEMENTS
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet var calibrationView: UIView!
    @IBOutlet weak var gazePosX: UILabel!
    @IBOutlet weak var gazePosY: UILabel!
    var gazeTarget : UIView = UIView()
    var calibration : Calibration!
    
    // 3D ELEMENTS
    var virtualPhoneNode: SCNNode = SCNNode()
    var virtualScreenNode: SCNNode = {
        let screenGeometry = SCNPlane(width: 1, height: 1)
        screenGeometry.firstMaterial?.isDoubleSided = true
        screenGeometry.firstMaterial?.diffuse.contents = UIColor.green
        return SCNNode(geometry: screenGeometry)
    }()
    var gazeTracker : GazeTracker = GazeTracker()
    
    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Sets up tracker that represents the gaze target
        gazeTarget.backgroundColor = UIColor.red
        gazeTarget.frame = CGRect.init(x: 0, y:0 ,width:25 ,height:25)
        gazeTarget.layer.cornerRadius = 12.5
        sceneView.addSubview(gazeTarget)
        
        // Set the view's delegate
        sceneView.delegate = self
        sceneView.automaticallyUpdatesLighting = true
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Add all the nodes to the scene
//        let device = sceneView.device!
//        let eyeGeometry = ARSCNFaceGeometry(device: device)!
        sceneView.scene.rootNode.addChildNode(gazeTracker)
        virtualPhoneNode.addChildNode(virtualScreenNode)
        sceneView.scene.rootNode.addChildNode(virtualPhoneNode)
        
        // Set up calibration
        calibration = Calibration(gazeTracker: gazeTracker, calibrationView: calibrationView)
        
        // TODO: REMOVE THIS!!!!!
        let test = OpenCVPerformanceTest()
        test.testFindHomographyPerformance()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        guard ARFaceTrackingConfiguration.isSupported else { return }
        let configuration = ARFaceTrackingConfiguration()
        configuration.isLightEstimationEnabled = true
        
        // Run the view's session
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    // MARK: - ARSCNViewDelegate
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
        return node
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let faceAnchor = anchor as? ARFaceAnchor else { return }
        gazeTracker.transform = node.transform
        guard let coords: simd_float2 = gazeTracker.update(withFaceAnchor: faceAnchor, virtualPhoneNode: virtualPhoneNode) else { return }
        
        // Update the tracker and labels
        DispatchQueue.main.async(execute: {() -> Void in
            self.gazeTarget.center = CGPoint.init(x: CGFloat(coords.x), y:CGFloat(coords.y))
            self.gazePosX.text = "\(Int(round(coords.x)))"
            self.gazePosY.text = "\(Int(round(coords.y)))"
        })
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        virtualPhoneNode.transform = (sceneView.pointOfView?.transform)!
    }
    
    func update() {
        
    }
}

