//
//  SHKOAuthSharer.m
//  ShareKit
//
//  Created by Nathan Weiner on 6/21/10.

//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//
//

#import "SHKOAuthSharer.h"
#import "SHKOAuthView.h"
#import "OAuthConsumer.h"

#import "JSON.h"
#import "SHKTencent.h"


@implementation SHKOAuthSharer

@synthesize consumerKey, secretKey, authorizeCallbackURL;
@synthesize authorizeURL, requestURL, accessURL, accountURL;
@synthesize consumer, requestToken, accessToken;
@synthesize signatureProvider;
@synthesize authorizeResponseQueryVars;
@synthesize serviceStr;

- (void)dealloc
{
	[serviceStr release];
	[consumerKey release];
	[secretKey release];
	[authorizeCallbackURL release];
	[authorizeURL release];
	[requestURL release];
	[accessURL release];
	[accountURL release];
	[consumer release];
	[requestToken release];
	[accessToken release];
	[signatureProvider release];
	[authorizeResponseQueryVars release];
	
	[super dealloc];
}



#pragma mark -
#pragma mark Authorization

- (BOOL)isAuthorized
{		
	return [self restoreAccessToken];
}

- (void)promptAuthorization
{		
	[self tokenRequest];
}


#pragma mark Request

- (void)tokenRequest
{
	SHKLog(@"%s", __FUNCTION__);
	[[SHKActivityIndicator currentIndicator] displayActivity:@"正在连接..."];
	
    OAMutableURLRequest *oRequest = [[OAMutableURLRequest alloc] initWithURL:requestURL
                                                                   consumer:consumer
                                                                      token:nil   // we don't have a Token yet
                                                                      realm:nil   // our service provider doesn't specify a realm
														   signatureProvider:signatureProvider
																serviceFlag:serviceStr
																loadingFirst:YES];
	
	if ([kTencentFlag isEqualToString:serviceStr]) {
		[oRequest setHTTPMethod:@"GET"];
	}else {
		[oRequest setHTTPMethod:@"POST"];
	}
	
	[self tokenRequestModifyRequest:oRequest];
	
    OAAsynchronousDataFetcher *fetcher = [OAAsynchronousDataFetcher asynchronousFetcherWithRequest:oRequest
                         delegate:self
                didFinishSelector:@selector(tokenRequestTicket:didFinishWithData:)
                  didFailSelector:@selector(tokenRequestTicket:didFailWithError:)];
	[fetcher start];	
	[oRequest release];
}

- (void)tokenRequestModifyRequest:(OAMutableURLRequest *)oRequest
{
	// Subclass to add custom paramaters and headers
}

- (void)tokenRequestTicket:(OAServiceTicket *)ticket didFinishWithData:(NSData *)data 
{
	NSString *responseBody = [[NSString alloc] initWithData:data
												   encoding:NSUTF8StringEncoding];
	NSLog(@"未授权 %@",responseBody);
	
	if (SHKDebugShowLogs) // check so we don't have to alloc the string with the data if we aren't logging
		SHKLog(@"tokenRequestTicket Response Body: %@", [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease]);
	
	[responseBody release];
	 
	[[SHKActivityIndicator currentIndicator] hide];
	
	if (ticket.didSucceed) 
	{
		NSString *responseBody = [[NSString alloc] initWithData:data
													   encoding:NSUTF8StringEncoding];
		self.requestToken = [[OAToken alloc] initWithHTTPResponseBody:responseBody];
		NSLog(@"未授权 %@",responseBody);
		[responseBody release];
		
		[self tokenAuthorize];
	}
	
	else
		// TODO - better error handling here
		[self tokenRequestTicket:ticket didFailWithError:[SHK error:[NSString stringWithFormat:@"在%@请求授权发生错误", [self sharerTitle]]]];
}

- (void)tokenRequestTicket:(OAServiceTicket *)ticket didFailWithError:(NSError*)error
{
	[[SHKActivityIndicator currentIndicator] hide];
	
	[[[[UIAlertView alloc] initWithTitle:@"请求错误"
								 message:error!=nil?[error localizedDescription]:@"分享时发生错误"
								delegate:nil
					   cancelButtonTitle:@"关闭"
					   otherButtonTitles:nil] autorelease] show];
}


#pragma mark Authorize 

