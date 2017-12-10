//
//  NSData+HR_HexString.m
//  BT_Center
//
//  Created by Obgniyum on 2017/11/8.
//  Copyright © 2017年 Risenb. All rights reserved.
//

#import "NSData+HR_HexString.h"

@implementation NSData (HR_HexString)

- (NSString *)HR_HexString {
    if (!self || [self length] == 0) {
        return @"";
    }
    NSMutableString *string = [[NSMutableString alloc] initWithCapacity:[self length]];
    [self enumerateByteRangesUsingBlock:^(const void *bytes, NSRange byteRange, BOOL *stop) {
        unsigned char *dataBytes = (unsigned char*)bytes;
        for (NSInteger i = 0; i < byteRange.length; i++) {
            NSString *hexStr = [NSString stringWithFormat:@"%x", (dataBytes[i]) & 0xff];
            if ([hexStr length] == 2) {
                [string appendString:hexStr];
            } else {
                [string appendFormat:@"0%@", hexStr];
            }
        }
    }];
    
    return string;
}

@end
