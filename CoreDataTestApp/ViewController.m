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
    
    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:[CoreDataController sharedController].managedObjectContext sectionNameKeyPath:nil cacheName:nil];
    
    self.fetchedResultsController.delegate = self;
    
    [self.fetchedResultsController performFetch:nil];
    
    [self.collectionView reloadData];
}

- (void)addObjects:(NSUInteger)objectCount {
    NSManagedObjectContext *temporaryContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    temporaryContext.parentContext = [CoreDataController sharedController].managedObjectContext;
    
    NSTimeInterval startTime = [[NSDate date] timeIntervalSince1970];
    
    [temporaryContext performBlock:^{
        for (int i = 0; i < objectCount; i++) {
            CustomObject *object = [NSEntityDescription insertNewObjectForEntityForName:@"CustomObject" inManagedObjectContext:temporaryContext];
            object.identifier = [[NSUUID UUID] UUIDString];
        }
        
        NSTimeInterval objectsCreatedEndTime = [[NSDate date] timeIntervalSince1970];
        NSTimeInterval objectsCreatedTime = objectsCreatedEndTime - startTime;
        NSLog(@"ZAO TRACE took %f seconds to add %lu object(s)", objectsCreatedTime, (unsigned long)objectCount);
        
        NSTimeInterval tempMOCSaveStartTime = [[NSDate date] timeIntervalSince1970];
        
        NSError *error;
        if (![temporaryContext save:&error]) {
            NSLog(@"Error: %@", error);
        }
        
        NSTimeInterval tempMOCSaveEndTime = [[NSDate date] timeIntervalSince1970];
        NSTimeInterval tempMOCSaveTime = tempMOCSaveEndTime - tempMOCSaveStartTime;
        NSTimeInterval totalTimeSoFar = tempMOCSaveEndTime - startTime;
        NSLog(@"ZAO TRACE took %f seconds to save %lu object(s) to temp MOC - %f seconds on background thread", totalTimeSoFar, (unsigned long)objectCount, tempMOCSaveTime);
        
        [[CoreDataController sharedController].managedObjectContext performBlock:^{
            NSTimeInterval mainMOCSaveStartTime = [[NSDate date] timeIntervalSince1970];
            
            NSError *error;
            if (![[CoreDataController sharedController].managedObjectContext save:&error]) {
                NSLog(@"Error: %@", error);
            }
            
            NSTimeInterval mainMOCSaveEndTime = [[NSDate date] timeIntervalSince1970];
            NSTimeInterval mainMOCSaveTime = mainMOCSaveEndTime - mainMOCSaveStartTime;
            NSTimeInterval totalTimeSoFar = mainMOCSaveEndTime - startTime;
            NSLog(@"ZAO TRACE took %f seconds to save %lu object(s) to main MOC - %f seconds on main thread", totalTimeSoFar, (unsigned long)objectCount, mainMOCSaveTime);
        }];
    }];
}

- (void)removeObjects:(NSUInteger)objectCount {
    NSManagedObjectContext *temporaryContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    temporaryContext.parentContext = [CoreDataController sharedController].managedObjectContext;
    
    [temporaryContext performBlock:^{
        NSFetchRequest<CustomObject *> *fetchRequest = [CustomObject fetchRequest];
        fetchRequest.sortDescriptors = @[ [[NSSortDescriptor alloc] initWithKey:@"identifier" ascending:YES] ];
        fetchRequest.fetchLimit = objectCount;
        
        NSFetchedResultsController<CustomObject *> *fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:temporaryContext sectionNameKeyPath:nil cacheName:nil];
        
        [fetchedResultsController performFetch:nil];
        
        for (CustomObject *object in fetchedResultsController.fetchedObjects) {
            [temporaryContext deleteObject:object];
        }
        
        NSError *error;
        if (![temporaryContext save:&error]) {
            NSLog(@"Error: %@", error);
        }
        
        [[CoreDataController sharedController].managedObjectContext performBlock:^{
            NSError *error;
            if (![[CoreDataController sharedController].managedObjectContext save:&error]) {
                NSLog(@"Error: %@", error);
            }
        }];
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
    
    [self.fetchedResultsController performFetch:nil];
    
    NSTimeInterval endTime = [[NSDate date] timeIntervalSince1970];
    NSTimeInterval fetchTime = endTime - startTime;
    NSLog(@"ZAO TRACE took %f seconds to fetch %lu object(s)", fetchTime, (unsigned long)self.fetchedResultsController.fetchedObjects.count);
    
    [self.collectionView reloadData];
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
    
    [cell setDisplayText:@"TODO"];
    
    cell.backgroundColor = [UIColor blueColor];
    
    return cell;
}

#pragma mark NSFetchedResultsControllerDelegate

//- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
//        self.collectionViewChanges = [[NSMutableArray alloc] init];
//}
//
//- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
//
//    switch (type) {
//        case NSFetchedResultsChangeInsert: {
//            [self.collectionViewChanges addObject:[[CollectionViewChange alloc] initWithChangeType:type indexPaths:@[newIndexPath]]];
//            break;
//        }
//
//        case NSFetchedResultsChangeDelete: {
//            [self.collectionViewChanges addObject:[[CollectionViewChange alloc] initWithChangeType:type indexPaths:@[indexPath]]];
//            break;
//        }
//
//        case NSFetchedResultsChangeUpdate: {
//            [self.collectionViewChanges addObject:[[CollectionViewChange alloc] initWithChangeType:type indexPaths:@[indexPath]]];
//            break;
//        }
//
//        case NSFetchedResultsChangeMove: {
//            [self.collectionViewChanges addObject:[[CollectionViewChange alloc] initWithChangeType:type indexPaths:@[indexPath, newIndexPath]]];
//            break;
//        }
//
//        default:
//            break;
//    }
//}
//
//- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
//    [self.collectionView performBatchUpdates:^{
//        for (CollectionViewChange *collectionViewChange in self.collectionViewChanges) {
//            switch (collectionViewChange.changeType) {
//                case NSFetchedResultsChangeInsert:
//                    [self.collectionView insertItemsAtIndexPaths:collectionViewChange.indexPaths];
//                    break;
//
//                case NSFetchedResultsChangeDelete:
//                    [self.collectionView deleteItemsAtIndexPaths:collectionViewChange.indexPaths];
//                    break;
//
//                default:
//                    break;
//            }
//        }
//    } completion:nil];
//}

@end

