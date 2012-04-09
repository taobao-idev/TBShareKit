//
//  UIImage+ImageWithName.m
//  taobao4iphone
//
//  Created by Xu Jiwei on 10-11-30.
//  Copyright 2010 Taobao.com. All rights reserved.
//

#import "UIImage+ImageWithName.h"

@implementation UIImage (ImageWithName)

+ (UIImage *)imageWithName:(NSString *)name {
    static float sysver = 0;
    if (sysver == 0) {
        sysver = [[[UIDevice currentDevice] systemVersion] floatValue];
    }
    
    if (sysver >= 4.0) {
        return [UIImage imageNamed:name];
    }
    
    if ([name length] > 4 && [[name substringFromIndex:[name length]-4] isEqualToString:@".png"]) {
        return [UIImage imageNamed:name];
    }
    
    return [UIImage imageNamed:[name stringByAppendingString:@".png"]];
}

@end