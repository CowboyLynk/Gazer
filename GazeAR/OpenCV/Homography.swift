//
//  Homography.swift
//  GazeAR
//
//  Created by Cowboy Lynk on 4/3/20.
//  Copyright © 2020 Cowboy Lynk. All rights reserved.
//


class OpenCVPerformanceTest {
    
    func testFindHomography() {
        let destinationArr = [CGPoint(x: 108.315837, y: 80.1687782),
                           CGPoint(x: 377.282671, y: 41.4352201),
                           CGPoint(x: 193.321418, y: 330.023027),
                           CGPoint(x: 459.781253, y: 251.836131)]
        let startArr = [CGPoint(x: 0, y: 0),
                     CGPoint(x: 1, y: 0),
                     CGPoint(x: 0, y: 1),
                     CGPoint(x: 1, y: 1)]
        let homography = OpenCVWrapper.findHomography(from: startArr, to: destinationArr, withNumPoints: 4)
        print("found homography")
        print(OpenCVWrapper.applyHomography(to: CGPoint(x: 1, y: 0), with: homography))
    }
}
