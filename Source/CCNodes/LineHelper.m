//
//  LineHelper.m
//
//  Created by Raghav Janamanchi on 02/01/17.
//  Copyright © 2017 Apportable. All rights reserved.
//

#import "LineHelper.h"
#import <Foundation/Foundation.h>

@implementation LineHelper
{
    CGPoint startPoint;
    CGPoint endPoint;
    CGFloat slope;
    CGFloat offset;
}

- (void)constructLine
{
    // First get m
    slope = (endPoint.y - startPoint.y) / (endPoint.x - startPoint.x);
    // Now b = (y - m * x)
    offset = startPoint.y - (slope * startPoint.x);
}

- (void)resetStart:(CGPoint)_startPoint end:(CGPoint)_endPoint
{
    startPoint = _startPoint;
    endPoint = _endPoint;
    [self constructLine];
}

- (id)initWithStart:(CGPoint)_startPoint end:(CGPoint)_endPoint
{
    self = [super init];
    if (self)
    {
        [self resetStart:_startPoint end:_endPoint];
    }
    
    return self;
}

- (void)updateStart:(CGPoint)_startPoint end:(CGPoint)_endPoint
{
    [self resetStart:_startPoint end:_endPoint];
}

- (CGFloat)getXFromY:(CGFloat)y
{
    // x  = (y - b) / m
    NSAssert(slope != 0, @"Division by zero!!!");
    CGFloat x = (y - offset) / slope;
    return x;
}

- (CGFloat)getYFromX:(CGFloat)x
{
    // y = m * x + b
    CGFloat y = (slope * x) + offset;
    return y;
}

@end
