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

extension CalibrationController {
    
    func initializeCalibration () {
        // Create touch gesture
        let gesture = UITapGestureRecognizer(target: self, action: #selector(calibratePoint))
        calibrationView.addGestureRecognizer(gesture)

        generatePoints()
    }
    
    func resetCalibration() {
        gazeTracker.setHomography(homography: nil)
        calibrationProgress = 0
        calibrationPoints = []
        
        for calibrationPoint in gridPoints {
            calibrationPoint.alpha = 0
        }
        
        updateCalibrationUI()
    }
    
    @objc func calibratePoint() {
        if calibrationProgress >= gridPoints.count {
            return
        }
        
        // Keep track of the calibration gaze coordinates
        let coords = gazeTracker.coords
        calibrationPoints.append(coords)
            
        // Do stuff with this calibration point
        calibrationProgress += 1
        updateCalibrationUI()
    }
    
    func generatePoints() {
        let size: CGSize = calibrationView.frame.size

        for i in 0..<Calibration.numPoints {
            for j in 0..<Calibration.numPoints {
                // Get the X and Y positions of the calibration point
                let adjustedWidth: Float = Float(size.width) - Float(2 * Calibration.edgeBuffer)
                let adjustedHeight: Float = Float(size.height) - Float(2 * Calibration.edgeBuffer)
                let x = Calibration.edgeBuffer + Int(round(Float(i) * (adjustedWidth / Float(Calibration.numPoints - 1))))
                let y = Calibration.edgeBuffer + Int(round(Float(j) * (adjustedHeight / Float(Calibration.numPoints - 1))))

                // Create the views and add them to the calibration view
                let calibrationPoint = Calibration.createCalibrationPoint(x: x, y: y)
                gridPoints.append(calibrationPoint)
                calibrationView.addSubview(calibrationPoint)
            }
        }
        
        updateCalibrationUI()
    }
    
    func updateCalibrationUI() {
        // Previous point should be set made transparent
        if calibrationProgress > 0 {
            let prevCalibrationPoint = gridPoints[calibrationProgress - 1]
            prevCalibrationPoint.alpha = 0
        }
        
        // Next point should be made visible
        if calibrationProgress < gridPoints.count {
            let calibrationPoint = gridPoints[calibrationProgress]
            calibrationPoint.alpha = 1
            calibrationDoneButton.backgroundColor = UIColor.gray
        } else {  // We are done calibrating
            var from: [CGPoint] = []
            var to: [CGPoint] = []
//            for i in 0..<calibrationPoints.count {  // All points
            for i in [0, 1, 3, 4, 6, 7] {  // All top points
//            for i in [0, 1, 7, 6] {  // Top corners
//            for i in [0, 2, 8, 6] {  // All corners
                let gazePoint = calibrationPoints[i]
                from.append(gazePoint)
                
                let savedCalibrationPoint = calibrationView.convert(gridPoints[i].center, to: view)
                to.append(savedCalibrationPoint)
            }
            
            // Create the homography
            let homography = OpenCVWrapper.findHomography(from: from, to: to, withNumPoints: 4)
            gazeTracker.setHomography(homography: homography)
            
            calibrationDoneButton.backgroundColor = UIColor.systemBlue
            calibrationDoneButton.isUserInteractionEnabled = true
        }
        
        calibrationProgressBar.progress = Float(calibrationProgress) / pow(Float(Calibration.numPoints), 2)
    }
    
    func finishedCalibrating() -> Bool {
        return calibrationProgress >= gridPoints.count
    }
}

class Calibration {
    static let edgeBuffer = 35
    static let numPoints = 3
    
    
    static func createCalibrationPoint(x: Int, y: Int) -> UIView {
        let calibrationPoint : UIView = UIView()
        calibrationPoint.backgroundColor = UIColor.white
        calibrationPoint.frame = CGRect.init(x: 0, y: 0 ,width:40 ,height:40)
        calibrationPoint.layer.borderWidth = 15
        calibrationPoint.layer.borderColor = UIColor.systemBlue.cgColor
        calibrationPoint.center = CGPoint(x: x, y: y)
        calibrationPoint.layer.cornerRadius = 20  // Make it a circle
        calibrationPoint.alpha = 0
        return calibrationPoint
    }
}
