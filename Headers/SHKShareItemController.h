//
//  SHKShareItemController.h
//  ShareKit
//
//  Created by HanFeng on 11-1-27.
//  Copyright 2011 Taobao.inc. All rights reserved.
//

/*! 
 @mainpage TBShareKit
 
 TBShareKit 在ShareKit的基础上，去掉了国内无法访问的facebook,twitter服务，
 添加了国内常用的分享服务，如新浪微博，腾讯微博和豆瓣说。
 
 该分享目前主要用在在淘宝客户端分享宝贝时使用，除了分享服务外，还提供了分享时需要的
 界面，可以输入分享内容和选择分享图图片。
 
 项目地址： http://iteam.taobao.ali.com/redmine/projects/tbsharekit
 
 */

/**
 * 分享时的主界面，可以输入要分享的内容和图片
 * 图片默认设置为传入图片地址列表对应的第一张图片，可以重新设置该分享图片
 * 图片因为需要从网络加载，所以加载图片采用单独线程加载，加载过程中图片分享按钮不可用
 */

#import <UIKit/UIKit.h>

@class SHKItem;


//! 分享宝贝时的主界面，可以输入分享内容和选择分享的图片
@interface SHKShareItemController : UIViewController <UITextViewDelegate, UIActionSheetDelegate> {
	UITextView * textView;
	UIImageView * selectedView;
	
	NSArray * imageShareList;
	
	NSString * sharedContext;
	
	UIImage * sharedImage; //the image to be shared
	NSString * sharedImgURL;
	
	NSOperationQueue * operationQueue; // 用于加载网络图片
	
	BOOL imageShared;
	
	SHKItem * sharedItem;
    
    UIActionSheet *shareActionSheet;
    
    NSMutableArray *sharerList;
}


//! 输入分享内容的文本框
@property (nonatomic, retain) UITextView * textView;

//! 选择分享后的标志图片，选中分享图片后显示该标志
@property (nonatomic, retain) UIImageView * selectedView;


//! 分享宝贝时要分享的内容，默认为宝贝的标题和该宝贝的链接
@property (nonatomic, retain) NSString * sharedContext;

//! 分享宝贝时，该宝贝相关的图片地址列表
@property (nonatomic, retain) NSArray * imageShareList;

//！ 选择分享的图片
@property (nonatomic, assign) UIImage * sharedImage;

//! 选择分享的图片的URL地址
@property (nonatomic, assign) NSString * sharedImgURL;

//! 分享完成后构建的SHKItem
@property (nonatomic, retain) SHKItem * sharedItem;


/*!
 初始化界面控件 
 */
- (void)setupShareView;

/*!
 为该视图控制器添加背景
 */
- (void)addCommonBackgroundView;

/*!
 根据宝贝相关的图片地址列表初始化控制器
 @param list 分享宝贝相关的图片地址列表
 */
- (id)initWithImageList:(NSArray *)list;

/*!
 分享宝贝到自动分享的服务
 @param item 根据分享内容和图片构建的SHKItem
 */
- (void)shareItem2Service:(SHKItem *)item;

@end
