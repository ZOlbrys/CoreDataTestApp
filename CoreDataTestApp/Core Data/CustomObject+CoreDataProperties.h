//
//  CustomObject+CoreDataProperties.h
//  CoreDataTestApp
//
//  Created by Zach Olbrys on 4/16/18.
//  Copyright © 2018 Zach Olbrys. All rights reserved.
//
//

#import "CustomObject+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface CustomObject (CoreDataProperties)

+ (NSFetchRequest<CustomObject *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *identifier;

@end

NS_ASSUME_NONNULL_END
