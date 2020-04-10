//
//  OpenCVWrapper.mm
//  GazeAR
//
//  Created by Cowboy Lynk on 4/7/20.
//  Copyright © 2020 Cowboy Lynk. All rights reserved.
//

#ifdef __cplusplus

#import <opencv2/opencv.hpp>

#import <opencv2/imgcodecs/ios.h>

#import <opencv2/videoio/cap_ios.h>

#endif

#import "OpenCVWrapper.h"


using namespace cv;

static Point2f convert(CGPoint point) {
    return Point2f(point.x, point.y);
}

static Mat_<CGFloat> convert(Homography hom) {
    Mat_<CGFloat> matrix(3, 3);
    matrix << hom.m11, hom.m12, hom.m13, hom.m21, hom.m22, hom.m23, hom.m31, hom.m32, hom.m33;

    matrix.reshape(3, 3);
    return matrix;
}

static Mat convert(const CGPoint points [], int size) {
    Mat matrix = Mat();
    for (int i = 0; i < size; i++) matrix.push_back(convert(points[i]));
    return matrix;
}

static Homography convertToHomography(Mat m) {
    Homography homography = {
        m.at<CGFloat>(0, 0),
        m.at<CGFloat>(0, 1),
        m.at<CGFloat>(0, 2),
        
        m.at<CGFloat>(1, 0),
        m.at<CGFloat>(1, 1),
        m.at<CGFloat>(1, 2),
        
        m.at<CGFloat>(2, 0),
        m.at<CGFloat>(2, 1),
        m.at<CGFloat>(2, 2)
    };
    return homography;
}

 static CGPoint applyHomography(Homography h, CGPoint p) {
     Mat_<CGFloat> m = convert(h);
     Mat_<CGFloat> coords(3, 1); coords << p.x, p.y, CGFloat(1);
     
     Mat applyHomography = m * coords;
     CGFloat w = applyHomography.at<CGFloat>(0, 2);
     CGPoint transformedPoint = {applyHomography.at<CGFloat>(0, 0) / w, applyHomography.at<CGFloat>(0, 1) / w};
     return transformedPoint;
 }

@implementation OpenCVWrapper

+ (Homography)findHomographyFromPoints:(const CGPoint [])origin
                              toPoints:(const CGPoint [])destination
                         withNumPoints:(int)numPoints {
    return convertToHomography(findHomography(convert(origin, numPoints), convert(destination, numPoints), RANSAC));
}

+ (CGPoint)applyHomographyToPoint:(CGPoint)point
                   withHomography:(Homography)homography {
    return applyHomography(homography, point);
}
@end
