//
//  UIColor+HR_ChainProperty.h
//  HR_ChainProperty
//
//  Created by Obgniyum on 2017/12/21.
//

#import <UIKit/UIKit.h>

@interface UIColor (HR_ChainProperty)

+ (UIColor *(^)(NSUInteger))HR_Hex;

+ (UIColor *(^)(NSString *))HR_HexString;

+ (UIColor *(^)(unsigned int, unsigned int, unsigned int))HR_RGB;

@end
