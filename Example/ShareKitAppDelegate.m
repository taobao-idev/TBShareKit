//
//  ShareKitAppDelegate.m
//  ShareKit
//
//  Created by Nathan Weiner on 6/4/10.
//  Copyright Idea Shower, LLC 2010. All rights reserved.
//

#import "ShareKitAppDelegate.h"
#import "RootViewController.h"
#import "SHK.h"

#import "SHKShareController.h"
#import "SHKShareItemController.h"

#import "NSData+AES.h"

@implementation ShareKitAppDelegate

@synthesize window;
@synthesize navigationController;


#pragma mark -
#pragma mark Application lifecycle

- (void)showEncryptedDataForString:(NSString *)str {
    NSData *dat = AES256EncryptWithKey([str dataUsingEncoding:NSUTF8StringEncoding], AES_ENCRYPT_KEY);
    NSMutableArray *arr = [NSMutableArray array];
    unsigned char *d = (unsigned char *)[dat bytes];
    for (int i = 0; i < [dat length]; ++i) {
        [arr addObject:[NSString stringWithFormat:@"0x%02x", d[i]]];
    }
    NSString *str2 = [NSString stringWithFormat:@"[NSData dataWithBytes:(uint8_t[]){%@} length:%d}",
                      [arr componentsJoinedByString:@", "],
                      [dat length]];
    NSLog(@"Encrypted:\n%@", str2);
}


- (void)showDefaultEncrypt:(NSString *)context withKey:(NSString *)key {
    NSData *dat = AES256EncryptWithKey([context dataUsingEncoding:NSUTF8StringEncoding], [key dataUsingEncoding:NSUTF8StringEncoding]);
    
    NSMutableArray *arr = [NSMutableArray array];
    unsigned char *d = (unsigned char *)[dat bytes];
    for (int i = 0; i < [dat length]; ++i) {
        [arr addObject:[NSString stringWithFormat:@"0x%02x", d[i]]];
    }
    NSString *str2 = [NSString stringWithFormat:@"[NSData dataWithBytes:(uint8_t[]){%@} length:%d]",
                      [arr componentsJoinedByString:@", "],
                      [dat length]];
    NSLog(@"%s\nEncrypted:\n%@", __FUNCTION__, str2);
}


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {    
    // Override point for customization after app launch
    [self showDefaultEncrypt:@"opensource" withKey:@"opensource"];
    
     /*
    [self showEncryptedDataForString:@"06690f9cfaf53987133b2ed6f0dfac95"];
    [self showEncryptedDataForString:@"34fc3d8a9ef78144"];*/
	
	[window addSubview:[navigationController view]];
    [window makeKeyAndVisible];
	
	navigationController.topViewController.title = SHKLocalizedString(@"Examples");
	[navigationController setToolbarHidden:NO];
	
	//[self performSelector:@selector(testOffline) withObject:nil afterDelay:0.5];
	
	SHKShareController * ctrler = [[SHKShareController alloc] initWithStyle:UITableViewStyleGrouped];
	//[navigationController pushViewController:ctrler animated:YES];
	
	NSArray * shareList = [NSArray arrayWithObjects:@"http://img04.taobaocdn.com/bao/uploaded/i4/T1mj8YXkXGXXXDFUYb_095521.jpg_160x160.jpg", 
						   @"http://img04.taobaocdn.com/bao/uploaded/i4/T1idNOXdhvXXbmkO70_035641.jpg_160x160.jpg", 
						   @"http://img02.taobaocdn.com/bao/uploaded/i2/T1.SJNXapkXXb8EHM0_034418.jpg_160x160.jpg",
						   @"http://img02.taobaocdn.com/imgextra/i2/151642256/T2HqJnXmlbXXXXXXXX_!!151642256.jpg_160x160.jpg",
						   @"http://img04.taobaocdn.com/bao/uploaded/i4/T1idNOXdhvXXbmkO70_035641.jpg_160x160.jpg", 
						   @"http://img02.taobaocdn.com/bao/uploaded/i2/T1.SJNXapkXXb8EHM0_034418.jpg_160x160.jpg",
						   @"http://img03.taobaocdn.com/imgextra/i3/151642256/T2mb8bXbhbXXXXXXXX_!!151642256.gif_160x160.jpg", nil];
	SHKShareItemController * itemController = [[SHKShareItemController alloc] initWithImageList:shareList];
	//[navigationController pushViewController:itemController animated:YES];
	
	[ctrler release];
	[itemController release];
	
	return YES;
}

- (void)testOffline
{	
	[SHK flushOfflineQueue];
}

- (void)applicationWillTerminate:(UIApplication *)application 
{
	// Save data if appropriate
}


#pragma mark -
#pragma mark Memory management

- (void)dealloc {
	[navigationController release];
	[window release];
	[super dealloc];
}


@end

