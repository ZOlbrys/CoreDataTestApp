//
//  CoreDataController.m
//  CoreDataTestApp
//
//  Created by Zach Olbrys on 4/12/18.
//  Copyright © 2018 Zach Olbrys. All rights reserved.
//

#import "CoreDataController.h"
#import <UIKit/UIKit.h>

@interface CoreDataController()

@property (nonatomic, strong) NSURL *persistentStoreURL;
@property (nonatomic, strong) NSURL *managedObjectModelURL;

@property (nonatomic, strong, readwrite) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, strong) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, strong, readwrite) NSManagedObjectContext *mainManagedObjectContext;
@property (nonatomic, strong, readwrite) NSManagedObjectContext *privateManagedObjectContext;

@end

@implementation CoreDataController

+ (CoreDataController *)sharedController {
    static CoreDataController *sharedController;
    
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        NSURL *managedObjectModelURL = [NSURL fileURLWithPath:[[NSBundle bundleForClass:[self class]] pathForResource:@"CoreDataTestApp" ofType:@"momd"]];
        
        NSString *applicationDocumentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
        NSURL *persistentStoreURL = [NSURL fileURLWithPath:[applicationDocumentsDirectory stringByAppendingPathComponent:@"CoreDataTestApp.sqlite"]];
        
        sharedController = [[CoreDataController alloc] initWithManagedObjectModelURL:managedObjectModelURL persistentStoreURL:persistentStoreURL];
    });
    
    return sharedController;
}

- (instancetype)initWithManagedObjectModelURL:(NSURL*)managedObjectModelURL persistentStoreURL:(NSURL*)persistentStoreURL {
    self = [super init];
    
    if (self) {
        self.persistentStoreURL = persistentStoreURL;
        self.managedObjectModelURL = managedObjectModelURL;
        
        [self setupCoreDataStack];
    }
    
    return self;
}

- (void)setupCoreDataStack {
    // setup managed object model
    self.managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:self.managedObjectModelURL];
    
    // setup persistent store coordinator
    self.persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.managedObjectModel];
    [self.persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:self.persistentStoreURL options:nil error:nil];
    
    // create MOCs
    self.mainManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    self.privateManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    
    [self.mainManagedObjectContext setPersistentStoreCoordinator:self.persistentStoreCoordinator];
    [self.privateManagedObjectContext setPersistentStoreCoordinator:self.persistentStoreCoordinator];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:NSManagedObjectContextDidSaveNotification
                                                      object:nil
                                                       queue:nil
                                                  usingBlock:^(NSNotification* note) {
                                                      NSManagedObjectContext *moc = self.mainManagedObjectContext;
                                                      
                                                      if (note.object != moc) {
                                                          [moc performBlock:^(){
                                                              [moc mergeChangesFromContextDidSaveNotification:note];
                                                          }];
                                                      }
                                                  }];
}

- (void)reset {
    // Delete persistent stores
    [self deletePersistentStores];
    
    self.persistentStoreCoordinator = nil;
    self.managedObjectModel = nil;
    self.mainManagedObjectContext = nil;
    self.privateManagedObjectContext = nil;
    
    // Re-create MOC stack
    [self setupCoreDataStack];
}

- (void)deletePersistentStores {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    for (NSPersistentStore *s in [self.persistentStoreCoordinator persistentStores]) {
        NSError *error = nil;
        NSString *path = [[s URL] path];
        
        [self.persistentStoreCoordinator removePersistentStore:s error:&error];
        
        if (error) {
            NSLog(@"Error deleting persistent store: %@", error);
        } else {
            if ([fileManager fileExistsAtPath:path]) {
                error = nil;
                [fileManager removeItemAtPath:path error:&error];
                if (error) {
                    NSLog(@"Error deleting item at path (%@): %@", path, error);
                }
            }
        }
    }
}

@end
