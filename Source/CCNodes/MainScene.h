//
//  DrawingCanvas.h
//  FreeDraw
//
//  Created by Raghav Janamanchi on 11/01/17.
//  Copyright © 2017 Apportable. All rights reserved.
//

@interface MainScene : CCScene

- (id)initWithObject:(NSManagedObject*)object;
- (void)clearWithObject:(NSManagedObject*)object;
- (NSData*)captureScreen;
- (NSNumber*)getID;

@end
