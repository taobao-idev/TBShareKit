//
//SHKTencent.m
// ShareKit
//
//Created by xiewenwei on 10 - 12 - 20.
// Copyright 2010 Taobao.inc.All rights reserved.
//
#include <ifaddrs.h>
#include <arpa/inet.h>

#import "SHKTencent.h"
#import "TSMutableString.h"

#import "JSON.h"

#define RETURN_CODE_NO_ERROR 0

@implementation SHKTencent

@ synthesize xAuth;

#pragma mark api

- (id)init 
{
	if (self =[super init]) {
		self.consumerKey = QQ_APPKEY;
		self.secretKey = QQ_APPSECRET;
		self.authorizeCallbackURL =[NSURL URLWithString:CallBackURL];

		self.xAuth = NO;

		self.serviceStr = kTencentFlag;
		self.authorizeURL =[NSURL URLWithString:QQ_AuthorizeURL];
		self.requestURL =[NSURL URLWithString:QQ_RequestURL];
		self.accessURL =[NSURL URLWithString:QQ_AccessURL];
		self.accountURL = [NSURL URLWithString:QQ_AccountURL];
	}
	return self;
}

#pragma mark -
#pragma mark Configuration : Service Defination

+ (NSString *)sharerTitle 
{
	return @"腾讯微博";
}

+ (NSString *)sharerIcon
{
    return @"service_tencent";
}

+ (BOOL)canShareURL 
{
	return YES;
}

+ (BOOL)canShareText 
{
	return YES;
}

//TODO use img.ly to support this
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
	return[self restoreAccessToken];
}

- (void)promptAuthorization 
{
	if (xAuth)
		[super authorizationFormShow];
	//xAuth process

		else
		[super promptAuthorization];
	//OAuth process
}

- (BOOL)validate 
{
	[item setCustomValue: @"分享到腾讯微博" forKey:@"status"];
	NSString * status =[item customValueForKey:@"status"];
	return status != nil && status.length <= 140;
}

- (BOOL)send 
{
	//Check if we should send follow request too
// if (xAuth &&[item customBoolForSwitchKey:@"followMe"])
			//[self followMe];
	if (![self validate])
		[self show];

	else {
		if (item.shareType == SHKShareTypeImage) {
			[self sendImage];
		} else {
			[self sendStatus];
		}
		//Notify delegate
		[self sendDidStart];

		return YES;
	}

	return NO;
}

- (void)accountWithUserId:(NSString *)userID 
{
	SHKLog(@"%s", __FUNCTION__);
	
	//NSString * getAccountURL = [NSString stringWithFormat:@"%@?format=%@", [accountURL absoluteURL], @"json"];
	NSString *generatedNonce =[TSMutableString _generateNonce];
	if ([generatedNonce length] > NONCE_LENGTH_FOR_TENCENT) {
		generatedNonce =[generatedNonce substringToIndex:NONCE_LENGTH_FOR_TENCENT];
	}
	OAMutableURLRequest *oRequest = [[OAMutableURLRequest alloc] initWithURL:accountURL
																	consumer:consumer
																	   token:accessToken
																	   realm:nil   // our service provider doesn't specify a realm
														   signatureProvider:signatureProvider
																	   nonce:generatedNonce
																   timestamp:[TSMutableString _generateTimestamp]
																 serviceFlag:serviceStr];
	
    [oRequest setHTTPMethod:@"GET"];
	OARequestParameter *formatParam =[[OARequestParameter alloc] initWithName:@"format" value:@"json"];
	NSArray *params =[NSArray arrayWithObjects:formatParam, nil];
	[oRequest setParameters:params];
	[formatParam release];
	
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
	id account = [accountInfo JSONValue];
	if ([account isKindOfClass:[NSDictionary class]]) {
		SHKLog(@"%@",(NSDictionary *)account);
	}
	[accountInfo release];
}

- (void)accountTicket:(OAServiceTicket *)ticket didFailWithError:(NSError *)error
{
	SHKLog(@"%s", __FUNCTION__);
}

