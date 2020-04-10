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
    
    // MARK: - Variables
    // 2D ELEMENTS
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet var calibrationView: UIView!
    @IBOutlet weak var gazePosX: UILabel!
    @IBOutlet weak var gazePosY: UILabel!
    @IBOutlet weak var adjustedGazePosX: UILabel!
    @IBOutlet weak var adjustedGazePosY: UILabel!
    @IBOutlet weak var calibrationProgressBar: UIProgressView!
    @IBOutlet weak var calibrationDoneButton: UIButton!
    var gazeTarget : UIView = UIView()
    
    // 3D ELEMENTS
    var virtualPhoneNode: SCNNode = SCNNode()
    var virtualScreenNode: SCNNode = {
        let screenGeometry = SCNPlane(width: 1, height: 1)
        screenGeometry.firstMaterial?.isDoubleSided = true
        screenGeometry.firstMaterial?.diffuse.contents = UIColor.green
        return SCNNode(geometry: screenGeometry)
    }()
    var gazeTracker : GazeTracker = GazeTracker()
    
    // Calibration
    var gridPoints: [UIView] = []  // The initial grid made for calibration
    var calibrationPoints: [simd_float2] = []  // The points the user looked at during calibration
    var calibrationProgress = 0
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Sets up tracker that represents the gaze target
        gazeTarget.backgroundColor = UIColor.red
        gazeTarget.frame = CGRect.init(x: 0, y:0 ,width:25 ,height:25)
        gazeTarget.layer.cornerRadius = 12.5
        view.addSubview(gazeTarget)
        view.bringSubviewToFront(gazeTarget)
        
        // Set the view's delegate
        sceneView.delegate = self
        sceneView.automaticallyUpdatesLighting = true
        
        // Add all the nodes to the scene
        sceneView.scene.rootNode.addChildNode(gazeTracker)
        virtualPhoneNode.addChildNode(virtualScreenNode)
        sceneView.scene.rootNode.addChildNode(virtualPhoneNode)
        
        // Set up calibration
        initializeCalibration()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        guard ARFaceTrackingConfiguration.isSupported else { return }
        let configuration = ARFaceTrackingConfiguration()
        configuration.isLightEstimationEnabled = true
        
        // Run the view's session
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        
        // Everytime we come back to this scene the calibration shoud reset
        resetCalibration()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if segue.destination is GameController
        {
            let vc = segue.destination as? GameController
            vc?.homography = gazeTracker.homography
        }
    }
 
    // MARK: - IB Actions
    @IBAction func resetCalibrationButtonPressed(_ sender: Any) {
        resetCalibration()
    }
    
    @IBAction func doneButtonPressed(_ sender: Any) {
        if finishedCalibrating() {
            performSegue(withIdentifier: "doneCalibratingSegue", sender: nil)
        } else {
            let alert = UIAlertController(title: "Calibration Incomplete", message: "Are you sure you want to continue?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { action in
                self.performSegue(withIdentifier: "doneCalibratingSegue", sender: nil)
            }))
            alert.addAction(UIAlertAction(title: "No", style: .default, handler: nil))
            self.present(alert, animated: true)
        }
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
        guard let rawCoords: CGPoint = gazeTracker.update(withFaceAnchor: faceAnchor, virtualPhoneNode: virtualPhoneNode) else { return }
        
        // Update the labels with the raw position
        let boundedRawCoords = boundedCoords(coords: rawCoords)
        DispatchQueue.main.async(execute: {() -> Void in
            self.gazePosX.text = "\(Int(round(boundedRawCoords.x)))"
            self.gazePosY.text = "\(Int(round(boundedRawCoords.y)))"
        })
        
        // Use the homography to adjust the position
        let adjustedCoords = gazeTracker.getTransformedPoint(point: rawCoords)
        let boundedAdjustedCoords = boundedCoords(coords: adjustedCoords)
        
        // Update the tracker and labels with the adjusted Position
        DispatchQueue.main.async(execute: {() -> Void in
            self.gazeTarget.center = boundedAdjustedCoords
            self.adjustedGazePosX.text = "\(Int(round(boundedAdjustedCoords.x)))"
            self.adjustedGazePosY.text = "\(Int(round(boundedAdjustedCoords.y)))"
        })
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        virtualPhoneNode.transform = (sceneView.pointOfView?.transform)!
    }
}
