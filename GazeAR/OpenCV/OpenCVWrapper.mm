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

static CGPoint convert(Point2f point) {
    return {point.x, point.y};
}

//static Mat convert(Homography hom) {
//    Mat matrix = Mat();
//    matrix.push_back(convert(hom.m00));
//    matrix.push_back(convert(hom.m01));
//    matrix.push_back(convert(hom.m02));
//
//    matrix.push_back(convert(hom.m10));
//    matrix.push_back(convert(hom.m11));
//    matrix.push_back(convert(hom.m12));
//
//    matrix.push_back(convert(hom.m20));
//    matrix.push_back(convert(hom.m21));
//    matrix.push_back(convert(hom.m22));
//
//    return matrix;
//}

static Mat convert(const CGPoint points [], int size) {
    Mat matrix = Mat();
    for (int i = 0; i < size; i++) matrix.push_back(convert(points[i]));
    return matrix;
}


static Mat convert(Quadrilateral quad) {
    Mat matrix = Mat();
    matrix.push_back(convert(quad.upperLeft));
    matrix.push_back(convert(quad.upperRight));
    matrix.push_back(convert(quad.lowerRight));
    matrix.push_back(convert(quad.lowerLeft));
    return matrix;
}

static CATransform3D convertToCATrandform3D(Mat m) {
    CATransform3D transform = CATransform3DIdentity;
    transform.m11 = m.at<CGFloat>(0, 0);
    transform.m21 = m.at<CGFloat>(0, 1);
    transform.m41 = m.at<CGFloat>(0, 2);

    transform.m12 = m.at<CGFloat>(1, 0);
    transform.m22 = m.at<CGFloat>(1, 1);
    transform.m42 = m.at<CGFloat>(1, 2);

    transform.m14 = m.at<CGFloat>(2, 0);
    transform.m24 = m.at<CGFloat>(2, 1);
    transform.m44 = m.at<CGFloat>(2, 2);
    return transform;
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

 static CGPoint applyHmography(Mat m, CGPoint p) {
     return p;
 }

@implementation OpenCVWrapper

+ (CATransform3D)findHomographyFromQuadrilateral:(Quadrilateral)origin
                                 toQuadrilateral:(Quadrilateral)destination {
    return convertToCATrandform3D(findHomography(convert(origin), convert(destination)));
}

+ (Homography)findHomographyFromPoints:(const CGPoint [])origin
                              toPoints:(const CGPoint [])destination
                         withNumPoints:(int)numPoints {
    return convertToHomography(findHomography(convert(origin, numPoints), convert(destination, numPoints)));
}

// TODO: Fill in this function
+ (CGPoint)applyHomographyToPoint:(CGPoint)point
                   withHomography:(Homography)homography {
    return {0, 0};
}
@end
