//
//  DrawingCanvas.m
//  FreeDraw
//
//  Created by Raghav Janamanchi on 11/01/17.
//  Copyright © 2017 Apportable. All rights reserved.
//  Inspired from https://github.com/krzysztofzablocki/KZLineDrawer

#import "DrawingCanvas.h"
#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <UIKit/UIGestureRecognizerSubclass.h>
#import "CCRenderer_private.h"
#import "AppDelegate.h"
#import <CCButton.h>
#import <CCAction.h>
#import "LineHelper.h"
#import "CircleHelper.h"
#import "LinePoint.h"
#import "DBHelper.h"
#import "DrawPanel.h"

typedef struct
{
    CGPoint pos;
    CGFloat z;
    ccColor4F color;
} LineVertex;

@implementation DrawingCanvas
{
    NSMutableArray<LinePoint*>* points;
    NSMutableArray<LinePoint*>* slicedPoints;
    NSMutableArray<LinePoint*>* totalUndoPoints;
    NSMutableArray<LinePoint*>* circlesPoints;
    
    BOOL connectingLine;
    CGPoint prevC, prevD;
    CGPoint prevG;
    CGPoint prevI;
    CGFloat overdraw;
    CGPoint rulerPosition;
    CGFloat _red, tempRed;
    CGFloat _green, tempGreen;
    CGFloat _blue, tempBlue;
    
    CCRenderTexture* renderTexture;
    CCDrawNode* drawNode;
    CCSprite* rulerSprite;
    BOOL rulerAdded;
    CGFloat rulerHeight;
    CGFloat rulerWidth;
    
    BOOL eraserAdded;
    
    CGFloat lineWidth, tempLineWidth, maxLineWidth;
    CGFloat undoLineWidth;
    
    BOOL finishingLine;
    
    BOOL undoingPoints;
        
    LineHelper* lineHelper;
    CircleHelper* circleHelper;
    DatabaseHelper* dbHelper;
    
    UIRotationGestureRecognizer* rotateGesture;
    
    DrawPanel* drawPanel;
    CGRect drawPanelShowRect;
    CGRect drawPanelHideRect;
    BOOL drawPanelShowing;
}

@synthesize imageId;

#pragma mark DrawPanelDelegate
- (void)lineWidthChanged:(id)sender
{
    UISlider* slider = (UISlider*)sender;
    lineWidth = MIN(maxLineWidth, 1.f + (5.f * slider.value));
    undoLineWidth = 2 * lineWidth;
}

- (void)redValueChanged:(id)sender
{
    UISlider* slider = (UISlider*)sender;
    _red = slider.value;
}

- (void)greenValueChanged:(id)sender
{
    UISlider* slider = (UISlider*)sender;
    _green = slider.value;
}

- (void)blueValueChanged:(id)sender
{
    UISlider* slider = (UISlider*)sender;
    _blue = slider.value;
}

- (void)rulerToggle:(id)sender
{
    if (rulerAdded)
    {
        [self removeRuler];
    }
    else
    {
        [self addRuler];
    }
}

- (void)backPressed:(id)sender
{
    id delegate = [[UIApplication sharedApplication] delegate];
    [delegate showHome];
}

- (void)removeEraser
{
    _red = tempRed;
    _blue = tempBlue;
    _green = tempGreen;
    lineWidth = tempLineWidth;
    eraserAdded = NO;
}

- (void)addEraser
{
    _red = 1.0;
    _blue = 1.0;
    _green = 1.0;
    lineWidth = 1.5 * maxLineWidth; // Arbitrary
    eraserAdded = YES;
}

- (void)eraserToggle:(id)sender
{
    if (eraserAdded)
    {
        [self removeEraser];
    }
    else
    {
        [self addEraser];
    }
}

#pragma mark DrawPanel show/hide
- (void)showDrawPanel
{
    drawPanelShowing = YES;
    [UIView animateWithDuration:1.0 animations:^{
        [drawPanel setFrame:drawPanelShowRect];
    }];
}

- (void)hideDrawPanel:(NSTimeInterval)delayInterval
{
    drawPanelShowing = NO;
    [UIView animateWithDuration:1.0 delay:delayInterval options:UIViewAnimationOptionCurveEaseOut animations:^{
        [drawPanel setFrame:drawPanelHideRect];
    } completion:nil];
}

