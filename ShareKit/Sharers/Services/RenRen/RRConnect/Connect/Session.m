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

#import "Session.h"
#import "Request.h"

///////////////////////////////////////////////////////////////////////////////////////////////////
// global

static NSString* kAPIRestURL = @"http://api.renren.com/restserver.do";

static const int kMaxBurstRequests = 3;
static const NSTimeInterval kBurstDuration = 0.2;

static Session* sharedSession = nil;

///////////////////////////////////////////////////////////////////////////////////////////////////

@implementation Session

@synthesize delegates = _delegates, apiKey = _apiKey, apiSecret = _apiSecret,
  getSessionProxy = _getSessionProxy, uid = _uid, sessionKey = _sessionKey,
  sessionSecret = _sessionSecret, expirationDate = _expirationDate;

///////////////////////////////////////////////////////////////////////////////////////////////////
// class public

+ (Session*)session {
  return sharedSession;
}

+ (void)setSession:(Session*)session {
  sharedSession = session;
}

+ (Session*)sessionForApplication:(NSString*)key secret:(NSString*)secret
    delegate:(id<SessionDelegate>)delegate {
  Session* session = [[[Session alloc] initWithKey:key secret:secret
    getSessionProxy:nil] autorelease];
  [session.delegates addObject:delegate];
  return session;
}

