//
//  CoreDataController.h
//  CoreDataTestApp
//
//  Created by Zach Olbrys on 4/12/18.
//  Copyright © 2018 Zach Olbrys. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class CoreDataOperation;

@interface CoreDataController : NSObject

@property (nonatomic, strong, readonly) NSManagedObjectContext *managedObjectContext;

+ (CoreDataController *)sharedController;

- (void)reset;

@end