#pragma mark Touches
- (void)changePoint:(CGPoint*)point
{
    CGFloat rotation = [rulerSprite rotation];
    if (((rotation > 315) || (rotation < 45)) || ((rotation > 135) && (rotation < 225)))
    {
        point->y = [lineHelper getYFromX:point->x];
    }
    else
    {
        point->x = [lineHelper getXFromY:point->y];
    }
}

- (void)touchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
    if (drawPanelShowing)
    {
        [self hideDrawPanel:0]; // Immediately hide panel
    }
    
    CGPoint point = [[CCDirector sharedDirector] convertToGL:[touch locationInView:[[CCDirector sharedDirector] view]]];
    
    [points removeAllObjects];
    [slicedPoints removeAllObjects];
    
    if (rulerAdded)
    {
        if (CGRectContainsPoint([rulerSprite spriteFrame].rect, point))
        {
            [rulerSprite setPosition:point];
        }
        else
        {
            CGFloat rulerRotation = [rulerSprite rotation] * M_PI / 180.f;
            CGPoint rulerPos = [rulerSprite position];
            CGFloat startX = rulerPos.x - (cosf(rulerRotation) * (rulerWidth / 2));
            CGFloat startY = rulerPos.y + (sinf(rulerRotation) * (rulerWidth / 2));
            
            CGPoint startPoint = CGPointMake(startX, startY);
            CGPoint endPoint = CGPointMake(rulerPos.x, rulerPos.y);
            CGPoint dir = ccpSub(startPoint, endPoint);
            CGPoint perpendicular = ccpNormalize(ccpPerp(dir));
            CGPoint _startPoint = ccpAdd(startPoint, ccpMult(perpendicular, -rulerHeight/ 2));
            CGPoint _endPoint = ccpAdd(endPoint, ccpMult(perpendicular, -rulerHeight/ 2));
            
            [lineHelper updateStart:_startPoint end:_endPoint];
            [self changePoint:&point];
            
            [self startNewLineFrom:point];
            [self addPoint:point];
            [self addPoint:point];
        }
    }
    else
    {
        [self startNewLineFrom:point];
        [self addPoint:point];
        [self addPoint:point];
    }
}

- (void)touchMoved:(UITouch *)touch withEvent:(UIEvent *)event
{
    CGPoint point = [[CCDirector sharedDirector] convertToGL:[touch locationInView:[[CCDirector sharedDirector] view]]];
    // skip points that are too close
    CGFloat eps = 0.5;
    if (points.count > 0) {
        CGFloat length = ccpLength(ccpSub(points.lastObject.pos, point));
        if (length < eps) {
            return;
        }
    }
    if (rulerAdded)
    {
        if (CGRectContainsPoint([rulerSprite spriteFrame].rect, point))
        {
            [rulerSprite setPosition:point];
        }
        else
        {
            [self changePoint:&point];
            [self addPoint:point];
        }
    }
    else
    {
        [self addPoint:point];
    }
    
}

- (void)touchEnded:(UITouch *)touch withEvent:(UIEvent *)event
{
    CGPoint point = [[CCDirector sharedDirector] convertToGL:[touch locationInView:[[CCDirector sharedDirector] view]]];
    if (rulerAdded)
    {
        if (CGRectContainsPoint([rulerSprite spriteFrame].rect, point))
        {
            [rulerSprite setPosition:point];
        }
        else
        {
            [self changePoint:&point];
            [self endLineAt:point];
        }
    }
    else
    {
        [self endLineAt:point];
        [self validateCircle];
    }
}

- (void)touchCancelled:(UITouch *)touch withEvent:(UIEvent *)event
{
    if (rulerAdded) return;
    // Not sure what to do here
}

