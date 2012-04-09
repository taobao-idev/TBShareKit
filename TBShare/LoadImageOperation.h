//
//  LoadImageOperation.h
//  ShareKit
//
//  Created by HanFeng on 11-3-7.
//  Copyright 2011 Taobao.inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

#define LOAD_IMAGE_FINISHED_NOTIFICATION @"LOAD_IMAGE_FINISHED_NOTIFICATION"

//! 从网络加载图片操作，加载完成前按钮显示正在加载状态
@interface LoadImageOperation : NSOperation {
	NSString * imageURL;
	UIButton * imageButton;
	
	UIActivityIndicatorView * indicatorView;
}

//! 需要从网络加载图片的URL地址
@property (nonatomic, retain) NSString * imageURL;

//! 需要显示网络图片的UIButton
@property (nonatomic, retain) UIButton * imageButton;

//! 加载图片完成前需要显示的状态指示视图
@property (nonatomic, retain) UIActivityIndicatorView * indicatorView;

/*!
 初始化加载图片操作
 @param url 从网络加载图标的URL地址
 @param button 图片显示的载体，加载完成后显示图片的按钮
 */
- (id)initWithURL:(NSString *)url withButton:(UIButton *)button;

@end