- (void)tokenAuthorize
{	
	SHKLog(@"%s", __FUNCTION__);
    
    NSURL *url;
    if ([authorizeURL.absoluteString rangeOfString:@"douban"].location != NSNotFound) {
        url = [NSURL URLWithString:[NSString stringWithFormat:@"%@?oauth_token=%@&oauth_callback=%@&p=1", authorizeURL.absoluteString, requestToken.key,CallBackURL]];
    }else {
        url = [NSURL URLWithString:[NSString stringWithFormat:@"%@?oauth_token=%@&oauth_callback=%@", authorizeURL.absoluteString, requestToken.key,CallBackURL]];
    }

	//NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@?oauth_token=%@&oauth_callback=%@", authorizeURL.absoluteString, requestToken.key,CallBackURL]];
	SHKOAuthView *auth = [[SHKOAuthView alloc] initWithURL:url delegate:self];
	NSLog(@"%s auth url: %@ helper: %@", __FUNCTION__, url, [SHK currentHelper]);
	[[SHK currentHelper] showViewController:auth];	
	//[[SHK currentHelper] performSelector:@selector(showViewController:) withObject:auth afterDelay:0.2];
	[auth release];
}

- (void)tokenAuthorizeView:(SHKOAuthView *)authView didFinishWithSuccess:(BOOL)success queryParams:(NSMutableDictionary *)queryParams error:(NSError *)error;
{
	[[SHK currentHelper] hideCurrentViewControllerAnimated:YES];
	if (!success)
	{
		[[[[UIAlertView alloc] initWithTitle:@"授权错误"
									 message:@"取消授权或授权时发生错误"
									delegate:nil
						   cancelButtonTitle:@"关闭"
						   otherButtonTitles:nil] autorelease] show];
	}	
	
	else 
	{
		self.authorizeResponseQueryVars = queryParams;
		
		[self tokenAccess];
	}
}

- (void)tokenAuthorizeCancelledView:(SHKOAuthView *)authView
{
	[[SHK currentHelper] hideCurrentViewControllerAnimated:YES];	
}


#pragma mark Access

- (void)tokenAccess
{
	[self tokenAccess:NO];
}

- (void)tokenAccess:(BOOL)refresh
{
	if (!refresh)
		[[SHKActivityIndicator currentIndicator] displayActivity:@"正在授权..."];
	
    OAMutableURLRequest *oRequest = [[OAMutableURLRequest alloc] initWithURL:accessURL
                                                                   consumer:consumer
																	   token:(refresh ? accessToken : requestToken)
                                                                      realm:nil   // our service provider doesn't specify a realm
                                                          signatureProvider:signatureProvider
																serviceFlag:serviceStr
																loadingFirst:NO]; // use the default method, HMAC-SHA1
    if ([kTencentFlag isEqualToString:serviceStr]) {
		[oRequest setHTTPMethod:@"GET"];
	}else {
		[oRequest setHTTPMethod:@"POST"];
	}
	
	[self tokenAccessModifyRequest:oRequest];
	
    OAAsynchronousDataFetcher *fetcher = [OAAsynchronousDataFetcher asynchronousFetcherWithRequest:oRequest
                         delegate:self
                didFinishSelector:@selector(tokenAccessTicket:didFinishWithData:)
                  didFailSelector:@selector(tokenAccessTicket:didFailWithError:)];
	[fetcher start];
	[oRequest release];
}

- (void)tokenAccessModifyRequest:(OAMutableURLRequest *)oRequest
{
	// Subclass to add custom paramaters or headers	
}

- (void)tokenAccessTicket:(OAServiceTicket *)ticket didFinishWithData:(NSData *)data 
{
    NSLog(@"%s", __FUNCTION__);
	if (SHKDebugShowLogs) // check so we don't have to alloc the string with the data if we aren't logging
		SHKLog(@"tokenAccessTicket Response Body: %@", [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease]);
	
	[[SHKActivityIndicator currentIndicator] hide];

	if (ticket.didSucceed) 
	{
		NSString *responseBody = [[NSString alloc] initWithData:data
													   encoding:NSUTF8StringEncoding];
		NSLog(@"%s response:%@", __FUNCTION__, responseBody);
		
		self.accessToken = [[OAToken alloc] initWithHTTPResponseBody:responseBody];
		
		[self storeAccessToken];
		
		
		//... 获取用户帐号信息
		NSArray * contextList = [responseBody componentsSeparatedByString:@"&"];
		for (NSString * context in contextList) {
			if ([serviceStr isEqualToString:kTencentFlag] && [context rangeOfString:@"name"].location != NSNotFound) {
				NSString * userName = [[context componentsSeparatedByString:@"="] objectAtIndex:1];
				NSLog(@"userName: %@", userName);
				
				[SHK setAuthValue:userName forKey:kKeychainAccount forSharer:[self sharerId]];
				
				break; //return if user name for account got from response
			}
			
			//get account info by user id in the response body
			if ([context rangeOfString:@"user_id"].location != NSNotFound) {
				NSString * userID = [[context componentsSeparatedByString:@"="] objectAtIndex:1];
				NSLog(@"userID: %@", userID);
				[self accountWithUserId:userID];
			}
		}
		
        [SHK registerAuthorizedService:self];
		
		if (!isOnlyAuthorize) {
			[self tryPendingAction];
		}else {
            //此时为用户在帐号管理中添加帐号，发送通知打开自动分享功能
            [[NSNotificationCenter defaultCenter] postNotificationName:SERVICE_AUTHORIZED object:NSStringFromClass([self class])];
        }


		[responseBody release];
	}
	
	
	else
		// TODO - better error handling here
		[self tokenAccessTicket:ticket didFailWithError:[SHK error:[NSString stringWithFormat:@"在%@请求访问时发生错误", [self sharerTitle]]]];
}

