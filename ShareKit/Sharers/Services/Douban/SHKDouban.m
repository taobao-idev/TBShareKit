//
//  SHKDouban.m
//  ShareKit
//
//  Created by xiewenwei on 10-12-17.
//  Copyright 2010 Taobao.inc. All rights reserved.
//

#import "SHKDouban.h"
#import "TSMutableString.h"

#import "JSON.h"
#import "NSData+AES.h"

@implementation SHKDouban

@synthesize xAuth;

#pragma mark api

- (id)init
{
	if(self = [super init])
	{
		self.consumerKey = DOUBAN_APPKEY;//AES256DecryptStringWithKey(DOUBAN_APPKEY, AES_ENCRYPT_KEY);
		self.secretKey = DOUBAN_APPSECRET;//AES256DecryptStringWithKey(DOUBAN_APPSECRET, AES_ENCRYPT_KEY);
		self.authorizeCallbackURL = [NSURL URLWithString:CallBackURL];
		
		self.xAuth = NO;
		
		self.authorizeURL = [NSURL URLWithString:DOUBAN_AuthorizeURL];
		self.requestURL = [NSURL URLWithString:DOUBAN_RequestURL];
		self.accessURL = [NSURL URLWithString:DOUBAN_AccessURL];
		self.accountURL = [NSURL URLWithString:DOUBAN_AccountURL];
	}
	return self;
}

#pragma mark -
#pragma mark Configuration : Service Defination

+ (NSString *)sharerTitle
{
	return @"豆瓣社区";
}

+ (NSString *)sharerIcon
{
    return @"service_douban";
}

+ (BOOL)canShareURL
{
	return YES;
}

+ (BOOL)canShareText
{
	return YES;
}

// TODO use img.ly to support this
+ (BOOL)canShareImage
{
	return NO;
}


#pragma mark -
#pragma mark Configuration : Dynamic Enable

/*
- (BOOL)shouldAutoShare
{
	return NO;
}*/


#pragma mark -
#pragma mark Authorization

- (BOOL)isAuthorized
{		
	return [self restoreAccessToken];
}

- (void)promptAuthorization
{		
	if (xAuth)
		[super authorizationFormShow]; // xAuth process
	
	else
		[super promptAuthorization]; // OAuth process		
}

- (BOOL)validate
{
	NSString *status = item.text;
	return status != nil && status.length <= 140;
}

- (void)accountWithUserId:(NSString *)userID 
{	
	if (userID == nil) {
		return;
	}
	
	SHKLog(@"%s", __FUNCTION__);
	
	NSURL * userAccountURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@", accountURL, userID]];
	OAMutableURLRequest *oRequest = [[OAMutableURLRequest alloc] initWithURL:userAccountURL
																	consumer:consumer
																	   token:accessToken
																	   realm:nil   // our service provider doesn't specify a realm
														   signatureProvider:signatureProvider
																	   nonce:[TSMutableString _generateNonce]
																   timestamp:[TSMutableString _generateTimestamp]
																 serviceFlag:kNotSinaFlag];
	
    [oRequest setHTTPMethod:@"GET"];
	
	[oRequest prepare];
	[self sendDidStart];
	
	OADataFetcher * fetcher = [[OADataFetcher alloc] init];
	[fetcher fetchDataWithRequest:oRequest delegate:self didFinishSelector:@selector(accountTicket: didFinishWithData:) didFailSelector:@selector(accountticket: didFailWithError:)];
    
	[oRequest release];
	[fetcher release];
}

- (void)accountTicket:(OAServiceTicket *)ticket didFinishWithData:(NSData *)data 
{
	SHKLog(@"%s", __FUNCTION__);
	
	NSString * accountInfo = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	SHKLog(@"account: %@", accountInfo);
	
	NSRange startRange = [accountInfo rangeOfString:@"<title>"];
	NSString * account = [accountInfo substringFromIndex:startRange.location+ startRange.length];
	NSRange endRange = [account rangeOfString:@"</title>"];
	account = [account substringToIndex:endRange.location];
	NSLog(@"account Name: %@", account);
	[SHK setAuthValue:account forKey:kKeychainAccount forSharer:[self sharerId]];
	
	[accountInfo release];
}

