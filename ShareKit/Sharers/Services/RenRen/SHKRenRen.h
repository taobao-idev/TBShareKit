//
//  SHKRenRen.h
//  ShareKit
//
//  Created by xiewenwei on 10-12-22.
//  Copyright 2010 Taobao.inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SHKSharer.h"
#import "Connect.h"

@interface SHKRenRen : SHKSharer<SessionDelegate, RequestDelegate> {
	Session* session;
}
@property(nonatomic, retain)Session* session;
- (void)sendStatus;
- (void)sendImage;
@end
