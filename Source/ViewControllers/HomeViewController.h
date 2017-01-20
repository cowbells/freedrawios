//
//  HomeViewController.h
//  FreeDraw
//
//  Created by Raghav Janamanchi on 14/01/17.
//  Copyright © 2017 Apportable. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HomeViewController : UIViewController <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property(strong) IBOutlet UICollectionView* collectionView;
- (IBAction)addCanvas:(id)sender;

@end
