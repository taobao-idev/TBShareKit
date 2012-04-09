    //
//  SHKShareItemController.m
//  ShareKit
//
//  Created by HanFeng on 11-1-27.
//  Copyright 2011 Taobao.inc. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "SHKShareItemController.h"

#import "SHKSharer.h"

#import "LoadImageOperation.h"
#import "UIImage+ImageWithName.h"

#import "SHKItem.h"

#import "SHKSina.h"
#import "SHKTencent.h"
#import "SHKDouban.h"

@interface SHKShareItemController ()


//! 判断有没有分享服务设为自动分享
- (BOOL)hasServiceAutoShared;

//! 选择分享图片后，为图片所在的按钮添加已选择标志
- (void)shareImageWithButton:(UIButton *)button;

@end


@implementation SHKShareItemController

@synthesize textView;
@synthesize selectedView;

@synthesize sharedContext;

@synthesize imageShareList;

@synthesize sharedImage;
@synthesize sharedImgURL;

@synthesize sharedItem;


static NSDictionary *shareKitMap = nil;


#pragma mark -
#pragma mark Share title and sharer map

+ (void)initialize {
    shareKitMap = [[NSDictionary dictionaryWithObjectsAndKeys:
                   @"SHKSina", @"新浪微博",
                   @"SHKDouban", @"豆瓣说",
                   nil] retain];
    
    [[[SHKSina alloc] init] autorelease];
    [[[SHKDouban alloc] init] autorelease];
}


#pragma mark -
#pragma mark initialization with image share list

- (id)initWithImageList:(NSArray *)list {
	NSAssert(list != nil, @"shared image list must not be nil");
	if (self = [super init]) {
		self.imageShareList = list;
	}
	return self;
}

// Implement loadView to create a view hierarchy programmatically, without using a nib.

- (void)loadView {
	SHKLog(@"%s self:%@", __FUNCTION__, self);
	
    UIView * frameView = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
    [frameView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
	[frameView setBackgroundColor:[UIColor clearColor]];
		
	self.view = frameView;
	[frameView release];
    
    [self addCommonBackgroundView];
}

- (void)addCommonBackgroundView {
    UIImageView *backView = [[UIImageView alloc] initWithImage:[UIImage imageWithName:@"orange_tableview_bg"]];
    backView.frame = self.view.bounds;
    backView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:backView];
    [self.view sendSubviewToBack:backView];
    [backView release];
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	SHKLog(@"%s", __FUNCTION__);
	self.title = @"宝贝分享";
	
    [self setupShareView];
    
	imageShared = YES;
    
    sharerList = [[NSMutableArray alloc] initWithCapacity:1];
	
	UIBarButtonItem * mgmtButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"取消" style:UIBarButtonItemStyleBordered target:self action:@selector(cancelAction)];
	self.navigationItem.leftBarButtonItem = mgmtButtonItem;
	[mgmtButtonItem release];
	
	UIBarButtonItem * shareButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"发布" style:UIBarButtonItemStyleBordered target:self action:@selector(shareAction)];
	self.navigationItem.rightBarButtonItem = shareButtonItem;
	[self.navigationItem.rightBarButtonItem setEnabled:NO];
	[shareButtonItem release];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadImageFinished:) name:LOAD_IMAGE_FINISHED_NOTIFICATION object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(shareItemFinished:) name:@"SHKSendDidFinish" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(shareItemFailed:) name:@"SHKSendDidFailed" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(keyboardWillShow:) name: UIKeyboardWillShowNotification object: nil];
}


