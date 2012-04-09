//
//  SHKServTypeController.h
//  ShareKit
//
//  Created by HanFeng on 11-1-21.
//  Copyright 2011 Taobao.inc. All rights reserved.
//

/**
 * 对不同服务的微博帐号提供支持，目前支持新浪，腾讯和豆瓣服务
 */

#import <UIKit/UIKit.h>

//! 显示支持的分享服务中未授权的服务，用户授权分享的入口
@interface SHKServTypeController : UITableViewController {
    NSArray * shareServiceList;
	NSMutableDictionary * serviceDictionary;
}

//! 目前支持分享的服务列表，暂时支持新浪微博，豆瓣说和腾讯微博
@property (nonatomic, retain) NSArray * shareServiceList;

//! 需要用户授权的服务字典
@property (nonatomic, retain) NSMutableDictionary * serviceDictionary;

@end
