//
//  CircleView.swift
//  GazeAR
//
//  Created by Cowboy Lynk on 4/12/20.
//  Copyright © 2020 Cowboy Lynk. All rights reserved.
//

import Foundation
import UIKit

class CircleView: UIView {
    var circleLayer: CAShapeLayer!
    let borderWidth: CGFloat = 5
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    func setup() {
        self.backgroundColor = UIColor.clear

        // Use UIBezierPath as an easy way to create the CGPath for the layer.
        // The path should be the entire circle.
        let circlePath = UIBezierPath(arcCenter: CGPoint(x: frame.size.width / 2.0, y: frame.size.height / 2.0), radius: (frame.size.width - borderWidth)/2, startAngle: 0.0, endAngle: CGFloat(Double.pi * 2.0), clockwise: true)

        // Setup the CAShapeLayer with the path, colors, and line width
        circleLayer = CAShapeLayer()
        circleLayer.path = circlePath.cgPath
        circleLayer.fillColor = UIColor.clear.cgColor
        circleLayer.strokeColor = UIColor.systemBlue.cgColor
        circleLayer.lineWidth = borderWidth;

        // Don't draw the circle initially
        circleLayer.strokeEnd = 0.0

        // Add the circleLayer to the view's layer's sublayers
        layer.addSublayer(circleLayer)
        
        // make circle
        self.layer.cornerRadius = frame.size.width / 2
    }
    
    func updateCircle(progress: CGFloat) {
        circleLayer.strokeEnd = progress
    }
    
    func updateColor(color: UIColor) {
        circleLayer.strokeColor = color.cgColor
    }
    
    func resetColor() {
        circleLayer.strokeColor = UIColor.systemBlue.cgColor
    }
    
    func recognizedCommand() {
        self.backgroundColor = UIColor.systemGreen
        let _ = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(self.resetVisualFeedback), userInfo: nil, repeats: false)
    }
    
    func unrecognizedCommand() {
        self.backgroundColor = UIColor.systemRed
        let _ = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(self.resetVisualFeedback), userInfo: nil, repeats: false)
    }
    
    @objc func resetVisualFeedback() {
        self.backgroundColor = UIColor.clear
    }
}
