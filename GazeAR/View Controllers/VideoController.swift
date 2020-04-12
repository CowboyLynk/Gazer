//
//  GameController.swift
//  GazeAR
//
//  Created by Cowboy Lynk on 4/7/20.
//  Copyright © 2020 Cowboy Lynk. All rights reserved.
//

import UIKit
import ARKit
import SceneKit
import Speech
import YouTubePlayer

class VideoController: UIViewController, ARSCNViewDelegate {
    
    // MARK: - Variables
    // 2D ELEMENTS
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var voiceCommandView: UIVisualEffectView!
    @IBOutlet weak var voiceCommandWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var voiceRecognitionField: UITextField!
    var gazeTarget : UIView = UIView()
    @IBOutlet var videoPlayer: YouTubePlayerView!
    
    // 3D ELEMENTS
    var virtualPhoneNode: SCNNode = SCNNode()
    var virtualScreenNode: SCNNode = {
        let screenGeometry = SCNPlane(width: 1, height: 1)
        screenGeometry.firstMaterial?.isDoubleSided = true
        screenGeometry.firstMaterial?.diffuse.contents = UIColor.green
        return SCNNode(geometry: screenGeometry)
    }()
    
    // MISC
    var gazeTracker = GazeTracker()
    var homography : Homography?
    var gaze = Gaze(coords: CGPoint(x: Int(Constants.iPadPointSize.x)/2,
                                    y: Int(Constants.iPadPointSize.y)/2))
    var isGazeOnScreen = false
    
    // Audio
    let audioEngine = AVAudioEngine()
    let speechRecognizer: SFSpeechRecognizer? = SFSpeechRecognizer()
    let request = SFSpeechAudioBufferRecognitionRequest()
    var recognitionTask: SFSpeechRecognitionTask?
    
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
        
        // Set up Video
        videoPlayer.playerVars = [
            "playsinline": "1",
            "controls": "0",
            "showinfo": "0"
            ] as YouTubePlayerView.YouTubePlayerParameters
        videoPlayer.loadVideoID("ozUzomVQsWc")
        
        // Set up gazeTracking
        gazeTracker.setHomography(homography: homography)
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
        guard let rawCoords: CGPoint = gazeTracker.update(withFaceAnchor: faceAnchor, virtualPhoneNode: virtualPhoneNode) else { return }
        let boundedRawCoords = boundedCoords(coords: rawCoords)
        
        // Use the homography to adjust the position
        let adjustedCoords = gazeTracker.getTransformedPoint(point: rawCoords)
        let boundedAdjustedCoords = boundedCoords(coords: adjustedCoords)
        
        // Update the tracker and labels with the adjusted Position
        DispatchQueue.main.async(execute: {() -> Void in
            self.handleGaze(boundedAdjustedGaze: boundedAdjustedCoords, rawGaze: rawCoords, boundedRawGaze: boundedRawCoords)
            self.gazeTarget.center = boundedAdjustedCoords
        })
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        virtualPhoneNode.transform = (sceneView.pointOfView?.transform)!
    }
}