+ (Session*)sessionForApplication:(NSString*)key getSessionProxy:(NSString*)getSessionProxy
    delegate:(id<SessionDelegate>)delegate {
  Session* session = [[[Session alloc] initWithKey:key secret:nil
    getSessionProxy:getSessionProxy] autorelease];
  [session.delegates addObject:delegate];
  return session;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// private

- (void)save {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  if (_uid) {
    [defaults setObject:[NSNumber numberWithLongLong:_uid] forKey:@"UserId"];
  } else {
    [defaults removeObjectForKey:@"UserId"];
  }

  if (_sessionKey) {
    [defaults setObject:_sessionKey forKey:@"SessionKey"];
  } else {
    [defaults removeObjectForKey:@"SessionKey"];
  }

  if (_sessionSecret) {
    [defaults setObject:_sessionSecret forKey:@"SessionSecret"];
  } else {
    [defaults removeObjectForKey:@"SessionSecret"];
  }

  if (_expirationDate) {
    [defaults setObject:_expirationDate forKey:@"SessionExpires"];
  } else {
    [defaults removeObjectForKey:@"SessionExpires"];
  }
  
  [defaults synchronize];
}

- (void)unsave {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  [defaults removeObjectForKey:@"UserId"];
  [defaults removeObjectForKey:@"SessionKey"];
  [defaults removeObjectForKey:@"SessionSecret"];
  [defaults removeObjectForKey:@"SessionExpires"];
  [defaults synchronize];
}

- (void)startFlushTimer {
  if (!_requestTimer) {
    NSTimeInterval t = kBurstDuration + [_lastRequestTime timeIntervalSinceNow];
    _requestTimer = [NSTimer scheduledTimerWithTimeInterval:t target:self
      selector:@selector(requestTimerReady) userInfo:nil repeats:NO];
  }
}

- (void)enqueueRequest:(Request*)request {
  [_requestQueue addObject:request];
  [self startFlushTimer];
}

- (BOOL)performRequest:(Request*)request enqueue:(BOOL)enqueue {
  NSTimeInterval t = [_lastRequestTime timeIntervalSinceNow];
	
  BOOL burst = t && t > -kBurstDuration;
  if (burst && ++_requestBurstCount > kMaxBurstRequests) {
    if (enqueue) {
      [self enqueueRequest:request];
    }
    return NO;
  } else {
    [request performSelector:@selector(connect)];

    if (!burst) {
      _requestBurstCount = 1;
      [_lastRequestTime release];
      _lastRequestTime = [[request timestamp] retain];
    }
  }
  return YES;
}

- (void)flushRequestQueue {
  while (_requestQueue.count) {
    Request* request = [_requestQueue objectAtIndex:0];
    if ([self performRequest:request enqueue:NO]) {
      [_requestQueue removeObjectAtIndex:0];
    } else {
      [self startFlushTimer];
      break;
    }
  }
}

- (void)requestTimerReady {
  _requestTimer = nil;
  [self flushRequestQueue];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// NSObject

- (Session*)initWithKey:(NSString*)key secret:(NSString*)secret
    getSessionProxy:(NSString*)getSessionProxy {
  if (self = [super init]) {
    if (!sharedSession) {
      sharedSession = self;
    }
    
    _delegates = RRCreateNonRetainingArray();    
    _apiKey = [key copy];
    _apiSecret = [secret copy];
    _getSessionProxy = [getSessionProxy copy];
    _uid = 0;
    _sessionKey = nil;
    _sessionSecret = nil;
    _expirationDate = nil;
    _requestQueue = [[NSMutableArray alloc] init];
    _lastRequestTime = nil;
    _requestBurstCount = 0;
    _requestTimer = nil;
  }
  return self;
}

- (void)dealloc {
  if (sharedSession == self) {
    sharedSession = nil;
  }

  [_delegates release];
  [_requestQueue release];
  [_apiKey release];
  [_apiSecret release];
  [_getSessionProxy release];
  [_sessionKey release];
  [_sessionSecret release];
  [_expirationDate release];
  [_lastRequestTime release];
  [super dealloc];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// public

- (NSString*)apiURL {
  return kAPIRestURL;
}

- (BOOL)isConnected {
  return !!_sessionKey;
}

- (void)begin:(RRUID)uid sessionKey:(NSString*)sessionKey
    sessionSecret:(NSString*)sessionSecret expires:(NSDate*)expires {
  _uid = uid;
  _sessionKey = [sessionKey copy];
  _sessionSecret = [sessionSecret copy];
  _expirationDate = [expires retain];
  
  [self save];
}

- (BOOL)resume {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  RRUID uid = [[defaults objectForKey:@"UserId"] intValue];
  if (uid) {
    NSDate* expirationDate = [defaults objectForKey:@"SessionExpires"];
    if (!expirationDate || [expirationDate timeIntervalSinceNow] > 0) {
      _uid = uid;
      _sessionKey = [[defaults stringForKey:@"SessionKey"] copy];
      _sessionSecret = [[defaults stringForKey:@"SessionSecret"] copy];
      _expirationDate = [expirationDate retain];

      for (id<SessionDelegate> delegate in _delegates) {
        [delegate session:self didLogin:_uid];
      }
      return YES;
    }
  }
  return NO;
}

- (void)cancelLogin {
  if (![self isConnected]) {
    for (id<SessionDelegate> delegate in _delegates) {
      if ([delegate respondsToSelector:@selector(sessionDidNotLogin:)]) {
        [delegate sessionDidNotLogin:self];
      }
    }
  }
}

- (void)logout {
  if (_sessionKey) {
    for (id<SessionDelegate> delegate in _delegates) {
      if ([delegate respondsToSelector:@selector(session:willLogout:)]) {
        [delegate session:self willLogout:_uid];
      }
    }
		
		// Remove cookies that UIWebView may have stored
    NSHTTPCookieStorage* cookies = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    NSArray* renrenCookies = [cookies cookiesForURL:
      [NSURL URLWithString:@"http://renren.com"]];
    for (NSHTTPCookie* cookie in renrenCookies) {
      [cookies deleteCookie:cookie];
    }
		
    _uid = 0;
    [_sessionKey release];
    _sessionKey = nil;
    [_sessionSecret release];
    _sessionSecret = nil;
    [_expirationDate release];
    _expirationDate = nil;
    [self unsave];

    for (id<SessionDelegate> delegate in _delegates) {
      if ([delegate respondsToSelector:@selector(sessionDidLogout:)]) {
        [delegate sessionDidLogout:self];
      }
    }
  } else {
    [self unsave];
  }
}

- (void)send:(Request*)request {
  [self performRequest:request enqueue:YES];
}

@end
