//
//  SHKSina.m
//  ShareKit
//
//  Created by xiewenwei on 10-12-17.
//  Copyright 2010 Taobao.inc. All rights reserved.
//

#import "SHKSina.h"
#import "TSMutableString.h"

#import "JSON.h"

#import "NSData+AES.h"

@implementation SHKSina

@synthesize xAuth;

#pragma mark api

- (id)init
{
	if(self = [super init])
	{
		self.consumerKey = SHKSinaConsumerKey;//AES256DecryptStringWithKey(SHKSinaConsumerKey, AES_ENCRYPT_KEY);
		self.secretKey = SHKSinaSecret;//AES256DecryptStringWithKey(SHKSinaSecret, AES_ENCRYPT_KEY);
		self.authorizeCallbackURL = [NSURL URLWithString:CallBackURL];
		
		self.xAuth = NO;
		self.serviceStr = kSinaFlag;
		self.authorizeURL = [NSURL URLWithString:SINA_AuthorizeURL];
		self.requestURL = [NSURL URLWithString:SINA_RequestURL];
		self.accessURL = [NSURL URLWithString:SINA_AccessURL];
		self.accountURL = [NSURL URLWithString:SINA_AccountURL];
	}
	return self;
}

#pragma mark -
#pragma mark Configuration : Service Defination

+ (NSString *)sharerTitle
{
	return @"新浪微博";
}

+ (NSString *)sharerIcon
{
    return @"service_sina";
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
	return YES;
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
	//check whether userid existed
	if (userID == nil) {
		return;
	}
	
	SHKLog(@"%s", __FUNCTION__);
	
	OAMutableURLRequest *accountRequest = [[OAMutableURLRequest alloc] initWithURL:[NSURL URLWithString:[TSMutableString urlEncode:@"http://api.t.sina.com.cn/users/show.json" stringEncoding:NSUTF8StringEncoding]]
																		 consumer:consumer
																			token:accessToken
																			realm:nil
																signatureProvider:nil
																			nonce:[TSMutableString _generateNonce]
																		timestamp:[TSMutableString _generateTimestamp]
																	  serviceFlag:kSinaFlag];
	
	//豆瓣方法在这里修改 PUT DELETE POST
	
	[accountRequest setHTTPMethod:@"POST"];
	
	OARequestParameter *useridParam = [[OARequestParameter alloc] initWithName:@"user_id" value:userID];
    NSArray *params = [NSArray arrayWithObjects:useridParam, nil];
    [accountRequest setParameters:params];
	NSLog(@"params %@",params);
	[useridParam release];
	[self sendDidStart];
	OADataFetcher *fetcher = [[OADataFetcher alloc] init];
    [fetcher fetchDataWithRequest:accountRequest 
                         delegate:self
                didFinishSelector:@selector(accountTicket:didFinishWithData:)
                  didFailSelector:@selector(accountTicket:didFailWithError:)];
	[accountRequest release];
}

- (void)accountTicket:(OAServiceTicket *)ticket didFinishWithData:(NSData *)data 
{
	SHKLog(@"%s", __FUNCTION__);
	
	NSString * accountInfo = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	//SHKLog(@"account: %@", accountInfo);
	id account = [accountInfo JSONValue];
	if ([account isKindOfClass:[NSDictionary class]]) {
		//SHKLog(@"%@",(NSDictionary *)account);
		
		[SHK setAuthValue:[(NSDictionary *)account valueForKey:@"name"] forKey:kKeychainAccount forSharer:[self sharerId]];
	}
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
        // Notify delegate
		[self sendDidStart];
		if (item.shareType == SHKShareTypeImage) {
			//[self sendImage];
            [NSThread detachNewThreadSelector:@selector(sendImage) toTarget:self withObject:nil];
		} else {
			[self sendStatus];
		}
		
		return YES;
	}
	
	return NO;
}

- (void)sendStatus
{
	//OAPlaintextSignatureProvider *plaintextProvider = [[OAPlaintextSignatureProvider alloc] init];
	OAMutableURLRequest *statusRequest = [[OAMutableURLRequest alloc] initWithURL:[NSURL URLWithString:[TSMutableString urlEncode:@"http://api.t.sina.com.cn/statuses/update.json" stringEncoding:NSUTF8StringEncoding]]
																		   consumer:consumer
																			  token:accessToken
																			  realm:nil
																  signatureProvider:nil
																			  nonce:[TSMutableString _generateNonce]
																		  timestamp:[TSMutableString _generateTimestamp]
																		serviceFlag:kSinaFlag];
	
	//豆瓣方法在这里修改 PUT DELETE POST
	
	[statusRequest setHTTPMethod:@"POST"];
	
    OARequestParameter *descParam = [[OARequestParameter alloc] initWithName:@"status"
                                                                       value:item.text];
    NSArray *params = [NSArray arrayWithObjects:descParam, nil];
    [statusRequest setParameters:params];
	NSLog(@"params %@",params);
	[descParam release];
	//[self sendDidStart];
	OADataFetcher *fetcher = [[OADataFetcher alloc] init];
    [fetcher fetchDataWithRequest:statusRequest 
                         delegate:self
                didFinishSelector:@selector(sendStatusTicket:finishedWithData:)
                  didFailSelector:@selector(sendStatusTicket:failedWithError:)];
	[statusRequest release];
}

