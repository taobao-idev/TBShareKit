//
//  SHKSina.h
//  ShareKit
//
//  Created by xiewenwei on 10-12-17.
//  Copyright 2010 Taobao.inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SHKOAuthSharer.h"

@interface SHKSina : SHKOAuthSharer {
	BOOL xAuth;
}
@property BOOL xAuth;

- (void)sendStatus;
- (void)sendStatusTicket:(OAServiceTicket *)ticket finishedWithData:(NSMutableData *)data;
- (void)sendStatusTicket:(OAServiceTicket *)ticket failedWithError:(NSError *)error;
- (void)sendImage;
- (void)sendImageTicket:(OAServiceTicket *)ticket finishedWithData:(NSMutableData *)data;
- (void)sendImageTicket:(OAServiceTicket *)ticket failedWithError:(NSError *)error;
@end
