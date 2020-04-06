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
    let gazeTracker: SCNNode
    let calibrationView: UIView
    let edgeBuffer = 25
    let calibrationPoints = 3
    
    init(gazeTracker: SCNNode, calibrationView: UIView) {
        self.gazeTracker = gazeTracker
        self.calibrationView = calibrationView
        generatePoints()
    }
    
    func generatePoints() {
        let size: CGSize = calibrationView.frame.size
        
        for i in 0..<calibrationPoints {
            for j in 0..<calibrationPoints {
                // Get the X and Y positions of the calibration point
                let adjustedWidth: Float = Float(size.width) - Float(2 * edgeBuffer)
                let adjustedHeight: Float = Float(size.height) - Float(2 * edgeBuffer)
                let x = edgeBuffer + Int(round(Float(i) * (adjustedWidth / Float(calibrationPoints - 1))))
                let y = edgeBuffer + Int(round(Float(j) * (adjustedHeight / Float(calibrationPoints - 1))))
                
                // Create the views and add them to the calibration view
                let calibrationPoint = createCalibrationPoint(x: x, y: y)
                calibrationView.addSubview(calibrationPoint)
            }
        }
    }
    
    func createCalibrationPoint(x: Int, y: Int) -> UIView {
        let calibrationPoint : UIView = UIView()
        calibrationPoint.backgroundColor = UIColor.lightGray
        calibrationPoint.frame = CGRect.init(x: 0, y: 0 ,width:25 ,height:25)
        calibrationPoint.layer.borderWidth = 5
        calibrationPoint.layer.borderColor = UIColor.darkGray.cgColor
        calibrationPoint.center = CGPoint(x: x, y: y)
        calibrationPoint.layer.cornerRadius = 12.5  // Make it a circle
        return calibrationPoint
    }
}
