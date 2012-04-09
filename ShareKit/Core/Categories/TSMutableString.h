//
//  TSMutableString.h
//  TaobaoShare
//
//  Created by xiewenwei on 10-12-14.
//  Copyright 2010 Taobao.inc. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface TSMutableString : NSObject 
{
}
+ (NSString *)_generateTimestamp;
+ (NSString *)_generateNonce;
+ (NSString*)urlEncode:(NSString *)originalString stringEncoding:(NSStringEncoding)stringEncoding;
+ (NSString*)string:(NSString*)actionString URLencode:(NSStringEncoding)enc;
@end
