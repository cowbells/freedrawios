#import "MainScene.h"
#import "DrawingCanvas.h"

@implementation MainScene
{
    DrawingCanvas* canvas;
}

- (id)initWithObject:(NSManagedObject*)object
{
    self = [super init];
    if (self)
    {
        canvas = [[DrawingCanvas alloc] initWithObject:object];
        canvas.contentSize = [CCDirector sharedDirector].viewSize;
        canvas.position = CGPointZero;
        canvas.anchorPoint = CGPointZero;
        [self addChild:canvas];
    }
    return self;
}

- (void)clearWithObject:(NSManagedObject*)object
{
    [canvas clear:object];
}

- (NSData*)captureScreen
{
    return [canvas getUIImageData];
}

- (NSNumber*)getID
{
    return canvas.imageId;
}

@end