- (void)setupShareView {
	NSLog(@"%s size:%@", __FUNCTION__, NSStringFromCGRect(self.view.bounds));
    
    container = [[UIView alloc] initWithFrame:self.view.bounds];
    container.backgroundColor = [UIColor clearColor];
    container.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    
    float buttonWidth = (self.view.bounds.size.width  - 20.0f - 12.5 * 4)/5;
    if (IS_RUN_IN_IPAD()) {
        buttonWidth = 94.0f;
    }else {
        buttonWidth = 50.0f;
    }
    
    UITextView * shareView = [[UITextView alloc] initWithFrame:CGRectMake(10.0f, 10.0f, self.view.bounds.size.width - 20.0f, container.bounds.size.height - buttonWidth - 20.0f)];
	[shareView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
	self.textView = shareView;
	[shareView release];
	[textView setDelegate:self];
	[textView setFont:[UIFont systemFontOfSize:16.0]];
	textView.layer.cornerRadius = 2.0;
	textView.layer.borderWidth = 1.0f;
	textView.layer.borderColor = [[UIColor lightGrayColor] CGColor];
	if (self.sharedContext != nil) {
		[textView setText:self.sharedContext];//
	}
	[container addSubview:textView];
	
	operationQueue = [[NSOperationQueue alloc] init];
	NSLog(@"operationQueue: %d", [operationQueue retainCount]);
	
	UIButton * loadButton = nil;
    UIImage * selectedImage = [UIImage imageWithName:@"image_share_selected"];
	self.selectedView = [[[UIImageView alloc] initWithImage:selectedImage] autorelease];
    
    NSLog(@"frame:%@ button:%f", NSStringFromCGRect(textView.bounds), buttonWidth);
    
	for (int i = 0; i< ([self.imageShareList count] > 5 ? 5 : [self.imageShareList count]); i++) {
		//UIButton * button = [[UIButton alloc] initWithFrame:CGRectMake(10.0f+ (50+ 12.5) * i, 140.0, 50.0f, 50.0f)];
		loadButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
		
		loadButton.frame = CGRectMake(10.0f+ (buttonWidth + 12.5)*i, container.bounds.size.height - buttonWidth, buttonWidth, buttonWidth);
        [loadButton setAutoresizingMask:UIViewAutoresizingFlexibleTopMargin];
		loadButton.tag = i;
		
		[[loadButton layer] setCornerRadius:5.0];
		[[loadButton layer] setMasksToBounds:YES];
        [loadButton setClipsToBounds:YES];
		//[[loadButton layer] setBorderWidth:0.5f];
		
		[loadButton setBackgroundColor:[UIColor whiteColor]];
		
		[loadButton addTarget:self action:@selector(btnPressed:) forControlEvents:UIControlEventTouchUpInside];
		
		LoadImageOperation * loadOperation = [[LoadImageOperation alloc] initWithURL:[imageShareList objectAtIndex:i] withButton:loadButton];
		[operationQueue addOperation:loadOperation];
		[loadOperation release];
		
		[container addSubview:loadButton];
		[loadButton release];
	}
	
    [self.view addSubview:container];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
	[self.textView becomeFirstResponder];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
	if (IS_RUN_IN_IPAD()) {
        return UIInterfaceOrientationIsLandscape(toInterfaceOrientation);
    }
	
    return UIInterfaceOrientationIsPortrait(toInterfaceOrientation);
}

#pragma mark -
#pragma mark Share Item action Method implementation

- (NSArray *)autoSharedService {
    NSMutableArray *serviceList = [NSMutableArray array];
    for (SHKSharer * sharer in [[SHK authorizedService] allValues]) {
        if ([sharer shouldAutoShare]) {
            [serviceList addObject:sharer];
        }else {
            continue;
        }
    }
    
    return serviceList;
}


- (void)shareAction {
	NSLog(@"%s", __FUNCTION__);
    
    [textView resignFirstResponder];
	
	if ([textView.text length] == 0 || [textView.text length] > 140) {
		UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:@"提示" message:@"分享内容为空或过长" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil];
		[alertView show];
		[alertView release];
		return;
	}
	
	SHKItem *item = nil;
	
	if (imageShared && self.sharedImage != nil) {
		NSLog(@"shared an image");
		item = [SHKItem image:self.sharedImage title:@"Share Image"];
		[item setText:textView.text];
	}else {
		item = [SHKItem text:textView.text];
	}
	
	self.sharedItem = item;
	
    shareActionSheet = [[UIActionSheet alloc] initWithTitle:@"分享到"
                                                   delegate:self
                                          cancelButtonTitle:@"取消"
                                     destructiveButtonTitle:nil
                                          otherButtonTitles:@"全部", @"新浪微博", @"豆瓣说", //@"腾讯微博",
                        nil];
    
    if (IS_RUN_IN_IPAD()) {
        [shareActionSheet showFromBarButtonItem:self.navigationItem.rightBarButtonItem animated:YES];
    }else {
        [shareActionSheet showFromToolbar:self.navigationController.toolbar];
    }
}


- (void)shareToAllService {
    [sharerList addObjectsFromArray:[SHK sharedService]];
	[self shareItem2Service:self.sharedItem];
}


- (BOOL)hasServiceAutoShared {
    for (SHKSharer * sharer in [[SHK authorizedService] allValues]) {
        if ([sharer shouldAutoShare]) {
            return YES;
        }else {
            continue;
        }
    }
    
    return NO;
}


- (void)shareItem2Service:(SHKItem *)item {
    if ([sharerList count] != 0) {
        SHKSharer *sharer = [sharerList objectAtIndex:0];
        [sharerList removeObject:sharer];
        
        if ([[sharer class] canShareImage]) {
            [[sharer class] shareItem:item];
        }else {
            [[sharer class] shareItem:[SHKItem text:item.text]];
        }
    }
    
    /*
    for (SHKSharer * sharer in [[SHK authorizedService] allValues]) {
        if ([sharer shouldAutoShare] && [[sharer class] canShareImage]) {
            [[sharer class] shareItem:item];
        }else if ([sharer shouldAutoShare]) {
            [[sharer class] shareItem:[SHKItem text:item.text]];
        }
    }*/
}