- (void)sendStatusTicket:(OAServiceTicket *)ticket finishedWithData:(NSMutableData *)data
{
	if (ticket.didSucceed) 
	{
		[self sendDidFinish];
		
		NSString *responseBody = [[NSString alloc] initWithData:data
													   encoding:NSUTF8StringEncoding];
		NSLog(@"api获取的数据:%@",responseBody);
		[responseBody release];
	}
	else
	{

	}
}

- (void)sendStatusTicket:(OAServiceTicket *)ticket failedWithError:(NSError *)error 
{
	NSLog(@"%@",error);
	[self sendDidFailWithError:error];
}

- (void)sendImage
{	
    NSAutoreleasePool * releasePool = [[NSAutoreleasePool alloc] init];
    
	 OAMutableURLRequest *oRequest = [[OAMutableURLRequest alloc] initWithURL:[NSURL URLWithString:[TSMutableString urlEncode:@"http://api.t.sina.com.cn/statuses/upload.json" stringEncoding:NSUTF8StringEncoding]]
												   consumer:consumer
													  token:accessToken
													  realm:nil 
										  signatureProvider:signatureProvider
													  nonce:[TSMutableString _generateNonce]
												  timestamp:[TSMutableString _generateTimestamp]
												serviceFlag:kSinaFlag];
	[oRequest setHTTPMethod:@"POST"];
	
	OARequestParameter *descParam = [[OARequestParameter alloc] initWithName:@"status"
                                                                       value:item.text];
    NSArray *params = [NSArray arrayWithObjects:descParam, nil];
    [oRequest setParameters:params];
	NSLog(@"params %@",params);
	[descParam release];
	
	[oRequest prepare];
	
	NSData * imageData = [self compressJPEGImage:[item image] withCompression:0.9f];
	[self prepareRequest:oRequest withMultipartFormData:imageData andContentKey:@"status"];
	
	// Notify delegate
	//[self sendDidStart];
	
	// Start the request
	OADataFetcher *fetcher = [[OADataFetcher alloc] init];
    [fetcher fetchDataWithRequest:oRequest 
                         delegate:self
                didFinishSelector:@selector(sendImageTicket:finishedWithData:)
                  didFailSelector:@selector(sendImageTicket:failedWithError:)];
	
	[oRequest release];
    
    [releasePool release];
}

- (void)sendImageTicket:(OAServiceTicket *)ticket finishedWithData:(NSMutableData *)data
{
	NSString *responseBody = [[NSString alloc] initWithData:data
												   encoding:NSUTF8StringEncoding];
	NSLog(@"api获取的数据:%@",responseBody);
	[responseBody release];
	if (ticket.didSucceed) {
		[self sendDidFinish];
		// Finished uploading Image, now need to posh the message and url in twitter
		NSString *responseBody = [[NSString alloc] initWithData:data
													   encoding:NSUTF8StringEncoding];
		//NSLog(@"api获取的数据:%@",responseBody);
		[responseBody release];
	} else {
        NSDictionary *responseJSON = [responseBody JSONValue];
        NSString *errorCodeString = [responseJSON valueForKey:@"error_code"];
        int errorCode = errorCodeString ? [errorCodeString intValue] : 0;
        NSLog(@"error:%@ code:%d", errorCodeString, errorCode);
        
        self.lastError = [NSError errorWithDomain:@"TBShareKit" code:errorCode userInfo:responseJSON];
		SHKLog(@"failed to send image ticket");
		[[SHKActivityIndicator currentIndicator] hide];
		[self sendDidFailWithError:self.lastError];
	}
}

- (void)sendImageTicket:(OAServiceTicket *)ticket failedWithError:(NSError *)error
{
	[[SHKActivityIndicator currentIndicator] hide];
	[self sendDidFailWithError:error];
	NSLog(@"error %@",error);
}


#pragma mark -
#pragma mark Override share failure to note user for accessor change

- (void)sharer:(SHKSharer *)sharer failedWithError:(NSError *)error shouldRelogin:(BOOL)shouldRelogin
{
    NSString *errorInfo = [error.userInfo valueForKey:@"error"];
    NSRange errorRange = [errorInfo rangeOfString:@"accessor was revoked"];
    if (errorRange.location != NSNotFound) {
        [[SHKActivityIndicator currentIndicator] hide];
        
        /*
        [[[[UIAlertView alloc] initWithTitle:@"错误"
                                     message:@"授权已经被取消，请删除帐号后重新授权"
                                    delegate:nil
                           cancelButtonTitle:@"关闭"
                           otherButtonTitles:nil] autorelease] show];*/
        
        [[self class] logout];
        
        [[self class] performSelector:@selector(shareItem:) onThread:[NSThread mainThread] withObject:self.item waitUntilDone:YES];
    }else {
        [super sharer:sharer failedWithError:error shouldRelogin:shouldRelogin];
    }
}

@end