- (void)sendStatus 
{
	NSString *generatedNonce =[TSMutableString _generateNonce];
	if ([generatedNonce length] > NONCE_LENGTH_FOR_TENCENT) {
		generatedNonce =[generatedNonce substringToIndex:NONCE_LENGTH_FOR_TENCENT];
	}
	OAMutableURLRequest *hmacSha1Request =[[OAMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://open.t.qq.com/api/t/add"]
					       consumer:consumer
					       token:accessToken
					       realm:nil
						   signatureProvider:signatureProvider
					       nonce:generatedNonce
						   timestamp:[TSMutableString _generateTimestamp]
					       serviceFlag:serviceStr];


	[hmacSha1Request setHTTPMethod:@"POST"];

	OARequestParameter *formatParam =[[OARequestParameter alloc] initWithName:@"format" value:@"json"];
	OARequestParameter *contentParam =[[OARequestParameter alloc] initWithName:@"content" value:[item text]];
	OARequestParameter *ipParam =[[OARequestParameter alloc] initWithName:@"clientip" value:[self getIPAddress]];
	NSArray *params =[NSArray arrayWithObjects:formatParam, contentParam, ipParam, nil];
	[hmacSha1Request setParameters:params];
	[formatParam release];
	[contentParam release];
	[ipParam release];

	[hmacSha1Request prepare];

	[self sendDidStart];
	OADataFetcher  *fetcher =[[OADataFetcher alloc] init];
	[fetcher fetchDataWithRequest:hmacSha1Request
				delegate:self
				didFinishSelector: @selector(sendStatusTicket: finishedWithData:)
				didFailSelector: @selector(sendStatusTicket: failedWithError:)];

	[hmacSha1Request release];
	[fetcher release];
}

- (void)sendStatusTicket:(OAServiceTicket *)ticket finishedWithData:(NSMutableData *) data 
{
	if (ticket.didSucceed) {
		[self sendDidFinish];
		[self handleResponseData:data];
	} else {
		
	}
}

- (void)sendStatusTicket:(OAServiceTicket *)ticket failedWithError:(NSError *) error 
{
	NSLog(@"%@", error);
	[self sendDidFailWithError:error];
}

- (void)sendImage 
{
	SHKLog(@"%s", __FUNCTION__);

	NSString *generatedNonce =[TSMutableString _generateNonce];
	if ([generatedNonce length] > NONCE_LENGTH_FOR_TENCENT) {
		generatedNonce =[generatedNonce substringToIndex:NONCE_LENGTH_FOR_TENCENT];
	}
	
	OAMutableURLRequest *oRequest =[[OAMutableURLRequest alloc] initWithURL:[NSURL URLWithString:[TSMutableString urlEncode:@"http://open.t.qq.com/api/t/add_pic" stringEncoding:NSUTF8StringEncoding]]
																consumer:consumer
																token:accessToken
																realm:nil
																signatureProvider:signatureProvider
																nonce:generatedNonce
																timestamp:[TSMutableString _generateTimestamp]
																serviceFlag:kTencentFlag];
	[oRequest setHTTPMethod:@"POST"];

	OARequestParameter *formatParam =[[OARequestParameter alloc] initWithName:@"format" value:@"json"];
	OARequestParameter *descParam =[[OARequestParameter alloc] initWithName:@"content" value:item.text];
	OARequestParameter *ipParam =[[OARequestParameter alloc] initWithName:@"clientip" value:[self getIPAddress]];
	NSArray *params =[NSArray arrayWithObjects:formatParam, descParam, ipParam, nil];
	[oRequest setParameters:params];
	[formatParam release];
	[descParam release];
	[ipParam release];

	[oRequest prepare];

	NSData *imageData =[self compressJPEGImage:[item image] withCompression:0.9f];
	[self prepareRequest:oRequest withMultipartFormData:imageData andContentKey:@"content"];
	
	//Notify delegate
	[self sendDidStart];

	//Start the request
	OADataFetcher *fetcher =[[OADataFetcher alloc] init];
	[fetcher fetchDataWithRequest:oRequest
				delegate:self
				didFinishSelector: @selector(sendImageTicket: finishedWithData:)
				didFailSelector: @selector(sendImageTicket: failedWithError:)];

	[oRequest release];
	[fetcher release];
}

- (void)sendImageTicket:(OAServiceTicket *)ticket finishedWithData:(NSMutableData *) data 
{
	if (ticket.didSucceed) {
		[self sendDidFinish];
		//Finished uploading Image, now need to posh the message and url in twitter
		[self handleResponseData:data];
	} else {
		[self sendDidFailWithError:nil];
	}
}

- (void)sendImageTicket:(OAServiceTicket *)ticket failedWithError:(NSError *) error 
{
	[self sendDidFailWithError:error];
}

- (NSString *)getIPAddress 
{
	NSString *address = @"error";
	struct ifaddrs *interfaces = NULL;
	struct ifaddrs *temp_addr = NULL;
	int success = 0;

	//retrieve the current interfaces - returns 0 on success
	success = getifaddrs(&interfaces);
	if (success == 0) {
		//Loop through linked list of interfaces
		temp_addr = interfaces;
		while (temp_addr != NULL) {
			if (temp_addr->ifa_addr->sa_family == AF_INET) {
				//Check if interface is en0 which is the wifi connection on the iPhone
				if ([[NSString stringWithUTF8String: temp_addr->ifa_name] isEqualToString:@"en0"]) {
					//Get NSString from C String
					address =[NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *) temp_addr->ifa_addr)->sin_addr)];
				}
			}
			temp_addr = temp_addr->ifa_next;
		}
	}
	//Free memory
	freeifaddrs(interfaces);
	SHKLog(@"current address: %@", address);
	return address;
}

- (void)handleResponseData:(NSData *)data
{
	NSString *responseBody =[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	SHKLog(@"api获取的数据:%@", responseBody);
	id jsonObject = [responseBody JSONValue];
	if ([jsonObject isKindOfClass:[NSDictionary class]]) {
		NSDictionary * responseDictionary = jsonObject;
		NSString *retCode= [responseDictionary valueForKey:@"ret"];
		NSString *retMsg = [responseDictionary valueForKey:@"msg"];
		if ([retCode intValue] != RETURN_CODE_NO_ERROR) {
			NSString *msgContent = [NSString stringWithFormat:@"ReturnCode:%d Message:%@", [retCode intValue], retMsg];
			NSError * error = [NSError errorWithDomain:msgContent code:[retCode intValue] userInfo:responseDictionary];
			[self sendDidFailWithError:error];
		}
	}
	[responseBody release];
}

@end
