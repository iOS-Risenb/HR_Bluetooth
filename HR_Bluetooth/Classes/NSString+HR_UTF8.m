//
//  NSString+HR_UTF8.m
//  AFNetworking
//
//  Created by Obgniyum on 2017/11/22.
//

#import "NSString+HR_UTF8.h"

@implementation NSString (HR_UTF8)

- (NSString *)HR_UTF8 {
    return [NSString stringWithCString:[self UTF8String] encoding:NSUnicodeStringEncoding];
}

@end