#pragma mark Class Methods
- (void)addBGImage:(NSData*)imageData
{
    // Lets add the background image if any
    if (imageData != NULL)
    {
        UIImage* image = [UIImage imageWithData:imageData];
        
        // TODO The saved image manages to grow in size somehow. The below code to size it down
        CGSize viewSize = [[CCDirector sharedDirector] viewSize];
        UIGraphicsBeginImageContextWithOptions(viewSize, NO, 0.0);
        [image drawInRect:CGRectMake(0, 0, viewSize.width, viewSize.height)];
        UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        CCTexture* tex = [[CCTexture alloc] initWithCGImage:newImage.CGImage contentScale:newImage.scale];
        CCSprite* sprite = [CCSprite spriteWithTexture:tex];
        sprite.position = ccp(renderTexture.contentSize.width/2, renderTexture.contentSize.height/2);
        [sprite setBlendMode:[CCBlendMode blendModeWithOptions:@{CCBlendFuncSrcColor: @(GL_SRC_ALPHA),
                                                                 CCBlendFuncDstColor: @(GL_ONE_MINUS_SRC_ALPHA)}]];
        [renderTexture begin];
        [sprite visit];
        [renderTexture end];
    }
}

- (void)reset
{
    if (rulerAdded)
    {
        [self removeRuler];
    }
    if (eraserAdded)
    {
        [self removeEraser];
    }
}

- (void)clear:(NSManagedObject*)object
{
    [renderTexture clear:1.0 g:1.0 b:1.0 a:1.0];
    
    self.imageId = [object valueForKey:kImageIdKey];
    NSData* imageData = [object valueForKey:kImageDataKey];
    
    [self addBGImage:imageData];
    [self reset];
    [self showDrawPanel];
}

- (id)initWithObject:(NSManagedObject*)object
{
    self = [super init];
    if (self)
    {
        self.imageId = [object valueForKey:kImageIdKey];
        NSData* imageData = [object valueForKey:kImageDataKey];
        
        points = [NSMutableArray array];
        slicedPoints = [NSMutableArray array];
        circlesPoints = [NSMutableArray array];
        totalUndoPoints = [NSMutableArray array];
        
        overdraw = 0.5;
        _red = _green = _blue = tempRed = tempGreen = tempBlue = 0.5;
        
        CGSize viewSize = [[CCDirector sharedDirector] viewSize];
        renderTexture = [[CCRenderTexture alloc] initWithWidth:viewSize.width height:viewSize.height pixelFormat:CCTexturePixelFormat_RGBA8888];
        
        [self setUserInteractionEnabled:YES];
        
        renderTexture.positionType = CCPositionTypeNormalized;
        renderTexture.anchorPoint = ccp(0, 0);
        renderTexture.position = ccp(0.5, 0.5);
        [renderTexture clear:1.0 g:1.0 b:1.0 a:1.0];
        [self addChild:renderTexture];
        
        [self addBGImage:imageData];
        
        drawNode = [[CCDrawNode alloc] init];
        [self addChild:drawNode];
        
        rulerSprite = [CCSprite spriteWithImageNamed:@"Ruler.png"];
        rulerPosition = ccp(renderTexture.contentSize.width/2, renderTexture.contentSize.height/2);
        rulerAdded = NO;
        // Adding these as constants for now. Refactor!
        rulerHeight = 93.f;
        rulerWidth = 800.f;
        
        eraserAdded = NO;
        
        lineHelper = [[LineHelper alloc] initWithStart:CGPointMake(20.f, 5.f) end:CGPointMake(800.f, 500.f)];
        circleHelper = [[CircleHelper alloc] init];
        undoingPoints = NO;
        lineWidth = tempLineWidth = 3.5;
        maxLineWidth = 6.5; // Good idea to a max limit
        undoLineWidth = 2 * lineWidth;
        
        dbHelper = [DatabaseHelper sharedDatabaseHelper];
        
        rotateGesture = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(rotate:)];
        
        // TODO refactor constants
        CGFloat minWidth = MIN(680.f, viewSize.width - 20.f);
        CGFloat offset = (viewSize.width - minWidth) / 2.0;
        drawPanelShowRect = CGRectMake(offset, -10.f, minWidth, 80.f);
        drawPanelHideRect = CGRectMake(offset, -70.f, minWidth, 80.f);
        drawPanel = [[DrawPanel alloc] initWithFrame:drawPanelHideRect delegate:self];
        [[[CCDirector sharedDirector] view] addSubview:drawPanel];
    }
    return self;
}

- (NSData*)getUIImageData
{
    UIImage* image = [renderTexture getUIImage];
    return UIImagePNGRepresentation(image);
}

