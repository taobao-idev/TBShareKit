//
//  SHKShareController.h
//  ShareKit
//
//  Created by HanFeng on 11-1-21.
//  Copyright 2011 Taobao.inc. All rights reserved.
//

/**
 * 提供帐号管理，可以添加／删除分享帐号
 */

#import <UIKit/UIKit.h>

//! 显示已授权帐号和管理分享帐号的视图控制器
@interface SHKShareController : UITableViewController {
    NSArray * shareServiceList;
	NSMutableDictionary * accountDictionary;
}

//! 支持的分享服务列表，目前支持新浪微博，豆瓣说和腾讯微博
@property (nonatomic, retain) NSArray * shareServiceList;

//! 用户已经授权的服务和帐号相关信息
@property (nonatomic, retain) NSMutableDictionary * accountDictionary;

//! 打开/关闭自动分享功能
- (void)switchValueChanged:(id)sender;

//! 提供返回操作
- (void)backAction;

@end
