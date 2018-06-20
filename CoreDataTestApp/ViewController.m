//
//  ViewController.m
//  CoreDataTestApp
//
//  Created by Zach Olbrys on 4/12/18.
//  Copyright © 2018 Zach Olbrys. All rights reserved.
//

#import "ViewController.h"
#import "CustomCell.h"
#import "CoreDataController.h"
#import "CustomObject+CoreDataClass.h"
#import "CollectionViewChange.h"

static NSString *const CUSTOM_CELL_REUSE_IDENTIFIER = @"CUSTOM_CELL_REUSE_IDENTIFIER";

@interface ViewController ()<UICollectionViewDataSource, UICollectionViewDelegate, NSFetchedResultsControllerDelegate>

@property (strong, nonatomic) IBOutlet UICollectionView *collectionView;
@property (strong, nonatomic) NSMutableArray<CollectionViewChange *> *collectionViewChanges;
@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;

@property (assign, nonatomic) NSTimeInterval controllerWillChangeContentCalledTime;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    
    [self setupFetchedResultsController];
}

- (void)setupFetchedResultsController {
    NSFetchRequest<CustomObject *> *fetchRequest = [CustomObject fetchRequest];
    fetchRequest.sortDescriptors = @[ [[NSSortDescriptor alloc] initWithKey:@"identifier" ascending:YES] ];
    
    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:[CoreDataController sharedController].mainManagedObjectContext sectionNameKeyPath:nil cacheName:nil];
    
    self.fetchedResultsController.delegate = self;
    
    NSTimeInterval startTime = [[NSDate date] timeIntervalSince1970];
    
    NSError *error;
    [self.fetchedResultsController performFetch:&error];
    if (error) {
        NSLog(@"ZAO error during setupFetchedResultsController fetch: %@", error);
    }
    
    [self.collectionView reloadData];
    
    NSTimeInterval fetchTime = [[NSDate date] timeIntervalSince1970] - startTime;
    NSLog(@"ZAO fetch and reloadData complete, took %f sec to fetch %lu object(s)", fetchTime, (unsigned long)self.fetchedResultsController.fetchedObjects.count);
    NSLog(@"*****");
}

- (void)addObjects:(NSUInteger)objectCount {
    NSTimeInterval startTime = [[NSDate date] timeIntervalSince1970];
    
    [[CoreDataController sharedController].privateManagedObjectContext performBlock:^{
        for (int i = 0; i < objectCount; i++) {
            CustomObject *object = [NSEntityDescription insertNewObjectForEntityForName:@"CustomObject" inManagedObjectContext:[CoreDataController sharedController].privateManagedObjectContext];
            object.identifier = [[NSUUID UUID] UUIDString];
        }
        
        NSTimeInterval addObjectsTime = [[NSDate date] timeIntervalSince1970] - startTime;
        NSLog(@"ZAO insert %lu object(s) complete, took %f sec", (unsigned long)objectCount, addObjectsTime);
        
        NSError *error;
        [[CoreDataController sharedController].privateManagedObjectContext save:&error];
        if (error) {
            NSLog(@"ZAO error during addObjects save: %@", error);
        }
    }];
}

- (void)removeObjects:(NSUInteger)objectCount {
    NSTimeInterval startTime = [[NSDate date] timeIntervalSince1970];
    
    [[CoreDataController sharedController].privateManagedObjectContext performBlock:^{
        NSFetchRequest<CustomObject *> *fetchRequest = [CustomObject fetchRequest];
        fetchRequest.sortDescriptors = @[ [[NSSortDescriptor alloc] initWithKey:@"identifier" ascending:YES] ];
        fetchRequest.fetchLimit = objectCount;
        
        NSFetchedResultsController<CustomObject *> *fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:[CoreDataController sharedController].privateManagedObjectContext sectionNameKeyPath:nil cacheName:nil];
        
        NSError *error;
        [fetchedResultsController performFetch:&error];
        if (error) {
            NSLog(@"ZAO error during removeObjects fetch: %@", error);
        }
        
        for (CustomObject *object in fetchedResultsController.fetchedObjects) {
            [[CoreDataController sharedController].privateManagedObjectContext deleteObject:object];
        }
        
        NSTimeInterval removeObjectsTime = [[NSDate date] timeIntervalSince1970] - startTime;
        NSLog(@"ZAO remove %lu object(s) complete, took %f sec", (unsigned long)objectCount, removeObjectsTime);
        
        NSError *saveError;
        [[CoreDataController sharedController].privateManagedObjectContext save:&saveError];
        if (saveError) {
            NSLog(@"ZAO error during removeObjects save: %@", error);
        }
    }];
}

