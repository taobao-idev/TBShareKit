//
//  NSData+AES.h
//  ShareKit
//
//  Created by Xu Jiwei on 11-3-31.
//  Copyright 2011 Taobao.inc. All rights reserved.
//

#import <Foundation/Foundation.h>


#ifdef __cplusplus
extern "C" {
#endif
    NSString* AES256DecryptStringWithKey(NSData *data, NSData *key);
    NSData* AES256DecryptWithKey(NSData *data, NSData *key);
    NSData* AES256EncryptWithKey(NSData *data, NSData *key);
#ifdef __cplusplus
}
#endif
