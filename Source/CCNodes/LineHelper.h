//
//  LineHelper.h
//
//  Created by Raghav Janamanchi on 02/01/17.
//  Copyright © 2017 Apportable. All rights reserved.
//


@interface LineHelper : NSObject

- (id)initWithStart:(CGPoint)startPoint end:(CGPoint)endPoint;
- (void)updateStart:(CGPoint)startPoint end:(CGPoint)endPoint;
- (CGFloat)getXFromY:(CGFloat)y;
- (CGFloat)getYFromX:(CGFloat)x;

@end
