//
//  CollectionViewChange.m
//  CoreDataTestApp
//
//  Created by Zach Olbrys on 4/12/18.
//  Copyright © 2018 Zach Olbrys. All rights reserved.
//

#import "CollectionViewChange.h"

@implementation CollectionViewChange

- (instancetype)initWithChangeType:(NSFetchedResultsChangeType)type indexPaths:(NSArray<NSIndexPath *> *)indexPaths {
    self = [super init];
    
    if (self) {
        _changeType = type;
        _indexPaths = indexPaths;
    }
    
    return self;
}

@end
