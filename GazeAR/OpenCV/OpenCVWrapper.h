//
//  OpenCVWrapper.h
//  GazeAR
//
//  Created by Cowboy Lynk on 4/7/20.
//  Copyright © 2020 Cowboy Lynk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <QuartzCore/QuartzCore.h>

typedef struct Quadrilateral {
    CGPoint upperLeft;
    CGPoint upperRight;
    CGPoint lowerRight;
    CGPoint lowerLeft;
} Quadrilateral;

typedef struct Homography {
    CGFloat m00;
    CGFloat m01;
    CGFloat m02;
    CGFloat m10;
    CGFloat m11;
    CGFloat m12;
    CGFloat m20;
    CGFloat m21;
    CGFloat m22;
} Homography;

@interface OpenCVWrapper: NSObject
+ (CATransform3D)findHomographyFromQuadrilateral:(Quadrilateral)origin
                                 toQuadrilateral:(Quadrilateral)destination;

+ (Homography)findHomographyFromPoints:(const CGPoint [])origin
                              toPoints:(const CGPoint [])destination
                         withNumPoints:(int)numPoints;

+ (CGPoint)applyHomographyToPoint:(CGPoint)point
                   withHomography:(Homography)homography;
@end
