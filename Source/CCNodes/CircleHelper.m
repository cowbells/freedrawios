//
//  CircleHelper.m
//
//  Created by Raghav Janamanchi on 03/01/17.
//  Copyright © 2017 Apportable. All rights reserved.
//
// The class assumes the points are in continuous fashion albeit clockwise/anitclockwise direction
// For the points to be a circle, all the points in the array should be in close proximity to the center/radius distance
// Figure out the top, bottom, left and right most points
// From the above 4 figure out the approximate center and radius
// All the points in the array should be in close proximity to the center/radius distance
// The angle between the first point and the running point should go from 0 to 180 and back


#import "CircleHelper.h"
#import "LinePoint.h"
#import <Foundation/Foundation.h>

@implementation CircleHelper
{
    CGPoint center;
    CGFloat radius;
    BOOL isCircle;
}

- (CGFloat)distanceBetweenPoints:(CGPoint)first second:(CGPoint)second
{
    CGFloat X = (second.x - first.x);
    CGFloat Y = (second.y - first.y);
    return sqrtf(X*X + Y*Y);
}

- (void)reset
{
    isCircle = NO;
    center = CGPointZero;
    radius = 0.f;
}

#define radiansToDegrees(x) (180.0 * x / M_PI)
CGFloat angleBetweenLines(CGPoint line1Start, CGPoint line1End, CGPoint line2Start, CGPoint line2End) {
    
    CGFloat a = line1End.x - line1Start.x;
    CGFloat b = line1End.y - line1Start.y;
    CGFloat c = line2End.x - line2Start.x;
    CGFloat d = line2End.y - line2Start.y;
    
    CGFloat rads = acos(((a*c) + (b*d)) / ((sqrt(a*a + b*b)) * (sqrt(c*c + d*d))));
    
    return radiansToDegrees(rads);
}

BOOL fuzzyGreater(CGFloat bigger, CGFloat smaller)
{
    if ((bigger - smaller) > 0.001)
        return true;
    return false;
}

- (void)checkForCircle:(NSMutableArray<LinePoint*>*)points
{
    // We are in the top right quadrant
    CGFloat leftmostPoint = points[0].pos.x;
    CGFloat rightmostPoint = points[0].pos.x;
    CGFloat topmostPoint = points[0].pos.y;
    CGFloat bottommostPoint = points[0].pos.y;
    
    for (LinePoint* point in points)
    {
        if (point.pos.x > rightmostPoint)
        {
            rightmostPoint = point.pos.x;
        }
        if (point.pos.x < leftmostPoint)
        {
            leftmostPoint = point.pos.x;
        }
        if (point.pos.y > bottommostPoint)
        {
            bottommostPoint = point.pos.y;
        }
        if (point.pos.y < topmostPoint)
        {
            topmostPoint = point.pos.y;
        }
    }
    
    center = CGPointMake((leftmostPoint + rightmostPoint) / 2.0, (topmostPoint + bottommostPoint) / 2.0);
    radius = MIN((rightmostPoint - leftmostPoint) / 2.0, (bottommostPoint - topmostPoint) / 2.0);
    
    // the first and the last point should be in close proximity
    if (!ccpFuzzyEqual(points.firstObject.pos, points.lastObject.pos, 25.f))
        return;
    
    CGFloat radiusTolerance = radius + 15.f;
    CGFloat runningAngle = 0.0;
    BOOL directionReveresed = NO;
    
    for (int i = 0; i < points.count; ++i)
    {
        CGPoint curPoint = points[i].pos;
        if (fabs(radius - [self distanceBetweenPoints:curPoint second:center]) > radiusTolerance)
            return;
        
        CGFloat currentAngle = angleBetweenLines(points[0].pos, center, points[i].pos, center);
        
        if ((currentAngle > runningAngle) && directionReveresed)
            return;
        
        if ((currentAngle < runningAngle) && !directionReveresed)
        {
            directionReveresed = YES;
        }
        
        runningAngle = currentAngle;
    }
    
    // If it has come this far, it is indeed a circle or so I assume :D
    isCircle = YES;
}

- (void)update:(NSMutableArray<LinePoint*>*)points
{
    [self reset];
    [self checkForCircle:points];
}

- (instancetype)initWithPoints:(NSMutableArray<LinePoint*>*)points
{
    self = [super init];
    if (self)
    {
        [self update:points];
    }
    
    return self;
}

- (BOOL)isCircle
{
    return isCircle;
}

- (CGPoint)getCenter
{
    return center;
}

- (CGFloat)getRadius
{
    return radius;
}

@end
