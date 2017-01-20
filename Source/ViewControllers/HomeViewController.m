//
//  HomeViewController.m
//  FreeDraw
//
//  Created by Raghav Janamanchi on 14/01/17.
//  Copyright © 2017 Apportable. All rights reserved.
//  We insert nil for image data into the DB
//  This is okay for now as the cell background is white and so is the drawing canvas
//  Should revisit this

#import "HomeViewController.h"
#import "DBHelper.h"
#import "CollectionViewCell.h"
#import "AppDelegate.h"

@interface HomeViewController ()

@end

@implementation HomeViewController
{
    NSMutableArray<NSManagedObject*>* canvases;
    int itemsPerRow;
    UIEdgeInsets cellInsets;
    DatabaseHelper* helper;
}

@synthesize collectionView;

- (void)dismiss
{
    CCDirector* direction = [CCDirector sharedDirector];
    [direction dismissViewControllerAnimated:self completion:NULL];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    canvases = [NSMutableArray array];
    itemsPerRow = 3;
    cellInsets = UIEdgeInsetsMake(50.f, 20.f, 50.f, 20.f);
    helper = [DatabaseHelper sharedDatabaseHelper];
    
    UINib *cellNib = [UINib nibWithNibName:@"CollectionViewCell" bundle:nil];
    [self.collectionView registerNib:cellNib forCellWithReuseIdentifier:@"Cell"];
}

- (void)viewDidAppear:(BOOL)animated
{
    NSArray<NSManagedObject*>* images = [helper getImages];
    [canvases removeAllObjects];
    [canvases addObjectsFromArray:images];
    if ([images count] == 0)
    {
        // If there is no image, we create a default one
        [self addCanvas:nil];
    }
    else
    {
        [self reload];
    }
}

- (void)reload
{
    [self.collectionView reloadData];
}

- (void)addImage:(NSData*)data imageId:(int32_t)imageId
{
    [helper insertImage:data imageId:imageId];
    [canvases removeAllObjects];
    [canvases addObjectsFromArray:[helper getImages]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)addCanvas:(id)sender
{
    int32_t newId = (int32_t)[helper getImages].count;
    [self addImage:nil imageId:newId];
    [self reload];
}

- (UIImage*)imageForIndexPath:(NSIndexPath*)indexPath
{
    if ([canvases count] > indexPath.row)
    {
        NSManagedObject* managedObject = [canvases objectAtIndex:indexPath.row];
        NSData* imageData = [managedObject valueForKey:kImageDataKey];
        if (imageData != NULL)
        {
            UIImage* image = [UIImage imageWithData:imageData];
            return image;
        }
    }
    return nil;
}

#pragma CollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    id delegate = [[UIApplication sharedApplication] delegate];
    NSManagedObject* object = [canvases objectAtIndex:indexPath.row];
    [delegate runSceneWithManagedObject:object];
    [self dismiss];
}

#pragma CollectionViewDelegateFlowLayout
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat paddingSpace = cellInsets.left * (itemsPerRow + 1);
    CGFloat availableWidth = self.view.frame.size.width - paddingSpace;
    CGFloat widthPerItem = availableWidth / itemsPerRow;
    
    return CGSizeMake(widthPerItem, widthPerItem);
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    return cellInsets;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    return cellInsets.left;
}

#pragma CollectionViewDataSource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    // One section for now
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    // There is only one section
    return [canvases count];
}

// The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)_collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identifier = @"Cell";
    
    CollectionViewCell *cell = [_collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
    cell.imageView.image = [self imageForIndexPath:indexPath];
    cell.layer.borderWidth = 2.5f;
    cell.layer.borderColor = [UIColor blackColor].CGColor;
    cell.layer.cornerRadius = 2.5f;
    
    return cell;
}

@end