#pragma mark Ruler
- (void)rotate:(UIRotationGestureRecognizer*)recognizer
{
    assert(rulerAdded);
    // The rotation looks smooth enough. I don't think I need an action here
    CGFloat currentRotation = [rulerSprite rotation];
    [rulerSprite setRotation:currentRotation + (recognizer.rotation * 1.15)];//Slightly accelerate it
}

- (void)addRuler
{
    [[[CCDirector sharedDirector]view] addGestureRecognizer:rotateGesture];
    
    [rulerSprite setPosition:rulerPosition];
    [rulerSprite setOpacity:0.35]; // magic number
    [self addChild:rulerSprite];
    [rulerSprite setRotation:45];
    rulerAdded = YES;
}

- (void)removeRuler
{
    [[[CCDirector sharedDirector]view] removeGestureRecognizer:rotateGesture];
    
    [self removeChild:rulerSprite];
    rulerAdded = NO;
}

#pragma mark - Handling points
- (void)startNewLineFrom:(CGPoint)newPoint
{
    connectingLine = NO;
    [self addPoint:newPoint];
}

- (void)endLineAt:(CGPoint)aEndPoint
{
    [self addPoint:aEndPoint];
    finishingLine = YES;
}

- (void)addPoint:(CGPoint)newPoint
{
    LinePoint *point = [[LinePoint alloc] init];
    point.pos = newPoint;
    point.width = lineWidth;
    [points addObject:point];
}

#pragma mark - Drawing

#define ADD_TRIANGLE(A, B, C, Z) vertices[index].pos = A, vertices[index++].z = Z, vertices[index].pos = B, vertices[index++].z = Z, vertices[index].pos = C, vertices[index++].z = Z

- (void)drawLines:(NSArray<LinePoint*>*)linePoints withColor:(ccColor4F)color
{
    NSUInteger numberOfVertices = (linePoints.count - 1) * 18;
    LineVertex *vertices = calloc(sizeof(LineVertex), numberOfVertices);
    
    CGPoint prevPoint = linePoints[0].pos;
    CGFloat prevValue = linePoints[0].width;
    CGFloat curValue;
    NSInteger index = 0;
    for (NSUInteger i = 1; i < linePoints.count; ++i) {
        LinePoint *pointValue = linePoints[i];
        CGPoint curPoint = pointValue.pos;
        curValue = pointValue.width;
        
        //! equal points, skip them
        if (ccpFuzzyEqual(curPoint, prevPoint, 0.0001)) {
            continue;
        }
        
        CGPoint dir = ccpSub(curPoint, prevPoint);
        CGPoint perpendicular = ccpNormalize(ccpPerp(dir));
        CGPoint A = ccpAdd(prevPoint, ccpMult(perpendicular, prevValue / 2));
        CGPoint B = ccpSub(prevPoint, ccpMult(perpendicular, prevValue / 2));
        CGPoint C = ccpAdd(curPoint, ccpMult(perpendicular, curValue / 2));
        CGPoint D = ccpSub(curPoint, ccpMult(perpendicular, curValue / 2));
        
        //! continuing line
        if (connectingLine || index > 0) {
            A = prevC;
            B = prevD;
        } else if (index == 0) {
            //! circle at start of line, revert direction
            [circlesPoints addObject:pointValue];
            [circlesPoints addObject:linePoints[i - 1]];
        }
        
        ADD_TRIANGLE(A, B, C, 1.0);
        ADD_TRIANGLE(B, C, D, 1.0);
        
        prevD = D;
        prevC = C;
        if (finishingLine && (i == linePoints.count - 1)) {
            [circlesPoints addObject:linePoints[i - 1]];
            [circlesPoints addObject:pointValue];
            finishingLine = NO;
        }
        
        prevPoint = curPoint;
        prevValue = curValue;
        
        //! Add overdraw
        CGPoint F = ccpAdd(A, ccpMult(perpendicular, overdraw));
        CGPoint G = ccpAdd(C, ccpMult(perpendicular, overdraw));
        CGPoint H = ccpSub(B, ccpMult(perpendicular, overdraw));
        CGPoint I = ccpSub(D, ccpMult(perpendicular, overdraw));
        
        //! end vertices of last line are the start of this one, also for the overdraw
        if (connectingLine || index > 6) {
            F = prevG;
            H = prevI;
        }
        
        prevG = G;
        prevI = I;
        
        ADD_TRIANGLE(F, A, G, 2.0);
        ADD_TRIANGLE(A, G, C, 2.0);
        ADD_TRIANGLE(B, H, D, 2.0);
        ADD_TRIANGLE(H, D, I, 2.0);
    }
    
    [self fillLineTriangles:vertices count:index withColor:color];
    
    if (index > 0) {
        connectingLine = YES;
    }
    
    free(vertices);
}

