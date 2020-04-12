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

func distanceFromPoint(p: CGPoint, toRect rect : CGRect) -> CGFloat {
    let width = rect.width
    let height = rect.height
    let origin = rect.origin
    
    let upperLeft = origin
    let upperRight = origin + CGPoint(x: width, y: 0)
    let lowerLeft = origin + CGPoint(x: 0, y: height)
    let lowerRight = origin + CGPoint(x: width, y: height)
    
    let one = distanceFromPoint(p: p, toLineSegment: upperLeft, and: upperRight)
    let two = distanceFromPoint(p: p, toLineSegment: lowerLeft, and: lowerRight)
    let three = distanceFromPoint(p: p, toLineSegment: upperLeft, and: lowerLeft)
    let four = distanceFromPoint(p: p, toLineSegment: upperRight, and: lowerRight)
    
    return min(four, min(three, min(two, one)))
}

func distanceFromPoint(p: CGPoint, toLineSegment v: CGPoint, and w: CGPoint) -> CGFloat {
    let pv_dx = p.x - v.x
    let pv_dy = p.y - v.y
    let wv_dx = w.x - v.x
    let wv_dy = w.y - v.y

    let dot = pv_dx * wv_dx + pv_dy * wv_dy
    let len_sq = wv_dx * wv_dx + wv_dy * wv_dy
    let param = dot / len_sq

    var int_x, int_y: CGFloat /* intersection of normal to vw that goes through p */

    if param < 0 || (v.x == w.x && v.y == w.y) {
        int_x = v.x
        int_y = v.y
    } else if param > 1 {
        int_x = w.x
        int_y = w.y
    } else {
        int_x = v.x + param * wv_dx
        int_y = v.y + param * wv_dy
    }

    /* Components of normal */
    let dx = p.x - int_x
    let dy = p.y - int_y

    return sqrt(dx * dx + dy * dy)
}
