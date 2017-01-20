//
//  DrawPanelDelegate.h
//  FreeDraw
//
//  Created by Raghav Janamanchi on 18/01/17.
//  Copyright © 2017 Apportable. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol DrawPanelDelegate <NSObject>

@required
- (void)showDrawPanel;
- (void)lineWidthChanged:(id)sender;
- (void)redValueChanged:(id)sender;
- (void)greenValueChanged:(id)sender;
- (void)blueValueChanged:(id)sender;
- (void)rulerToggle:(id)sender;
- (void)eraserToggle:(id)sender;
- (void)backPressed:(id)sender;

@end
