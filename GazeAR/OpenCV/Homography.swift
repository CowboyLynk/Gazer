//
//  Homography.swift
//  GazeAR
//
//  Created by Cowboy Lynk on 4/3/20.
//  Copyright © 2020 Cowboy Lynk. All rights reserved.
//


class OpenCVPerformanceTest {

    let destination = Quadrilateral(upperLeft: CGPoint(x: 108.315837, y: 80.1687782),
                                    upperRight: CGPoint(x: 377.282671, y: 41.4352201),
                                    lowerRight: CGPoint(x: 193.321418, y: 330.023027),
                                    lowerLeft: CGPoint(x: 459.781253, y: 251.836131))
    let start: Quadrilateral = {
        var one = Quadrilateral()
        one.upperLeft = CGPoint(x: 0, y: 0)
        one.upperRight = CGPoint(x: 1, y: 0)
        one.lowerLeft = CGPoint(x: 0, y: 1)
        one.lowerRight = CGPoint(x: 1, y: 1)
        return one
    }()

    /** on average findHomography 4 times slower then perspectiveTransform
     */
    func testFindHomographyPerformance() {
        let test = OpenCVWrapper.findHomography(from: start, to: destination)
        print(test)
    }
}