- (void)fillLineEndPointAt:(CGPoint)center direction:(CGPoint)aLineDir radius:(CGFloat)radius andColor:(ccColor4F)color
{
    // Premultiplied alpha.
    color.r *= color.a;
    color.g *= color.a;
    color.b *= color.a;
    ccColor4F fadeOutColor = ccc4f(0, 0, 0, 0);
    
    const NSUInteger numberOfSegments = 32;
    LineVertex *vertices = malloc(sizeof(LineVertex) * numberOfSegments * 9);
    CGFloat anglePerSegment = (CGFloat)(M_PI / (numberOfSegments - 1));
    
    CGPoint perpendicular = ccpPerp(aLineDir);
    CGFloat angle = acosf(ccpDot(perpendicular, CGPointMake(0, 1)));
    CGFloat rightDot = ccpDot(perpendicular, CGPointMake(1, 0));
    if (rightDot < 0.0) {
        angle *= -1;
    }
    
    CGPoint prevPoint = center;
    CGPoint prevDir = ccp(sinf(0), cosf(0));
    for (NSUInteger i = 0; i < numberOfSegments; ++i) {
        CGPoint dir = ccp(sinf(angle), cosf(angle));
        CGPoint curPoint = ccp(center.x + radius * dir.x, center.y + radius * dir.y);
        vertices[i * 9 + 0].pos = center;
        vertices[i * 9 + 1].pos = prevPoint;
        vertices[i * 9 + 2].pos = curPoint;
        
        //! fill rest of vertex data
        for (NSUInteger j = 0; j < 9; ++j) {
            vertices[i * 9 + j].z = j < 3 ? 1.0 : 2.0;
            vertices[i * 9 + j].color = color;
        }
        
        //! add overdraw
        vertices[i * 9 + 3].pos = ccpAdd(prevPoint, ccpMult(prevDir, overdraw));
        vertices[i * 9 + 3].color = fadeOutColor;
        vertices[i * 9 + 4].pos = prevPoint;
        vertices[i * 9 + 5].pos = ccpAdd(curPoint, ccpMult(dir, overdraw));
        vertices[i * 9 + 5].color = fadeOutColor;
        
        vertices[i * 9 + 6].pos = prevPoint;
        vertices[i * 9 + 7].pos = curPoint;
        vertices[i * 9 + 8].pos = ccpAdd(curPoint, ccpMult(dir, overdraw));
        vertices[i * 9 + 8].color = fadeOutColor;
        
        prevPoint = curPoint;
        prevDir = dir;
        angle += anglePerSegment;
    }
    
    CCRenderer *renderer = [CCRenderer currentRenderer];
    GLKMatrix4 projection;
    [renderer.globalShaderUniforms[CCShaderUniformProjection] getValue:&projection];
    CCRenderBuffer buffer = [renderer enqueueTriangles:numberOfSegments * 3 andVertexes:numberOfSegments * 9 withState:self.renderState globalSortOrder:1];
    
    CCVertex vertex;
    for (NSUInteger i = 0; i < numberOfSegments * 9; i++) {
        vertex.position = GLKVector4Make(vertices[i].pos.x, vertices[i].pos.y, 0.0, 1.0);
        vertex.color = GLKVector4Make(vertices[i].color.r, vertices[i].color.g, vertices[i].color.b, vertices[i].color.a);
        CCRenderBufferSetVertex(buffer, (int)i, CCVertexApplyTransform(vertex, &projection));
    }
    
    for (NSUInteger i = 0; i < numberOfSegments * 3; i++) {
        CCRenderBufferSetTriangle(buffer, (int)i, i*3, (i*3)+1, (i*3)+2);
    }
    
    free(vertices);
}

