//
//  CustomObject+CoreDataProperties.m
//  CoreDataTestApp
//
//  Created by Zach Olbrys on 4/16/18.
//  Copyright © 2018 Zach Olbrys. All rights reserved.
//
//

#import "CustomObject+CoreDataProperties.h"

@implementation CustomObject (CoreDataProperties)

+ (NSFetchRequest<CustomObject *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"CustomObject"];
}

@dynamic identifier;

@end
