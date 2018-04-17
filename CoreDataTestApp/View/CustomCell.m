//
//  CustomCell.m
//  CoreDataTestApp
//
//  Created by Zach Olbrys on 4/16/18.
//  Copyright © 2018 Zach Olbrys. All rights reserved.
//

#import "CustomCell.h"

@interface CustomCell()

@property (strong, nonatomic) IBOutlet UILabel *label;

@end

@implementation CustomCell

- (void)setDisplayText:(NSString *)displayText {
    self.label.text = displayText;
}

@end
