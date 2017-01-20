//
//  DrawingCanvas.h
//  FreeDraw
//
//  Created by Raghav Janamanchi on 11/01/17.
//  Copyright © 2017 Apportable. All rights reserved.
//
#import "DrawPanelDelegate.h"

@interface DrawingCanvas : CCNode <DrawPanelDelegate>

- (id)initWithObject:(NSManagedObject*)object;
- (void)clear:(NSManagedObject*)object;
- (NSData*)getUIImageData;

@property(strong) NSNumber* imageId;

@end
