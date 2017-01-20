//
//  DBHelper.h
//  FreeDraw
//
//  Created by Raghav Janamanchi on 14/01/17.
//  Copyright © 2017 Raghav Janamanchi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface DatabaseHelper : NSObject

+ (id)sharedDatabaseHelper;
- (NSArray<NSManagedObject*>*)getImages;
- (BOOL)insertImage:(NSData*)imageData imageId:(int32_t)imageId;
- (BOOL)removeImage:(NSManagedObject*)canvas;
- (BOOL)updateImage:(NSData*)imageData imageId:(int32_t)imageId;

@property(strong) NSManagedObject* currentCanvas;

@end