- (void)fillLineTriangles:(LineVertex *)vertices count:(NSUInteger)count withColor:(ccColor4F)color
{
    if (!count) {
        return;
    }
    ccColor4F fullColor = color;
    fullColor.r *= fullColor.a;
    fullColor.g *= fullColor.a;
    fullColor.b *= fullColor.a;
    ccColor4F fadeOutColor = ccc4f(0, 0, 0, 0); // Premultiplied alpha.
    
    for (NSUInteger i = 0; i < count / 18; ++i) {
        for (NSUInteger j = 0; j < 6; ++j) {
            vertices[i * 18 + j].color = fullColor;
        }
        
        //! FAG
        vertices[i * 18 + 6].color = fadeOutColor;
        vertices[i * 18 + 7].color = fullColor;
        vertices[i * 18 + 8].color = fadeOutColor;
        
        //! AGD
        vertices[i * 18 + 9].color = fullColor;
        vertices[i * 18 + 10].color = fadeOutColor;
        vertices[i * 18 + 11].color = fullColor;
        
        //! BHC
        vertices[i * 18 + 12].color = fullColor;
        vertices[i * 18 + 13].color = fadeOutColor;
        vertices[i * 18 + 14].color = fullColor;
        
        //! HCI
        vertices[i * 18 + 15].color = fadeOutColor;
        vertices[i * 18 + 16].color = fullColor;
        vertices[i * 18 + 17].color = fadeOutColor;
    }
    
    CCRenderer *renderer = [CCRenderer currentRenderer];
    
    GLKMatrix4 projection;
    [renderer.globalShaderUniforms[CCShaderUniformProjection] getValue:&projection];
    CCRenderBuffer buffer = [renderer enqueueTriangles:count/3 andVertexes:count withState:self.renderState globalSortOrder:1];
    
    CCVertex vertex;
    for (NSUInteger i = 0; i < count; i++) {
        vertex.position = GLKVector4Make(vertices[i].pos.x, vertices[i].pos.y, 0.0, 1.0);
        vertex.color = GLKVector4Make(vertices[i].color.r, vertices[i].color.g, vertices[i].color.b, vertices[i].color.a);
        CCRenderBufferSetVertex(buffer, (int)i, CCVertexApplyTransform(vertex, &projection));
    }
    
    for (NSUInteger i = 0; i < count/3; i++) {
        CCRenderBufferSetTriangle(buffer, (int)i, i*3, (i*3)+1, (i*3)+2);
    }
    
    for (NSUInteger i = 0; i < circlesPoints.count / 2; ++i) {
        LinePoint *prevPoint = circlesPoints[i * 2];
        LinePoint *curPoint = circlesPoints[i * 2 + 1];
        CGPoint dirVector = ccpNormalize(ccpSub(curPoint.pos, prevPoint.pos));
        
        [self fillLineEndPointAt:curPoint.pos direction:dirVector radius:curPoint.width * 0.5 andColor:color];
    }
    
    [circlesPoints removeAllObjects];
}

- (NSMutableArray<LinePoint*>*)getSmoothLinePointsFor:(NSMutableArray<LinePoint*>*)linePoints
{
    if (linePoints.count > 2) {
        NSMutableArray<LinePoint*>* smoothedPoints = [NSMutableArray array];
        for (NSUInteger i = 2; i < linePoints.count; ++i) {
            LinePoint *prev2 = linePoints[i - 2];
            LinePoint *prev1 = linePoints[i - 1];
            LinePoint *cur = linePoints[i];
            
            CGPoint midPoint1 = ccpMult(ccpAdd(prev1.pos, prev2.pos), 0.5);
            CGPoint midPoint2 = ccpMult(ccpAdd(cur.pos, prev1.pos), 0.5);
            
            const NSUInteger segmentDistance = 2;
            CGFloat distance = ccpDistance(midPoint1, midPoint2);
            const NSUInteger numberOfSegments = MIN(128, MAX(floorf(distance / segmentDistance), 32));
            
            CGFloat t = 0.0;
            CGFloat step = 1.0 / numberOfSegments;
            for (NSUInteger j = 0; j < numberOfSegments; j++) {
                LinePoint *newPoint = [[LinePoint alloc] init];
                newPoint.pos = ccpAdd(ccpAdd(ccpMult(midPoint1, powf(1 - t, 2)), ccpMult(prev1.pos, 2.0 * (1 - t) * t)), ccpMult(midPoint2, t * t));
                newPoint.width = undoingPoints ? undoLineWidth : lineWidth;
                [smoothedPoints addObject:newPoint];
                t += step;
            }
            LinePoint *finalPoint = [[LinePoint alloc] init];
            finalPoint.pos = midPoint2;
            finalPoint.width = undoingPoints ? undoLineWidth : lineWidth;
            [smoothedPoints addObject:finalPoint];
        }
        return smoothedPoints;
    }
    return nil;
}

