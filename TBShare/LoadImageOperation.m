//
//  LoadImageOperation.m
//  ShareKit
//
//  Created by HanFeng on 11-3-7.
//  Copyright 2011 Taobao.inc. All rights reserved.
//

#import "LoadImageOperation.h"

@interface LoadImageOperation ()

//! 从网络加载完成图片后调用的方法，设置按钮背景和按钮可用，并对外发出通知
- (void)didFinishLoading:(UIImage *)image;

@end


@implementation LoadImageOperation

@synthesize imageURL;
@synthesize imageButton;

@synthesize indicatorView;

- (id)initWithURL:(NSString *)url withButton:(UIButton *)button {
	if (self = [super init]) {
		self.imageURL = url;
		self.imageButton = button;
		[self.imageButton setEnabled:NO]; //加载图片期间按钮不可用以保证加载完成获得图像数据
        
        UIActivityIndicatorView * view = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [view setCenter:CGPointMake(button.frame.size.width/2, button.frame.size.height/2)];
        self.indicatorView = view;
        [self.indicatorView startAnimating];
        [self.imageButton addSubview:view];
        [view release];
	}
	
	return self;
}

#pragma mark -
#pragma mark NSOperation Method implementation
- (void)main {
	NSLog(@"%s", __FUNCTION__);
	
	NSAutoreleasePool * releasePool = [[NSAutoreleasePool alloc] init];
	
	if ([self isCancelled] == NO && self.imageURL != nil) {
		NSURL * loadURL = [NSURL URLWithString:self.imageURL];
		if (loadURL) {
			NSData * imgData = [NSData dataWithContentsOfURL:loadURL];
			UIImage * image = [UIImage imageWithData:imgData];
			
			//[self didFinishLoading:image];
			[self performSelectorOnMainThread:@selector(didFinishLoading:) withObject:image waitUntilDone:[NSThread isMainThread]];
		}
	}
	
	[releasePool release];
}

/*!
 图片加载完成后按钮显示该图片，设置按钮可用并通知图片加载完成
 @param image 从网络加载完成的图片
 */
- (void)didFinishLoading:(UIImage *)image {
	[imageButton setBackgroundImage:image forState:UIControlStateNormal];
	[indicatorView stopAnimating];
	[[NSNotificationCenter defaultCenter] postNotificationName:LOAD_IMAGE_FINISHED_NOTIFICATION object:imageButton]; // 发出通知，设置分享按钮可用
	[self.imageButton setEnabled:YES];
}

- (void)dealloc {
	[imageURL release];
	[indicatorView release];
	[imageButton release];
	
	[super dealloc];
}

@end
