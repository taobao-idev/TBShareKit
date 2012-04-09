#import "FeedDialog.h"
#import "Session.h"

///////////////////////////////////////////////////////////////////////////////////////////////////
// global

static NSString* kFeedURL = @"http://www.connect.renren.com/feed/iphone/iphonePromptFeed";

///////////////////////////////////////////////////////////////////////////////////////////////////

@implementation FeedDialog

@synthesize templateId = _templateId, templateData = _templateData,
  bodyGeneral = _bodyGeneral, userMessage = _userMessage, userMessagePrompt = _userMessagePrompt;

///////////////////////////////////////////////////////////////////////////////////////////////////
// private

- (NSString*)generateFeedInfo {
  NSMutableArray* pairs = [NSMutableArray array];
  
  if (_templateId) {
    [pairs addObject:[NSString stringWithFormat:@"\"template_id\": \"%d\"", _templateId]];
  }
  if (_templateData) {
    [pairs addObject:[NSString stringWithFormat:@"\"template_data\": %@", _templateData]];
  }
  if (_bodyGeneral) {
    [pairs addObject:[NSString stringWithFormat:@"\"body_general\": \"%@\"", _bodyGeneral]];
  }
  
  return [NSString stringWithFormat:@"{%@}", [pairs componentsJoinedByString:@","]];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// NSObject

- (id)initWithSession:(Session*)session {
  if (self = [super initWithSession:session]) {
    _templateId = 0;
    _templateData = nil;
    _bodyGeneral = nil;
		_getSessionRequest = nil;
  }
	
  return self;
}

- (void)dealloc {
  [_templateData release];
  [_bodyGeneral release];
	[_getSessionRequest release];
  [super dealloc];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// Dialog

- (void)load {
  
	NSString* feedInfo = [self generateFeedInfo];
	NSDictionary* postParams = [NSDictionary dictionaryWithObjectsAndKeys:
    _session.apiKey, @"api_key", _session.sessionKey, @"session_key",
    @"true", @"preview", @"rrconnect://success", @"callback", @"rrconnect://cancel", @"cancel_url",
    feedInfo, @"feed_info", @"self_feed", @"feed_target_type", _userMessage,@"user_message", _userMessagePrompt,@"user_message_prompt", @"0", @"in_canvas", @"2", @"size", nil];
	
  [self loadURL:kFeedURL method:@"POST" get:nil post:postParams];
}

- (void)dialogDidCancel:(NSURL*)url {
	NSString* q = url.query;
	if (q) {
		NSRange start = [q rangeOfString:@"errMsg="];
		if (start.location != NSNotFound) {
			NSRange end = [q rangeOfString:@"&"];
			NSUInteger offset = start.location+start.length;
			NSString* errMsg = end.location == NSNotFound
									? [q substringFromIndex:offset]: [q substringWithRange:NSMakeRange(offset, end.location-offset)];
			errMsg = [errMsg stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
			UIAlertView* alert = [[UIAlertView alloc] initWithTitle:errMsg message:nil delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil];
			[alert show];
			[alert release];
		}
	}
	[super dialogDidCancel:url];
}

- (void)dialogDidSucceed:(NSURL*)url {
	UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"发送成功" message:nil delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil];
	[alert show];
	[alert release];
	[super dialogDidSucceed:url];
}

@end
