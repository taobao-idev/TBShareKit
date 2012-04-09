//
//  SHKRenRen.m
//  ShareKit
//
//  Created by xiewenwei on 10-12-22.
//  Copyright 2010 Taobao.inc. All rights reserved.
//

#import "SHKRenRen.h"
#import "TSMutableString.h"
#import "JSON.h"

@implementation SHKRenRen

@synthesize session;

#pragma mark api

#pragma mark -
#pragma mark Configuration : Service Defination

- (void)dealloc
{
	[session.delegates removeObject:self];
	[session release];
	[super dealloc];
}

+ (NSString *)sharerTitle
{
	return @"人人网";
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

- (BOOL)shouldAutoShare
{
	return YES; // FBConnect presents its own dialog
}

#pragma mark -
#pragma mark Authorization

- (BOOL)isAuthorized
{
	if (session == nil)
	{
		if(!SHKRenRenUseSessionProxy){
			self.session = [Session sessionForApplication:RENREN_APIKEY
													 secret:RENREN_SECRET
												   delegate:self];
			
		}else {
			self.session = [Session sessionForApplication:RENREN_APIKEY
											getSessionProxy:SHKRenRenSessionProxyURL
												   delegate:self];
		}
		
		
		return [session resume];
	}
	
	return [session isConnected];
}

- (void)promptAuthorization
{
	LoginDialog* dialog = [[[LoginDialog alloc] initWithSession:[self session]] autorelease];
	[dialog show];
}

+ (void)logout
{
	Session *rrSession; 
	
	if(!SHKRenRenUseSessionProxy){
		rrSession = [Session sessionForApplication:RENREN_APIKEY
											  secret:RENREN_SECRET
											delegate:self];
		
	}else {
		rrSession = [Session sessionForApplication:RENREN_APIKEY
									 getSessionProxy:SHKRenRenSessionProxyURL
											delegate:self];
	}
	
	[rrSession logout];
}

- (BOOL)send
{	
	// Check if we should send follow request too
	if (item.shareType == SHKShareTypeImage) 
	{
		[self sendImage];
	} 
	else 
	{
		[self sendStatus];
		
	}
	// Notify delegate
	[self sendDidStart];
	return YES;
}

- (void)sendImage
{
	NSString *photoName = @"sanFran.jpg";
	UIImage *photo = [UIImage imageNamed:@"sanFran.jpg"];
	[[Request requestWithDelegate:self] call:@"photos.upload" params:nil dataParam:photo dataName:photoName];
}

- (void)session:(Session*)session didLogin:(RRUID)uid {
	//[self share];
}

- (void)session:(Session*)session willLogout:(RRUID)uid 
{
	// Not handling this
}

- (void)request:(Request*)req didLoad:(id)result {
	NSLog(@"%@",result);
	if([req.method isEqualToString:@"photos.upload"]) {
		[self sendDidFinish];
	} else {

	}
}

- (void)request:(Request*)req didFailWithError:(NSError*)error 
{
	[self sendDidFailWithError:error];
}

- (void)sendStatus
{
	// create the string that points to the correct Wikipedia page for the element name
	FeedDialog* dialog = [[[FeedDialog alloc] init] autorelease];
	dialog.templateId = 4;
	NSString* feedtype = @"自定义新鲜事";
	NSString* appName = @"游向彼岸";
	NSString* appLink = @"http://www.swimmingacross.com/home.do";
	NSString* imageSrc = @"http://fmn.xnimg.cn/fmn036/20100222/1205/p_main_8QZ0_7d5900050dcf2d10.jpg";
	NSString* imageHref = @"http://photo.renren.com/getphoto.do?id=2702050036&owner=287936566&ref=newsfeed";
	NSString* content = @"恭贺新年";
	NSDictionary* image = [NSDictionary dictionaryWithObjectsAndKeys:imageSrc, @"src", imageHref, @"href", nil];
	NSArray* images = [NSArray arrayWithObject:image];
	NSDictionary* data = [NSDictionary dictionaryWithObjectsAndKeys:feedtype, @"feedtype", appName, @"appName", 
						  appLink, @"appLink", content, @"content", images, @"images", nil];
	dialog.templateData = [data JSONRepresentation];
	dialog.bodyGeneral = @"用iphone应用连接人人网，和好友互动，分享精彩时刻！";
	dialog.userMessage = @"嗯，不错";
	dialog.userMessagePrompt = @"请写下你的评论";
	[dialog show];
	[self sendDidFinish];
}

@end
