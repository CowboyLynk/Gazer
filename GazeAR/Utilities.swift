//
//  Utilities.swift
//  GazeAR
//
//  Created by Cowboy Lynk on 4/10/20.
//  Copyright © 2020 Cowboy Lynk. All rights reserved.
//

import Foundation
import ARKit
import CoreGraphics

class Constants {
    static let iPadPointSize = simd_float2(1668/2, 2388/2)
    static let iPadMeterSize = simd_float2(0.16048181818181817, 0.22975454545454543)
}

func +(lhs: CGPoint, rhs: CGPoint) -> CGPoint {
    return CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
}

func boundedCoords(coords: CGPoint) -> CGPoint {
    let x = Float.maximum(Float.minimum(Float(coords.x), Constants.iPadPointSize.x-1), 0)
    let y = Float.maximum(Float.minimum(Float(coords.y), Constants.iPadPointSize.y-1), 0)
    return CGPoint(x: CGFloat(x), y: CGFloat(y))
}

func CGPointDistanceSquared(from: CGPoint, to: CGPoint) -> CGFloat {
    return (from.x - to.x) * (from.x - to.x) + (from.y - to.y) * (from.y - to.y)
}

func convertWrittenNumToInt(numString: String) -> Int? {
    let numberFormatter:NumberFormatter = NumberFormatter()
    numberFormatter.numberStyle = NumberFormatter.Style.spellOut
    return numberFormatter.number(from: numString)?.intValue
}
