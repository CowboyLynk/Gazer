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

@interface OpenCVWrapper: NSObject
+ (CATransform3D)findHomographyFromQuadrilateral:(Quadrilateral)origin
                                 toQuadrilateral:(Quadrilateral)destination;
@end
