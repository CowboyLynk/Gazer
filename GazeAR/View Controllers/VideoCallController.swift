//
//  VideoCallController.swift
//  GazeAR
//
//  Created by Cowboy Lynk on 4/26/20.
//  Copyright © 2020 Cowboy Lynk. All rights reserved.
//

import UIKit
import ARKit
import AgoraRtcKit

let AppID = "65ff8a3b30c84bb5bfb373146abc9693"

class VideoCallController: UIViewController, ARSCNViewDelegate {
    
    // MARK: - Variables
    // 2D ELEMENTS
    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet var sceneView: ARSCNView!
    var gazeTarget : UIView = UIView()
    var speechCommandView: SpeechCommandView!
    @IBOutlet var unfocusedSlider: UISlider!
    
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
    var agoraKit: AgoraRtcEngineKit!
    var data: [UIView] = []  // the people on the call
    var isFocusEnabled = false
    var currentFocusUid: UInt? = nil
    var lastFocusTime = Date()
    
    // MARK: - Init and lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        unfocusedSlider.value = 0
        unfocusedSlider.isEnabled = false
        
        // Sets up speech command view
        let frame = CGRect(x: 20, y: 90, width: 50, height: 50)
        speechCommandView = SpeechCommandView(frame: frame, delegate: self)
        self.view.addSubview(speechCommandView)
        
        // Sets up the video collection view
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(VideoCell.self, forCellWithReuseIdentifier: VideoCell.identifier)
        
        // Sets up video call engine
        initializeAgoraEngine()
        setupVideo()
        setChannelProfile()
        
        // Sets up tracker that represents the gaze target
        gazeTarget.backgroundColor = UIColor.red
        gazeTarget.frame = CGRect.init(x: 0, y:0 ,width:25 ,height:25)
        gazeTarget.layer.cornerRadius = 12.5
        view.addSubview(gazeTarget)
        view.bringSubviewToFront(gazeTarget)
        
        // Set the view's delegate
        sceneView.delegate = self
        sceneView.automaticallyUpdatesLighting = true
        sceneView.layer.masksToBounds = true
        sceneView.clipsToBounds = true
        sceneView.layer.cornerRadius = 15
        
        // Add all the nodes to the scene
        sceneView.scene.rootNode.addChildNode(gazeTracker)
        virtualPhoneNode.addChildNode(virtualScreenNode)
        sceneView.scene.rootNode.addChildNode(virtualPhoneNode)
        
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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let alertController = UIAlertController(title: nil, message: "Ready to join channel?", preferredStyle: .alert)
        
        let action = UIAlertAction(title: "Join", style: .destructive) { (action:UIAlertAction) in
            self.joinChannel()
        }
        alertController.addAction(action)
        present(alertController, animated: true, completion: nil)
    }
    
    // MARK: - Functions
    
    func initializeAgoraEngine() {
        
        agoraKit = AgoraRtcEngineKit.sharedEngine(withAppId: AppID, delegate: self)
        agoraKit.enableWebSdkInteroperability(true)
    }
    
    func setupVideo() {
        agoraKit.enableVideo()
        let configuration = AgoraVideoEncoderConfiguration(size: AgoraVideoDimension640x360, frameRate: .fps15, bitrate: AgoraVideoBitrateStandard, orientationMode: .adaptative)
        agoraKit.setVideoEncoderConfiguration(configuration)
    }
    
    func setChannelProfile() {
        agoraKit.setChannelProfile(.communication)
    }

    func joinChannel() {
        agoraKit.setDefaultAudioRouteToSpeakerphone(true)
        agoraKit.joinChannel(byToken: nil, channelId: "test", info: nil, uid: 0)
        agoraKit.enableLocalVideo(false)
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    @IBAction func didTouchHangUpButton(_ sender: Any) {
        leaveChannel()
    }
    
    func leaveChannel() {
        agoraKit.leaveChannel(nil)
        UIApplication.shared.isIdleTimerDisabled = false
        data = []
        collectionView.reloadData()
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
                setVolumeForAll(volume: 0)
                speechCommandView.handleStartSpeech()
            } else {
                setVolumeForAll(volume: 100)
                speechCommandView.handleEndSpeech()
            }
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
        
        // Check collection view cells
        if isFocusEnabled && progress == 0 {
            handleVideoFocusGaze(boundedAdjustedGaze)
        }
    }
    
    func handleVideoFocusGaze(_ boundedAdjustedGaze: CGPoint) {
        // Find the new focus cell
        var newFocusUid: UInt? = nil
        for case let cell as VideoCell in collectionView.visibleCells {
            let convertedPoint = self.view.convert(boundedAdjustedGaze, to: collectionView)
            let shouldHighlight = cell.frame.contains(convertedPoint)
            if shouldHighlight {
                newFocusUid = cell.uid
                break
            }
        }
        
        // Update all the variables
        if currentFocusUid == newFocusUid {
            // If the focused video is the same, keep updating the timeout
            lastFocusTime = Date()
        } else {
            // Only udpdate the current focus ID, if the timeout has passed
            let timeDelta = Date().timeIntervalSince(lastFocusTime)
            if timeDelta > gazeTimeout {
                currentFocusUid = newFocusUid
                // Set the volume and highlighting appropriately
                let lowVolume = Int32(unfocusedSlider.value * 100)
                for case let cell as VideoCell in collectionView.visibleCells {
                    let isNewFocusCell = cell.uid == newFocusUid
                    cell.changeBorder(shouldHighlight: isNewFocusCell)
                    agoraKit.adjustUserPlaybackSignalVolume(cell.uid, volume: isNewFocusCell || newFocusUid == nil ? 100 : lowVolume)
                }
            }
        }
    }
    
    func setVolumeForAll(volume : Int32) {
        for case let cell as VideoCell in collectionView.visibleCells {
            agoraKit.adjustUserPlaybackSignalVolume(cell.uid, volume: volume)
        }
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

// MARK: - Agora Delegate

extension VideoCallController: AgoraRtcEngineDelegate {
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, firstRemoteVideoDecodedOfUid uid: UInt, size: CGSize, elapsed: Int) {
        
        let videoView = UIView(frame: .zero)
        videoView.tag = Int(uid)
        videoView.backgroundColor = UIColor.purple

        let videoCanvas = AgoraRtcVideoCanvas()
        videoCanvas.uid = uid
        videoCanvas.view = videoView
        videoCanvas.renderMode = .hidden
        agoraKit.setupRemoteVideo(videoCanvas)
        
        newUserJoined(withView: videoView)
    }
    
    internal func rtcEngine(_ engine: AgoraRtcEngineKit, didOfflineOfUid uid:UInt, reason:AgoraUserOfflineReason) {
        data = data.filter(){$0.tag != Int(uid)}
        collectionView.reloadData()
    }
}
