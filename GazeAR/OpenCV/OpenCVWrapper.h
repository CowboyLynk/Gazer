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

typedef struct Homography {
    CGFloat m11;
    CGFloat m12;
    CGFloat m13;
    CGFloat m21;
    CGFloat m22;
    CGFloat m23;
    CGFloat m31;
    CGFloat m32;
    CGFloat m33;
} Homography;

@interface OpenCVWrapper: NSObject
+ (Homography)findHomographyFromPoints:(const CGPoint [])origin
                              toPoints:(const CGPoint [])destination
                         withNumPoints:(int)numPoints;

+ (CGPoint)applyHomographyToPoint:(CGPoint)point
                   withHomography:(Homography)homography;
@end
