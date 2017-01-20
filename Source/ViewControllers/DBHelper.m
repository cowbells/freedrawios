//
//  DBHelper.m
//  FreeDraw
//
//  Created by Raghav Janamanchi on 14/01/17.
//  Copyright © 2017 Raghav Janamanchi. All rights reserved.
//  Singleton class to help with Core Data

#import "DBHelper.h"
#import <UIKit/UIKit.h>
#import "AppDelegate.h"

@implementation DatabaseHelper

+ (id)sharedDatabaseHelper
{
    static id _sharedObject = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedObject = [[self alloc] init];
    });
    return _sharedObject;
}

- (NSManagedObjectContext*)managedObjectContext
{
    NSManagedObjectContext *context = nil;
    id delegate = [[UIApplication sharedApplication] delegate];
    context = [[delegate persistentContainer] viewContext];
    return context;
}

- (NSArray<NSManagedObject*>*)getImages
{
    // Gets all the canvas images in DB
    NSManagedObjectContext *managedObjectContext = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:kEntityName];
    NSArray<NSManagedObject*>* canvases = [managedObjectContext executeFetchRequest:fetchRequest error:nil];
                    
    return canvases;
}

- (BOOL)insertImage:(NSData*)imageData imageId:(int32_t)imageId
{
    NSManagedObjectContext *context = [self managedObjectContext];
    NSManagedObject *canvas = [NSEntityDescription insertNewObjectForEntityForName:kEntityName inManagedObjectContext:context];
    
    [canvas setValue:imageData forKey:kImageDataKey];
    [canvas setValue:[NSNumber numberWithInteger:imageId] forKey:kImageIdKey];
    
    NSError *error = nil;
    if (![context save:&error])
    {
        // Cant save.
        return NO;
    }
    
    return YES;
}

- (BOOL)updateImage:(NSData*)imageData imageId:(int32_t)imageId
{
    NSManagedObjectContext *managedObjectContext = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:kEntityName];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"imageId == %d", imageId]];
    NSArray<NSManagedObject*>* results = [managedObjectContext executeFetchRequest:fetchRequest error:nil];
    
    if ([results count] > 0)
    {
        assert([results count] == 1);
        NSManagedObject* result = [results objectAtIndex:0];
        [result setValue:imageData forKey:kImageDataKey];
        
        NSError* error = nil;
        if (![managedObjectContext save:&error])
        {
            return NO;
        }
    }
    
    return YES;
}

- (BOOL)removeImage:(NSManagedObject*)canvas
{
    NSManagedObjectContext *context = [self managedObjectContext];
    [context deleteObject:canvas];
    
    NSError *error = nil;
    if (![context save:&error])
    {
        // Cant save.
        return NO;
    }
    return YES;
}

@end

