//
//  Utilities.swift
//  GazeAR
//
//  Created by Cowboy Lynk on 4/10/20.
//  Copyright © 2020 Cowboy Lynk. All rights reserved.
//

import Foundation

func boundedCoords(coords: CGPoint) -> CGPoint {
    let x = Float.maximum(Float.minimum(Float(coords.x), iPadPointSize.x-1), 0)
    let y = Float.maximum(Float.minimum(Float(coords.y), iPadPointSize.y-1), 0)
    return CGPoint(x: CGFloat(x), y: CGFloat(y))
}
