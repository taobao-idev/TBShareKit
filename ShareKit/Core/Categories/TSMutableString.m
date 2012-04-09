//
//  TSMutableString.m
//  TaobaoShare
//
//  Created by xiewenwei on 10-12-14.
//  Copyright 2010 Taobao.inc. All rights reserved.
//

#import "TSMutableString.h"


@implementation TSMutableString

+ (NSString*)urlEncode:(NSString *)originalString stringEncoding:(NSStringEncoding)stringEncoding {
    //!  @  $  &  (  )  =  +  ~  `  ;  '  :  ,  /  ?
    //%21%40%24%26%28%29%3D%2B%7E%60%3B%27%3A%2C%2F%3F
    NSArray *escapeChars = [NSArray arrayWithObjects://@";" , @"/" , @"?" , @":" ,
                            @"@" , @"&" ,
							//@"=" , @"+" ,    @"$" , @"," ,
                            @"!", @"'", @"(", @")", @"*", nil];
	
    NSArray *replaceChars = [NSArray arrayWithObjects://@"%3B" , @"%2F" , @"%3F" , @"%3A" , 
                             @"%40" , @"%26" , 
							 //@"%3D" , @"%2B" , @"%24" , @"%2C" ,
                             @"%21", @"%27", @"%28", @"%29", @"%2A", nil];
	
    int len = [escapeChars count];
	
    NSString *temp = [originalString stringByAddingPercentEscapesUsingEncoding:stringEncoding];
	
    int i;
    for(i = 0; i < len; i++)
    {
        temp = [temp stringByReplacingOccurrencesOfString:[escapeChars objectAtIndex:i]
                                               withString:[replaceChars objectAtIndex:i]
                                                  options:NSLiteralSearch
                                                    range:NSMakeRange(0, [temp length])];
    }
	
    NSString *out = [NSString stringWithString: temp];
	
    return out;
}

+ (NSString*)string:(NSString*)actionString URLencode:(NSStringEncoding)enc {
	NSMutableString *escaped = [NSMutableString string];
	[escaped setString:[actionString stringByAddingPercentEscapesUsingEncoding:enc]];
	[escaped replaceOccurrencesOfString:@"&" withString:@"%26" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [escaped length])];
	[escaped replaceOccurrencesOfString:@"+" withString:@"%2B" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [escaped length])];
	[escaped replaceOccurrencesOfString:@"," withString:@"%2C" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [escaped length])];
	[escaped replaceOccurrencesOfString:@"/" withString:@"%2F" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [escaped length])];
	[escaped replaceOccurrencesOfString:@":" withString:@"%3A" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [escaped length])];
	[escaped replaceOccurrencesOfString:@";" withString:@"%3B" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [escaped length])];
	[escaped replaceOccurrencesOfString:@"=" withString:@"%3D" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [escaped length])];
	[escaped replaceOccurrencesOfString:@"?" withString:@"%3F" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [escaped length])];
	[escaped replaceOccurrencesOfString:@"@" withString:@"%40" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [escaped length])];
	[escaped replaceOccurrencesOfString:@" " withString:@"+" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [escaped length])];
	[escaped replaceOccurrencesOfString:@"\t" withString:@"%09" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [escaped length])];
	[escaped replaceOccurrencesOfString:@"#" withString:@"%23" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [escaped length])];
	[escaped replaceOccurrencesOfString:@"<" withString:@"%3C" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [escaped length])];
	[escaped replaceOccurrencesOfString:@">" withString:@"%3E" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [escaped length])];
	[escaped replaceOccurrencesOfString:@"\"" withString:@"%22" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [escaped length])];
	[escaped replaceOccurrencesOfString:@"\n" withString:@"%0A" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [escaped length])];
	return escaped;
}


#pragma mark 获得时间戳
+ (NSString *)_generateTimestamp 
{
    return [NSString stringWithFormat:@"%d", time(NULL)];
}

#pragma mark 获得随时字符串
+ (NSString *)_generateNonce 
{
    CFUUIDRef theUUID = CFUUIDCreate(NULL);
    CFStringRef string = CFUUIDCreateString(NULL, theUUID);
    NSMakeCollectable(theUUID);
    return (NSString *)string;
}

@end
