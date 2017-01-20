//
//  CircleHelper.h
//
//  Created by Raghav Janamanchi on 03/01/17.
//  Copyright © 2017 Apportable. All rights reserved.
//

@class LinePoint;
@interface CircleHelper : NSObject

- (instancetype)initWithPoints:(NSMutableArray<LinePoint*>*)points;
- (void)update:(NSMutableArray<LinePoint*>*)points;
- (BOOL)isCircle;
- (CGPoint)getCenter;
- (CGFloat)getRadius;

@end
