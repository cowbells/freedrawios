//
//  DrawPanel.h
//  FreeDraw
//
//  Created by Raghav Janamanchi on 18/01/17.
//  Copyright © 2017 Apportable. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DrawPanelDelegate.h"

@interface DrawPanel : UIView

- (id)initWithFrame:(CGRect)frame delegate:(id<DrawPanelDelegate>)delegate;

@end
