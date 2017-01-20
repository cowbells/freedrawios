//
//  DrawPanel.m
//  FreeDraw
//
//  Created by Raghav Janamanchi on 18/01/17.
//  Copyright © 2017 Apportable. All rights reserved.
//

#import "DrawPanel.h"

@implementation DrawPanel

- (id)initWithFrame:(CGRect)frame delegate:(id<DrawPanelDelegate>)delegate
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self setBackgroundColor:[UIColor groupTableViewBackgroundColor]];
        [[self layer] setMasksToBounds:YES];
        [[self layer] setCornerRadius:8.0];
        
        UIScrollView* scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
        scrollView.delaysContentTouches = NO;
        
        CGFloat initialOffset = 10.f;
        CGFloat contentWidth = initialOffset;
        CGRect backButtonFrame = CGRectMake(initialOffset, 30.f, 40.f, 40.f);
        UIButton* backButton = [[UIButton alloc] initWithFrame:backButtonFrame];
        [backButton setImage:[UIImage imageNamed:@"Back.png"] forState:UIControlStateNormal];
        [backButton addTarget:delegate action:@selector(backPressed:) forControlEvents:UIControlEventTouchUpInside];
        backButton.showsTouchWhenHighlighted = YES;
        [scrollView addSubview:backButton];
        contentWidth += backButtonFrame.size.width;
        
        CGFloat topOffset = 45.f;
        CGFloat sliderWidth = 100.f;
        CGFloat padding = 25.f;
        CGRect lineFrame = CGRectMake(backButtonFrame.origin.x + backButtonFrame.size.width + padding, topOffset, sliderWidth, 10.f);
        UISlider* lineSlider = [[UISlider alloc] initWithFrame:lineFrame];
        [lineSlider setValue:0.5f];
        [lineSlider setMinimumTrackTintColor:[UIColor darkGrayColor]];
        [lineSlider addTarget:delegate action:@selector(lineWidthChanged:) forControlEvents:UIControlEventValueChanged];
        [scrollView addSubview:lineSlider];
        contentWidth += (lineFrame.size.width + padding);
        
        padding = 12.f;
        CGRect redFrame = CGRectMake(lineFrame.origin.x + lineFrame.size.width + padding, topOffset, sliderWidth, 10.f);
        UISlider* redSlider = [[UISlider alloc] initWithFrame:redFrame];
        [redSlider setValue:0.5f];
        [redSlider setMinimumTrackTintColor:[UIColor redColor]];
        [redSlider addTarget:delegate action:@selector(redValueChanged:) forControlEvents:UIControlEventValueChanged];
        [scrollView addSubview:redSlider];
        contentWidth += (redFrame.size.width + padding);
        
        CGRect greenFrame = CGRectMake(redFrame.origin.x + redFrame.size.width + padding, topOffset, sliderWidth, 10.f);
        UISlider* greenSlider = [[UISlider alloc] initWithFrame:greenFrame];
        [greenSlider setValue:0.5f];
        [greenSlider setMinimumTrackTintColor:[UIColor greenColor]];
        [greenSlider addTarget:delegate action:@selector(greenValueChanged:) forControlEvents:UIControlEventValueChanged];
        [scrollView addSubview:greenSlider];
        contentWidth += (greenFrame.size.width + padding);
        
        CGRect blueFrame = CGRectMake(greenFrame.origin.x + greenFrame.size.width + padding, topOffset, sliderWidth, 10.f);
        UISlider* blueSlider = [[UISlider alloc] initWithFrame:blueFrame];
        [blueSlider setValue:0.5f];
        [blueSlider setMinimumTrackTintColor:[UIColor blueColor]];
        [blueSlider addTarget:delegate action:@selector(blueValueChanged:) forControlEvents:UIControlEventValueChanged];
        [scrollView addSubview:blueSlider];
        contentWidth += (blueFrame.size.width + padding);
        
        padding = 25.f;
        CGRect rulerButtonFrame = CGRectMake(blueFrame.origin.x + blueFrame.size.width + padding, 30.f, 40.f, 40.f);
        UIButton* rulerButton = [[UIButton alloc] initWithFrame:rulerButtonFrame];
        [rulerButton setImage:[UIImage imageNamed:@"RulerIcon.png"] forState:UIControlStateNormal];
        [rulerButton addTarget:delegate action:@selector(rulerToggle:) forControlEvents:UIControlEventTouchUpInside];
        rulerButton.showsTouchWhenHighlighted = YES;
        [scrollView addSubview:rulerButton];
        contentWidth += (rulerButtonFrame.size.width + padding);
        
        CGRect eraserButtonFrame = CGRectMake(rulerButtonFrame.origin.x + rulerButtonFrame.size.width + padding, 30.f, 40.f, 40.f);
        UIButton* eraserButton = [[UIButton alloc] initWithFrame:eraserButtonFrame];
        [eraserButton setBackgroundImage:[UIImage imageNamed:@"Eraser.png"] forState:UIControlStateNormal];
        [eraserButton addTarget:delegate action:@selector(eraserToggle:) forControlEvents:UIControlEventTouchUpInside];
        eraserButton.showsTouchWhenHighlighted = YES;
        [scrollView addSubview:eraserButton];
        contentWidth += (eraserButtonFrame.size.width + padding);
        
        UITapGestureRecognizer* tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:delegate action:@selector(showDrawPanel)];
        [self addGestureRecognizer:tapGesture];
        
        contentWidth += 10.f; // Padding at the end
        [scrollView setContentSize:CGSizeMake(contentWidth, frame.size.height)];
        [scrollView setScrollEnabled:YES];
        [self addSubview:scrollView];
    }
    return self;
}

@end