- (void)tokenAccessTicket:(OAServiceTicket *)ticket didFailWithError:(NSError*)error
{
	[[SHKActivityIndicator currentIndicator] hide];
	
	[[[[UIAlertView alloc] initWithTitle:@"访问错误"
								 message:error!=nil?[error localizedDescription]:@"分享时发生错误"
								delegate:nil
					   cancelButtonTitle:@"关闭"
					   otherButtonTitles:nil] autorelease] show];
}

- (void)storeAccessToken
{	
    NSLog(@"%s", __FUNCTION__);
    
	[SHK setAuthValue:accessToken.key
					 forKey:kKeychainAccessKey
				  forSharer:[self sharerId]];
	
	[SHK setAuthValue:accessToken.secret
					 forKey:kKeychainAccessSecret
			forSharer:[self sharerId]];
	
	[SHK setAuthValue:accessToken.sessionHandle
			   forKey:kKeychainSessionHandle
			forSharer:[self sharerId]];
}

+ (void)deleteStoredAccessToken
{
	NSString *sharerId = [self sharerId];
	SHKLog(@"%s sharerId:%@", __FUNCTION__, sharerId);
	
	[SHK removeAuthValueForKey:kKeychainAccount forSharer:sharerId];
	[SHK removeAuthValueForKey:kKeychainAccessKey forSharer:sharerId];
	[SHK removeAuthValueForKey:kKeychainAccessSecret forSharer:sharerId];
	[SHK removeAuthValueForKey:kKeychainSessionHandle forSharer:sharerId];
}

+ (void)logout
{
    NSLog(@"%s", __FUNCTION__);
	[self deleteStoredAccessToken];
	
	// Clear cookies (for OAuth, doesn't affect XAuth)
	// TODO - move the authorizeURL out of the init call (into a define) so we don't have to create an object just to get it
	SHKOAuthSharer *sharer = [[self alloc] init];
	if (sharer.authorizeURL)
	{
		SHKLog(@"%s authorizeURL:%@", __FUNCTION__, sharer.authorizeURL);
		NSHTTPCookieStorage *storage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
		NSArray *cookies = [storage cookiesForURL:sharer.authorizeURL];
		for (NSHTTPCookie *each in cookies) 
		{
			[storage deleteCookie:each];
		}
	}
    
    // 删除账户的同时将是否分享过标志置为否，以便用新账户分享时上传新的账户到服务器端
    [SHK removeAuthorizedService:[sharer sharerId]];
	[[NSUserDefaults standardUserDefaults] setBool:NO forKey:[NSString stringWithFormat:@"%@_isShared", [sharer sharerId]]];
    
	[sharer release];
}

- (BOOL)restoreAccessToken
{
	self.consumer = [[[OAConsumer alloc] initWithKey:consumerKey secret:secretKey] autorelease];
	
	if (accessToken != nil)
		return YES;
		
	NSString *key = [SHK getAuthValueForKey:kKeychainAccessKey
				  forSharer:[self sharerId]];
	
	NSString *secret = [SHK getAuthValueForKey:kKeychainAccessSecret
									 forSharer:[self sharerId]];
	
	NSString *sessionHandle = [SHK getAuthValueForKey:kKeychainSessionHandle
									 forSharer:[self sharerId]];
	
	if (key != nil && secret != nil)
	{
		self.accessToken = [[[OAToken alloc] initWithKey:key secret:secret] autorelease];
		
		if (sessionHandle != nil)
			accessToken.sessionHandle = sessionHandle;
		
		return accessToken != nil;
	}
	
	return NO;
}


#pragma mark Expired

- (void)refreshToken
{
	self.pendingAction = SHKPendingRefreshToken;
	[self tokenAccess:YES];
}

#pragma mark -
#pragma mark Pending Actions
#pragma mark -
#pragma mark Pending Actions

- (void)tryPendingAction
{
	switch (pendingAction) 
	{
		case SHKPendingRefreshToken:
			[self tryToSend]; // try to resend
			break;
			
		default:			
			[super tryPendingAction];			
	}
}

#pragma mark -
#pragma mark Get personal account info for service
- (void)accountWithUserId:(NSString *)userID 
{
	
}

- (void)accountTicket:(OAServiceTicket *)ticket didFinishWithData:(NSData *)data 
{
	
}
- (void)accountTicket:(OAServiceTicket *)ticket didFailWithError:(NSError *)error 
{
	
}

@end