- (NSMutableArray<LinePoint*>*)calculateSmoothLinePoints
{
    NSMutableArray<LinePoint*>* smoothedPoints = [self getSmoothLinePointsFor:points];
    if (smoothedPoints)
    {
        // we need to leave last 2 points for next draw
        NSRange range = NSMakeRange(0, points.count - 2);
        [slicedPoints addObjectsFromArray:[points subarrayWithRange:range]];
        [points removeObjectsInRange:range];
    }
    return smoothedPoints;
}

- (NSMutableArray<LinePoint*>*)getUndoPoints
{
    if ([totalUndoPoints count] > 0)
    {
        NSMutableArray<LinePoint*>* drawPoints = [NSMutableArray array];
        if ([totalUndoPoints count] > 2000) // too many vertices to draw
        {
            NSRange range = NSMakeRange(0, 2000);
            [drawPoints  addObjectsFromArray:[totalUndoPoints subarrayWithRange:range]];
            [totalUndoPoints removeObjectsInRange:range];
        }
        else
        {
            [drawPoints addObjectsFromArray:totalUndoPoints];
            [totalUndoPoints removeAllObjects];
            // Undoing is tied with drawing a circle. Make this better!
            [self drawCircle];
            
            undoingPoints = NO;
        }
        
        connectingLine = NO;
        
        return drawPoints;
    }
    else if ([slicedPoints count] > 0)
    {
        totalUndoPoints = [self getSmoothLinePointsFor:slicedPoints];
        [slicedPoints removeAllObjects];
        
        // Too many vertices in one draw call will break cocos2d. Space it out
        return [self getUndoPoints];
    }
    else
    {
        // empty array
        undoingPoints = NO;
        return [NSMutableArray array];
    }
}

#pragma mark Draw Methods
- (void)draw:(CCRenderer *)renderer transform:(const GLKMatrix4 *)transform
{
    [renderTexture begin];
    ccColor4F color;
    NSMutableArray<LinePoint*>* smoothedPoints;
    if (undoingPoints)
    {
        // white
        color = ccc4f(1.f, 1.f, 1.f, 1.f);
        smoothedPoints = [self getUndoPoints];
    }
    else
    {
        smoothedPoints = [self calculateSmoothLinePoints];
        color = ccc4f(_red, _green, _blue, 1.f);
    }
    
    if (smoothedPoints)
    {
        [self drawLines:smoothedPoints withColor:color];
    }
    [renderTexture end];
}

- (void)drawCircle
{
    if ([circleHelper isCircle])
    {
        CGFloat radius = [circleHelper getRadius];
        CGPoint center = [circleHelper getCenter];
        CGFloat precision = 0.05;
        CGFloat circumference = 2 * M_PI;
        NSUInteger count = (circumference / precision);
        CGPoint* vertices = malloc(sizeof(CGPoint) * count);
        NSUInteger index = 0;
        for (CGFloat i = 0.0f; i < circumference; i += precision)
        {
            if (index < count)
            {
                CGFloat x = center.x + radius * cosf(i);
                CGFloat y = center.y + radius * sinf(i);
                vertices[index++] = CGPointMake(x, y);
            }
        }
        
        [drawNode drawPolyWithVerts:vertices count:count
                        fillColor:[CCColor colorWithCcColor4f:ccc4f(1.f, 1.f, 1.f, 1.f)]
                        borderWidth:lineWidth
                        borderColor:[CCColor colorWithCcColor4f:ccc4f(_red, _blue, _green, 1.f)]];
    }
}

#pragma mark - GestureRecognizer handling

- (void)validateCircle
{
    [slicedPoints addObjectsFromArray:points];
    NSMutableArray<LinePoint*>* smoothedPoints = [self getSmoothLinePointsFor:slicedPoints];
    [circleHelper update:smoothedPoints];
    CCLOG(@"Is a valid circle %d", [circleHelper isCircle]);
    undoingPoints = [circleHelper isCircle];
}

@end