- (void)accountTicket:(OAServiceTicket *)ticket didFailWithError:(NSError *)error
{
	SHKLog(@"%s", __FUNCTION__);
}

- (BOOL)send
{	
	// Check if we should send follow request too
	//	if (xAuth && [item customBoolForSwitchKey:@"followMe"])
	//		[self followMe];	
	if (![self validate])
		[self show];
	
	else
	{
		if (item.shareType == SHKShareTypeImage) 
		{
			
		} 
		else 
		{
			[self sendStatus];
		}
		// Notify delegate
		//[self sendDidStart];	
		
		return YES;
	}
	
	return NO;
}

- (void)sendStatus
{	
	OAMutableURLRequest *hmacSha1Request = [[OAMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://api.douban.com/miniblog/saying"]
																		   consumer:consumer
																			  token:accessToken
																			  realm:nil
																  signatureProvider:signatureProvider
																			  nonce:[TSMutableString _generateNonce]
																		  timestamp:[TSMutableString _generateTimestamp]
																		serviceFlag:kNotSinaFlag];
	
	//豆瓣方法在这里修改 PUT DELETE POST
	[hmacSha1Request setHTTPMethod:@"POST"];
	[hmacSha1Request setValue:@"application/atom+xml" forHTTPHeaderField:@"Content-Type"];
	

	NSString *bodyMessage =[NSString stringWithFormat:
							@"<?xml version='1.0' encoding='UTF-8'?>"
							 "<entry xmlns:ns0=\"http://www.w3.org/2005/Atom\" xmlns:db=\"http://www.douban.com/xmlns/\">"
							 "<content>%@</content>"
							 "</entry>",item.text];	
	[hmacSha1Request prepare];
	
	[hmacSha1Request setHTTPBody:[bodyMessage dataUsingEncoding:NSUTF8StringEncoding]];
	
	[self sendDidStart];
	OADataFetcher *fetcher = [[OADataFetcher alloc] init];
    [fetcher fetchDataWithRequest:hmacSha1Request 
                         delegate:self
                didFinishSelector:@selector(sendStatusTicket:finishedWithData:)
                  didFailSelector:@selector(sendStatusTicket:failedWithError:)];
	
	[hmacSha1Request release];
}

- (void)sendStatusTicket:(OAServiceTicket *)ticket finishedWithData:(NSMutableData *)data
{
	
	NSString *responseBody = [[NSString alloc] initWithData:data
												   encoding:NSUTF8StringEncoding];
	NSLog(@"api获取的数据:%@",responseBody);
	
	[responseBody release];
	
	if (ticket.didSucceed) 
	{
		[self sendDidFinish];
		
		/*
		NSString *responseBody = [[NSString alloc] initWithData:data
													   encoding:NSUTF8StringEncoding];
		NSLog(@"api获取的数据:%@",responseBody);
		
		[responseBody release];
		 */
		
		[[SHKActivityIndicator currentIndicator] hide];
	}
	else
	{
		
	}
}

- (void)sendStatusTicket:(OAServiceTicket *)ticket failedWithError:(NSError*)error
{
	NSLog(@"%@",error);
	[self sendDidFailWithError:error];
}


#pragma mark -
#pragma mark Override share failure to note user for accessor change

- (void)sharer:(SHKSharer *)sharer failedWithError:(NSError *)error shouldRelogin:(BOOL)shouldRelogin
{
    //[[SHKActivityIndicator currentIndicator] hide];
    if ([NSThread isMainThread]) {
        [self performSelector:@selector(hideActivityView:) withObject:nil afterDelay:1.0];
    }else {
        [self performSelectorOnMainThread:@selector(hideActivityView:) withObject:nil waitUntilDone:[NSThread isMainThread]];
    }
    
    NSString *errorInfo = @"发生错误，可能授权已经被取消，请删除帐号后重新授权";
    NSString *msgInfo = [NSString stringWithFormat:@"分享到%@%@", [[self class] sharerTitle], errorInfo];
    
    [[[[UIAlertView alloc] initWithTitle:@"错误"
                                 message:msgInfo
                                delegate:nil
                       cancelButtonTitle:@"关闭"
                       otherButtonTitles:nil] autorelease] show];
}

@end
