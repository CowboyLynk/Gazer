//
//  WebController.swift
//  GazeAR
//
//  Created by Cowboy Lynk on 4/19/20.
//  Copyright © 2020 Cowboy Lynk. All rights reserved.
//

import UIKit
import ARKit
import SceneKit
import Speech
import WebKit

class WebController: UIViewController, ARSCNViewDelegate, WKNavigationDelegate {
    
    // MARK: - Variables
    // 2D ELEMENTS
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet var webView: WKWebView!
    var gazeTarget : UIView = UIView()
    var speechCommandView: SpeechCommandView!
    
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
    var isGazeOnScreen = false
    var gaze = Gaze(coords: CGPoint(x: Int(Constants.iPadPointSize.x)/2,
                                    y: Int(Constants.iPadPointSize.y)/2))
    let maxScrollSpeed: CGFloat = 5  // pixels
    let scrollAreaSize: CGFloat = 250
    var scrollEnabled = true
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Sets up speech command view
        let frame = CGRect(x: 20, y: 90, width: 50, height: 50)
        speechCommandView = SpeechCommandView(frame: frame, delegate: self)
        self.view.addSubview(speechCommandView)
        
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
        
        // Set up gazeTracking
        gazeTracker.setHomography(homography: homography)
        
        // Set up web view
        webView.navigationDelegate = self
        let url = URL(string: "https://www.allrecipes.com/")!
        webView.load(URLRequest(url: url))
        webView.allowsBackForwardNavigationGestures = true
        webView.layer.borderColor = UIColor.systemRed.cgColor
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
    
    // MARK: - Handle gaze
    func handleGaze(boundedAdjustedGaze : CGPoint, rawGaze : CGPoint, boundedRawGaze : CGPoint) {
        
        // Check if the gaze is off the screen
        let squaredScreenDist = CGPointDistanceSquared(from: rawGaze, to: boundedRawGaze)
        if squaredScreenDist <= allowedOffScreenDistSquared && !isGazeOnScreen {
            handleOnScreenGaze()
        } else if squaredScreenDist > allowedOffScreenDistSquared && isGazeOnScreen {
            handleOffScreenGaze()
        }
        
        // Check if the gaze is near the speech icon
        let speechCommandRect = speechCommandView.frame
        let boundingRect = CGRect(x: speechCommandRect.origin.x - nearingSpeechViewDist/2,
                                  y: speechCommandRect.origin.y - nearingSpeechViewDist/2,
                                  width: speechCommandRect.width + nearingSpeechViewDist,
                                  height: speechCommandRect.height + nearingSpeechViewDist)
        let touchedSpeechView = boundingRect.contains(boundedAdjustedGaze)
        let wasTouchingSpeechView = boundingRect.contains(gaze.coords)
        let sameAction = wasTouchingSpeechView == touchedSpeechView
        let timeDelta = Date().timeIntervalSince(gaze.time)
        let timeoutPassed = timeDelta > gazeTimeout
        if !sameAction && timeoutPassed {
            if touchedSpeechView {
                speechCommandView.handleStartSpeech()
            } else {
                speechCommandView.handleEndSpeech()
            }
        }
        
        // Check scroll
        if !touchedSpeechView && scrollEnabled && squaredScreenDist <= allowedOffScreenDistSquared {
            let relativeGaze = view.convert(boundedAdjustedGaze, to: webView)
            var yAdjustment: CGFloat = 0
            let maxYThresh = webView.frame.height - scrollAreaSize
            if relativeGaze.y <= scrollAreaSize {
                let multiplier = CGFloat.minimum((scrollAreaSize - relativeGaze.y) / scrollAreaSize, 1)
                yAdjustment = -maxScrollSpeed * multiplier
            } else if relativeGaze.y >= maxYThresh {
                let multiplier = (relativeGaze.y - maxYThresh) / scrollAreaSize
                yAdjustment = maxScrollSpeed * multiplier
            }
            let oldOffset = webView.scrollView.contentOffset
            let newYVal = CGFloat.maximum(0, oldOffset.y + yAdjustment)
            webView.scrollView.contentOffset = CGPoint(x: oldOffset.x, y: newYVal)
        }
        
        // Update last relevant gaze
        if sameAction || timeoutPassed {
            gaze.setCoords(newCoords: boundedAdjustedGaze)
        }
        
        // Update the progress timeout bar
        var progress = 1.0
        if !sameAction {  // TODO: and audio command didn't timeout
            progress = timeDelta / gazeTimeout
            if !touchedSpeechView {
                progress = 1 - progress
            }
        } else if !touchedSpeechView {
            progress = 0.0
        }
        speechCommandView.updateCircle(progress: CGFloat(progress))
    }
    
    func handleOnScreenGaze() {
        isGazeOnScreen = true
    }
    
    func handleOffScreenGaze() {
        isGazeOnScreen = false
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
        var boundedAdjustedCoords = boundedCoords(coords: adjustedCoords)
        
        // Update the tracker and labels with the adjusted Position
        DispatchQueue.main.async(execute: {() -> Void in
            boundedAdjustedCoords = CGPoint(
                x: boundedAdjustedCoords.x,
                y: CGFloat.maximum(boundedAdjustedCoords.y, self.webView.frame.origin.y)
            )
            self.handleGaze(boundedAdjustedGaze: boundedAdjustedCoords, rawGaze: rawCoords, boundedRawGaze: boundedRawCoords)
            self.gazeTarget.center = boundedAdjustedCoords
        })
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        virtualPhoneNode.transform = (sceneView.pointOfView?.transform)!
    }
}
