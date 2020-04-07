//
//  Calibration.swift
//  GazeAR
//
//  Created by Cowboy Lynk on 4/2/20.
//  Copyright © 2020 Cowboy Lynk. All rights reserved.
//

import Foundation
import UIKit
import ARKit

class Calibration {
    
    // Variables
    let gazeTracker: GazeTracker
    let calibrationView: UIView
    var calibrationPoints: [UIView] = []
    let edgeBuffer = 25
    let numPoints = 3
    var calibrationProgress = 0
    var calibrationGaze: [simd_float2] = []
    
    init(gazeTracker: GazeTracker, calibrationView: UIView) {
        self.gazeTracker = gazeTracker
        self.calibrationView = calibrationView
        
        // Create touch gesture
        let gesture = UITapGestureRecognizer(target: self, action: #selector(calibratePoint))
        calibrationView.addGestureRecognizer(gesture)
        
        generatePoints()
    }
    
    @objc func calibratePoint(sender: UIButton!) {
        if calibrationProgress >= calibrationPoints.count {
            return
        }
        
        // Keep track of the calibration gaze coordinates
        let coords = gazeTracker.coords
        print(coords.x)
        print(coords.y)
        print("-------------")
        calibrationGaze.append(coords)
            
        // Do stuff with this calibration point
        calibrationProgress += 1
        updateCalibrationPoints()
    }
    
    func updateCalibrationPoints() {
        if calibrationProgress < calibrationPoints.count {
            let calibrationPoint = calibrationPoints[calibrationProgress]
            calibrationPoint.alpha = 1
        }
        
        if calibrationProgress > 0 {
            let prevCalibrationPoint = calibrationPoints[calibrationProgress - 1]
            prevCalibrationPoint.alpha = 0
        }
    }
    
    func generatePoints() {
        let size: CGSize = calibrationView.frame.size

        for i in 0..<numPoints {
            for j in 0..<numPoints {
                // Get the X and Y positions of the calibration point
                let adjustedWidth: Float = Float(size.width) - Float(2 * edgeBuffer)
                let adjustedHeight: Float = Float(size.height) - Float(2 * edgeBuffer)
                let x = edgeBuffer + Int(round(Float(i) * (adjustedWidth / Float(numPoints - 1))))
                let y = edgeBuffer + Int(round(Float(j) * (adjustedHeight / Float(numPoints - 1))))

                // Create the views and add them to the calibration view
                let calibrationPoint = createCalibrationPoint(x: x, y: y)
                calibrationPoints.append(calibrationPoint)
                calibrationView.addSubview(calibrationPoint)
            }
        }
        
        updateCalibrationPoints()
    }
    
    func createCalibrationPoint(x: Int, y: Int) -> UIView {
        let calibrationPoint : UIView = UIView()
        calibrationPoint.backgroundColor = UIColor.lightGray
        calibrationPoint.frame = CGRect.init(x: 0, y: 0 ,width:25 ,height:25)
        calibrationPoint.layer.borderWidth = 5
        calibrationPoint.layer.borderColor = UIColor.darkGray.cgColor
        calibrationPoint.center = CGPoint(x: x, y: y)
        calibrationPoint.layer.cornerRadius = 12.5  // Make it a circle
        calibrationPoint.alpha = 0
        return calibrationPoint
    }
}
