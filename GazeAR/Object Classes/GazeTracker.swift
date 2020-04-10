//
//  GazeTracker.swift
//  GazeAR
//
//  Created by Cowboy Lynk on 4/2/20.
//  Copyright © 2020 Cowboy Lynk. All rights reserved.
//

import Foundation
import ARKit
import SceneKit

let iPadPointSize = simd_float2(1668/2, 2388/2)
let iPadMeterSize = simd_float2(0.16048181818181817, 0.22975454545454543)

class GazeTracker : SCNNode {
    // MARK: Constants
    let offset = simd_float2(1668/4, 2388/4)
    let floatRaycastDistance:Float = 2  // How far away in meters the gaze visualization should extend
    let numPositions = 10 // How many positions to average over
    let hitTestOptions : [String: Any] = [SCNHitTestOption.backFaceCulling.rawValue: false,
                                   SCNHitTestOption.searchMode.rawValue: 1,
                                   SCNHitTestOption.ignoreChildNodes.rawValue : false,
                                   SCNHitTestOption.ignoreHiddenNodes.rawValue : false]
    var homography : Homography?  // How points are altered after calibration
    
    // MARK: Variables
    var positions: Array<simd_float2> = Array()
    var leftEye: SCNNode = {
        let geometry = SCNCone(topRadius: 0.005, bottomRadius: 0.003, height: 0.2)
        geometry.radialSegmentCount = 20
        geometry.firstMaterial?.diffuse.contents = UIColor.systemBlue
        let node = SCNNode()
        node.geometry = geometry
        node.eulerAngles.x = -.pi / 2
        node.position.z = 0.1
        node.opacity = 0.5
        let parentNode = SCNNode()
        parentNode.addChildNode(node)
        return parentNode
    }()
    var rightEye: SCNNode = {
        let geometry = SCNCone(topRadius: 0.005, bottomRadius: 0.003, height: 0.2)
        geometry.radialSegmentCount = 20
        geometry.firstMaterial?.diffuse.contents = UIColor.systemBlue
        let node = SCNNode()
        node.geometry = geometry
        node.eulerAngles.x = -.pi / 2
        node.position.z = 0.1
        node.opacity = 0.5
        let parentNode = SCNNode()
        parentNode.addChildNode(node)
        return parentNode
    }()
    var leftEyeEnd: SCNNode = SCNNode()
    var rightEyeEnd: SCNNode = SCNNode()
    var coords = simd_float2(0, 0)
    
    // MARK: Initialization
    override init() {
        leftEye.addChildNode(leftEyeEnd)
        leftEyeEnd.simdPosition = simd_float3(0,0, floatRaycastDistance);
        rightEye.addChildNode(rightEyeEnd)
        rightEyeEnd.simdPosition = simd_float3(0,0, floatRaycastDistance);
        
        super.init()
        
        addChildNode(leftEye)
        addChildNode(rightEye)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("\(#function) has not been implemented")
    }
    
    // MARK: - Public Functions
    
    /**
    Sets the homography matrix variable
     */
    func setHomography(homography: Homography?) {
        self.homography = homography
    }
    
    /**
     Applies the homography matrix to @param point
     */
    func getTransformedPoint(point: CGPoint) -> CGPoint {
        if (homography != nil) {
            return OpenCVWrapper.applyHomography(to: point, with: homography!);
        }
        return point;
    }
    
    // MARK: - ARKit Updates
    func update(withFaceAnchor anchor: ARFaceAnchor, virtualPhoneNode: SCNNode) -> CGPoint? {
        leftEye.simdTransform = anchor.leftEyeTransform;
        rightEye.simdTransform = anchor.rightEyeTransform;
        
        let hitTestLeftEye = virtualPhoneNode.hitTestWithSegment(
            from: virtualPhoneNode.convertPosition(leftEye.worldPosition, from:nil),
            to:  virtualPhoneNode.convertPosition(leftEyeEnd.worldPosition, from:nil),
            options: hitTestOptions)
        
        let hitTestRightEye = virtualPhoneNode.hitTestWithSegment(
            from: virtualPhoneNode.convertPosition(rightEye.worldPosition, from:nil),
            to:  virtualPhoneNode.convertPosition(rightEyeEnd.worldPosition, from:nil),
            options: hitTestOptions)
        
        if (hitTestLeftEye.count > 0 && hitTestRightEye.count > 0) {
            coords = screenPositionFromHittest(result1: hitTestLeftEye[0], result2: hitTestRightEye[0])
            return CGPoint(x: CGFloat(coords.x), y: CGFloat(coords.y))
        }
        return nil
    }
    
    func screenPositionFromHittest(result1: SCNHitTestResult, result2: SCNHitTestResult) -> simd_float2 {
        // Get the local coordinates
        // TODO: This formula needs to be adjusted and calibrated
        let xLC = ((result1.localCoordinates.x + result2.localCoordinates.x) / 2.0)
        let x = xLC / (iPadMeterSize.x / 2.0) * iPadPointSize.x + offset.x
        let yLC = -((result1.localCoordinates.y + result2.localCoordinates.y) / 2.0);
        let y = yLC / (iPadMeterSize.y / 2.0) * iPadPointSize.y + offset.y
        
        // Smooth the values
        positions.append(simd_float2(x,y));
        if positions.count > numPositions {
            positions.removeFirst()
        }
        
        // Average the values
        var total = simd_float2(0,0);
        for pos in positions {
            total.x += pos.x
            total.y += pos.y
        }
        total.x /= Float(positions.count)
        total.y /= Float(positions.count)
        
        return total
    }
}
