/*
 * Thank you for Facebook original source code
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 * 
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * modified by xuyan(yan.xu@opi-corp.com) to fit RenRen in China.
 */

#import "LoginDialog.h"
#import "Session.h"
#import "Request.h"

#import "SHKConfig.h"
#import "SHKRenRen.h"

///////////////////////////////////////////////////////////////////////////////////////////////////
// global

static NSString* kLoginURL = @"http://login.api.renren.com/connect/touch_login.do";

///////////////////////////////////////////////////////////////////////////////////////////////////

@implementation LoginDialog

///////////////////////////////////////////////////////////////////////////////////////////////////
// private

- (void)connectToGetSession:(NSString*)token {
  _getSessionRequest = [[Request requestWithSession:_session delegate:self] retain];
  NSMutableDictionary* params = [NSMutableDictionary dictionaryWithObject:token forKey:@"auth_token"];
  if (!_session.apiSecret) {
    [params setObject:@"1" forKey:@"generate_session_secret"];
  }
  
  if (_session.getSessionProxy) {
    [_getSessionRequest post:_session.getSessionProxy params:params];
  } else {
    [_getSessionRequest call:@"auth.getSession" params:params];
  }
}

- (void)loadLoginPage {
	NSHTTPCookieStorage* cookies = [NSHTTPCookieStorage sharedHTTPCookieStorage];
	NSHTTPCookie* testCookie = [NSHTTPCookie cookieWithProperties:
								[NSDictionary dictionaryWithObjectsAndKeys:
								 @"beta", NSHTTPCookieValue,
								 @"iphone-connect", NSHTTPCookieName,
								 @".renren.com", NSHTTPCookieDomain,
								 @"/", NSHTTPCookiePath,
								 nil]];
	[cookies setCookie:testCookie];
	
  NSDictionary* params = [NSDictionary dictionaryWithObjectsAndKeys:
    @"1", @"rrconnect", @"touch", @"display", _session.apiKey, @"api_key",
    @"rrconnect://success", @"next", nil];
  [self loadURL:kLoginURL method:@"GET" get:params post:nil];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// NSObject

- (id)initWithSession:(Session*)session {
  if (self = [super initWithSession:session]) {
    _getSessionRequest = nil;
  }
  return self;
}

- (void)dealloc {
  _getSessionRequest.delegate = nil;
  [_getSessionRequest release];
  [super dealloc];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
//Dialog

- (void)load {
  [self loadLoginPage];
}

- (void)dialogWillDisappear {
  [_webView stringByEvaluatingJavaScriptFromString:@"email.blur();"];
  [_getSessionRequest cancel];
	
	if(![_session isConnected]) {
		[_session cancelLogin];
	}
}

- (void)dialogDidSucceed:(NSURL*)url {
  NSString* q = url.query;
  NSRange start = [q rangeOfString:@"auth_token="];
  if (start.location != NSNotFound) {
    NSRange end = [q rangeOfString:@"&"];
    NSUInteger offset = start.location+start.length;
    NSString* token = end.location == NSNotFound
      ? [q substringFromIndex:offset]
      : [q substringWithRange:NSMakeRange(offset, end.location-offset)];
    if (token) {
      [self connectToGetSession:token];
    }
  }
}

///////////////////////////////////////////////////////////////////////////////////////////////////
//request
- (void)request:(Request*)request didLoad:(id)result {
  NSDictionary* object = result;
  RRUID uid = [[object objectForKey:@"uid"] intValue];
  NSString* sessionKey = [object objectForKey:@"session_key"];
  NSString* sessionSecret = [object objectForKey:@"secret"];
  NSTimeInterval expires = [[object objectForKey:@"expires"] floatValue];
  NSDate* expiration = expires ? [NSDate dateWithTimeIntervalSince1970:expires] : nil;
  
  [_getSessionRequest release];
  _getSessionRequest = nil;

  [_session begin:uid sessionKey:sessionKey sessionSecret:sessionSecret expires:expiration];
  [_session resume];
	
  [[NSNotificationCenter defaultCenter] postNotificationName:SERVICE_AUTHORIZED object:NSStringFromClass([SHKRenRen class])];
  
  [self dismissWithSuccess:YES animated:YES];
}

- (void)request:(Request*)request didFailWithError:(NSError*)error {
  [_getSessionRequest release];
  _getSessionRequest = nil;

  [self dismissWithError:error animated:YES];
}
 
@end