- (IBAction)add10k:(id)sender {
    [self addObjects:10000];
}

- (IBAction)add1:(id)sender {
    [self addObjects:1];
}

- (IBAction)refetchData:(id)sender {
    NSTimeInterval startTime = [[NSDate date] timeIntervalSince1970];
    
    NSError *error;
    [self.fetchedResultsController performFetch:&error];
    if (error) {
        NSLog(@"ZAO error during refetchData fetch: %@", error);
    }
    
    [self.collectionView reloadData];
    
    NSTimeInterval fetchTime = [[NSDate date] timeIntervalSince1970] - startTime;
    NSLog(@"ZAO refetch and reloadData complete, took %f sec to fetch %lu object(s)", fetchTime, (unsigned long)self.fetchedResultsController.fetchedObjects.count);
    NSLog(@"*****");
}

- (IBAction)resetData:(id)sender {
    CoreDataController *coreDataController = [CoreDataController sharedController];
    
    [coreDataController reset];
    
    [self setupFetchedResultsController];
}

- (IBAction)remove1:(id)sender {
    [self removeObjects:1];
}

- (IBAction)remove10k:(id)sender {
    [self removeObjects:10000];
}

#pragma mark UICollectionViewDataSource

- (NSInteger)collectionView:(nonnull UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self.fetchedResultsController.sections objectAtIndex:section].numberOfObjects;
}

- (nonnull __kindof UICollectionViewCell *)collectionView:(nonnull UICollectionView *)collectionView cellForItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
    CustomCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:CUSTOM_CELL_REUSE_IDENTIFIER forIndexPath:indexPath];
    
    CustomObject *object = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    [cell setDisplayText:object.identifier];
    
    return cell;
}

#pragma mark NSFetchedResultsControllerDelegate

// TODO comment out these methods to see how quick adding/removing objects is!
- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    self.controllerWillChangeContentCalledTime = [[NSDate date] timeIntervalSince1970];
    NSLog(@"ZAO controllerWillChangeContent called");
    
    self.collectionViewChanges = [[NSMutableArray alloc] init];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
    switch (type) {
        case NSFetchedResultsChangeInsert: {
            [self.collectionViewChanges addObject:[[CollectionViewChange alloc] initWithChangeType:type indexPaths:@[newIndexPath]]];
            break;
        }

        case NSFetchedResultsChangeDelete: {
            [self.collectionViewChanges addObject:[[CollectionViewChange alloc] initWithChangeType:type indexPaths:@[indexPath]]];
            break;
        }

        case NSFetchedResultsChangeUpdate: {
            [self.collectionViewChanges addObject:[[CollectionViewChange alloc] initWithChangeType:type indexPaths:@[indexPath]]];
            break;
        }

        case NSFetchedResultsChangeMove: {
            [self.collectionViewChanges addObject:[[CollectionViewChange alloc] initWithChangeType:type indexPaths:@[indexPath, newIndexPath]]];
            break;
        }

        default:
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    NSTimeInterval delegateMethodTimeDifference = [[NSDate date] timeIntervalSince1970] - self.controllerWillChangeContentCalledTime;
    NSLog(@"ZAO controllerDidChangeContent called, %f sec since controllerWillChangeContent was called", delegateMethodTimeDifference);
    
    [self.collectionView performBatchUpdates:^{
        for (CollectionViewChange *collectionViewChange in self.collectionViewChanges) {
            switch (collectionViewChange.changeType) {
                case NSFetchedResultsChangeInsert:
                    [self.collectionView insertItemsAtIndexPaths:collectionViewChange.indexPaths];
                    break;

                case NSFetchedResultsChangeDelete:
                    [self.collectionView deleteItemsAtIndexPaths:collectionViewChange.indexPaths];
                    break;

                default:
                    break;
            }
        }
    } completion:nil];
}

@end

