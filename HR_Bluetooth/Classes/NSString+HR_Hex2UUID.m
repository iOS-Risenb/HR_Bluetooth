//
//  NSString+JQR_BT_UUID.m
//  BT_Center
//
//  Created by Obgniyum on 2017/11/8.
//  Copyright © 2017年 Risenb. All rights reserved.
//

#import "NSString+HR_Hex2UUID.h"

@implementation NSString (HR_Hex2UUID)

- (NSString *)HR_Hex2UUID {
    if (self.length <= 10) {
        return @"";
    }
    NSMutableString *temp = [NSMutableString stringWithString:self];
    [temp insertString:@"-" atIndex:10 * 2];
    [temp insertString:@"-" atIndex:8 * 2];
    [temp insertString:@"-" atIndex:6 * 2];
    [temp insertString:@"-" atIndex:4 * 2];
    return temp;
}

@end
