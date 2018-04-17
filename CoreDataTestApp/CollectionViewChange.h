//
//  CollectionViewChange.h
//  CoreDataTestApp
//
//  Created by Zach Olbrys on 4/12/18.
//  Copyright © 2018 Zach Olbrys. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface CollectionViewChange : NSObject

- (instancetype)initWithChangeType:(NSFetchedResultsChangeType)changeType indexPaths:(NSArray<NSIndexPath *> *)indexPaths;

@property (nonatomic) NSFetchedResultsChangeType changeType;
@property (strong, nonatomic) NSArray<NSIndexPath *> *indexPaths;

@end