- (void)cancelAction {
	NSLog(@"%s", __FUNCTION__);
    
    if (shareActionSheet && [shareActionSheet isVisible]) {
        [shareActionSheet dismissWithClickedButtonIndex:shareActionSheet.cancelButtonIndex animated:YES];
    }
	
	[self dismissModalViewControllerAnimated:YES];
}


#pragma mark -
#pragma mark Shared Image slected method implementation

-(void)btnPressed:(id)sender {
	UIButton * selectedButton = (UIButton *)sender;
	NSLog(@"%s tag: %d", __FUNCTION__, selectedButton.tag);
	
	[selectedView removeFromSuperview];
	[self shareImageWithButton:selectedButton];
}

-(void)shareImageWithButton:(UIButton *)button {
	[selectedView setFrame:CGRectMake(button.bounds.size.width - 18.0f, button.bounds.size.height - 18.0f, 18.0f, 18.0f)];
	[button addSubview:selectedView]; //selected first one by default
	
	imageShared = YES;
	self.sharedImage = button.currentBackgroundImage;
	self.sharedImgURL = [imageShareList objectAtIndex:[button tag]];
}


#pragma mark -
#pragma mark LoadImageOperation implementation

- (void)loadImageFinished:(NSNotification *)notification {
	NSLog(@"%s", __FUNCTION__);
	
	//UIImage * image = [notification object];
	UIButton * loadedButton = [notification object];
	
	//判断，当第一个按钮对应的宝贝图片加载完成后设置分享可操作
	if ([loadedButton tag] == 0) {
		[self shareImageWithButton:loadedButton];
		[self.navigationItem.rightBarButtonItem setEnabled:YES];
	}
}

- (void)shareItemFinished:(NSNotification *)notification {
	NSLog(@"%s", __FUNCTION__);
    
    if ([sharerList count] != 0) {
        [self shareItem2Service:self.sharedItem];
    }else {
        [self performSelectorOnMainThread:@selector(dismissShareItemController) withObject:nil waitUntilDone:[NSThread isMainThread]];
    }
}


- (void)shareItemFailed:(NSNotification *)notification {
    [sharerList removeAllObjects];
}


- (void)onTimer:(NSTimer *)timer {
    [self dismissModalViewControllerAnimated:YES];
    [timer invalidate];
}


- (void)dismissShareItemController {
    NSLog(@"%s", __FUNCTION__);
    
    if ([self retainCount] != 1) {
    	[NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(onTimer:) userInfo:nil repeats:YES];
    }else {
	    [self dismissModalViewControllerAnimated:YES];
    }
}


#pragma mark -
#pragma mark UIViewController Method implementation

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
	operationQueue = nil;
	
    container = nil;
    
	self.textView = nil;
	//self.imageButton = nil;
	self.imageShareList = nil;
	
	self.sharedContext = nil;
	self.sharedImage = nil;
	self.sharedImgURL = nil;
}


- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:nil object:nil];
	
    [container release];
	[textView release];
    [selectedView release];
	if (imageShareList != nil) {
		[imageShareList release];
	}
	[sharedContext release];
    [sharedItem release];
	
	[operationQueue release];
    
    [shareActionSheet release];
    
    [sharerList release];
	
    [super dealloc];
}

#pragma mark -
#pragma mark UIActionSheetDelegate Method implementation

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (self.sharedItem == nil) {
		return;
	}
	
    
    NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
    NSLog(@"%s clicked: %d title:%@", __FUNCTION__, buttonIndex, buttonTitle);
    
    if ([buttonTitle isEqualToString:@"全部"]) {
        [self shareToAllService];
        return;
    }
    
    NSString *sharerClass = [shareKitMap valueForKey:buttonTitle];
    if (![sharerClass isEqualToString:@"SHKDouban"]) {
        [NSClassFromString(sharerClass) shareItem:self.sharedItem];
    }else {
        if (self.sharedItem.shareType == SHKShareTypeImage && sharedImgURL != nil) {
			SHKItem * txtItem = [SHKItem text:[NSString stringWithFormat:@"%@", self.sharedItem.text]];
			[NSClassFromString(sharerClass) shareItem:txtItem];
		}
    }
    
}


#pragma mark -
#pragma mark UIKeyboard hide/show notification

- (void)keyboardWillShow:(NSNotification *)notification {
#ifdef __IPHONE_3_21
    CGRect frameStart;
    [[notification.userInfo objectForKey:UIKeyboardFrameBeginUserInfoKey] getValue:&frameStart];
    
    CGRect keyboardBounds = CGRectMake(0, 0, frameStart.size.width, frameStart.size.height);
#else
    CGRect keyboardBounds;
    [[notification.userInfo objectForKey:UIKeyboardBoundsUserInfoKey] getValue:&keyboardBounds];
#endif
    
    NSLog(@"%s bounds:%@", __FUNCTION__, NSStringFromCGRect(keyboardBounds));
    
    CGRect containerFrame = container.frame;
    containerFrame.size.height = self.view.bounds.size.height - keyboardBounds.size.height - 5.0f;
    container.frame = containerFrame;
}

@end
