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

#import "ConnectGlobal.h"

@protocol DialogDelegate;
@class Session;

@interface Dialog : UIView <UIWebViewDelegate> {
  id<DialogDelegate> _delegate;
  Session* _session;
  NSURL* _loadingURL;
  UIWebView* _webView;
  UIActivityIndicatorView* _spinner;
  UIImageView* _iconView;
  UILabel* _titleLabel;
  UIButton* _closeButton;
  UIDeviceOrientation _orientation;
  BOOL _showingKeyboard;
}

/**
 * 委托(delegate)。
 */
@property(nonatomic,assign) id<DialogDelegate> delegate;

/**
 * 已经登录的会话。
 */
@property(nonatomic,assign) Session* session;

/**
 * 视图顶部显示的标题。
 */
@property(nonatomic,copy) NSString* title;

/**
 * 创建视图但不显示它。
 */
- (id)initWithSession:(Session*)session;

/**
 * 动态显示视图。
 *
 * 视图将会以浮层的形式显示在当前主窗口之上。
 */
- (void)show;

/**
 * 显示对话的第一页。
 *
 * 不要直接调用它，要让子类实现它。
 */
- (void)load;

/**
 * 在对话框中显示某个URL的内容。
 */
- (void)loadURL:(NSString*)url method:(NSString*)method get:(NSDictionary*)getParams
        post:(NSDictionary*)postParams;

/**
 * 隐藏视图并通知委托成功或者取消。
 */
- (void)dismissWithSuccess:(BOOL)success animated:(BOOL)animated;

/**
 * 隐藏视图并通知委托出现错误。
 */
- (void)dismissWithError:(NSError*)error animated:(BOOL)animated;

/**
 * 子类重载并在显示对话前执行。
 */
- (void)dialogWillAppear;

/**
 * 子类重载并在隐藏对话前执行。
 */
- (void)dialogWillDisappear;


- (void)dialogDidSucceed:(NSURL*)url;

- (void)dialogDidCancel:(NSURL*)url;

@end

///////////////////////////////////////////////////////////////////////////////////////////////////

@protocol DialogDelegate <NSObject>

@optional

/**
 * 对话成功并且即将执行前调用。
 */
- (void)dialogDidSucceed:(Dialog*)dialog;

/**
 * 对话取消调用。
 */
- (void)dialogDidCancel:(Dialog*)dialog;

/**
 * 当对话因为出错失败时调用。
 */
- (void)dialog:(Dialog*)dialog didFailWithError:(NSError*)error;

/**
 * 是否接触链接后打开safari浏览器
 */
- (BOOL)dialog:(Dialog*)dialog shouldOpenURLInExternalBrowser:(NSURL*)url;

@end
