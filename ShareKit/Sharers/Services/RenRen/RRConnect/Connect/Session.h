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

@protocol SessionDelegate;
@class Request;

/**
 * Session对象表示一个用户对某个人人网应用的认证会话。
 * 
 * 为了创建会话，必须使用你的应用的api key（可以通过在人人网注册app应用得到）。
 * 接着，你可以使用登录对话框要求用户输入人人网输入用户名和密码。
 * 如果用户名和密码验证成功，你将得到一个session key可以使用它来调用人人网的各种API接口或发送自定义新鲜事。
 * 
 * session key会缓存在设备的磁盘中，因此用户不必每次都输入用户名和密码来登录。
 * 你可以在初始化session对象后调用resume方法来恢复最后一次的活动对话。
 */
 
@interface Session : NSObject {
  NSMutableArray* _delegates;
  NSString* _apiKey;
  NSString* _apiSecret;
  NSString* _getSessionProxy;
  RRUID _uid;
  NSString* _sessionKey;
  NSString* _sessionSecret;
  NSDate* _expirationDate;
  NSMutableArray* _requestQueue;
  NSDate* _lastRequestTime;
  int _requestBurstCount;
  NSTimer* _requestTimer;
}

/**
 * 实现SessionDelegate的delegates。
 */
@property(nonatomic,readonly) NSMutableArray* delegates;

/**
 * 用来进行应用程序接口（API）HTTP请求的URL。
 */
@property(nonatomic,readonly) NSString* apiURL;

/**
 * 你的应用的API key，需要传给构造函数。
 */
@property(nonatomic,readonly) NSString* apiKey;

/**
 * 你的应用的API Secret，需要传给构造函数。
 */
@property(nonatomic,readonly) NSString* apiSecret;

/**
 *登录后用来调用创建session key的URL。
 *
 * 这是直接使用secret key调用auth.getSession外的另一种方式。
 */
@property(nonatomic,readonly) NSString* getSessionProxy;

/**
 * 当前用户的人人网用户ID。
 */
@property(nonatomic,readonly) RRUID uid;

/**
 * 当前用户的session key。
 */
@property(nonatomic,readonly) NSString* sessionKey;

/**
 * 当前用户的session secret。
 */
@property(nonatomic,readonly) NSString* sessionSecret;

/**
 * session key的过期时间。
 */
@property(nonatomic,readonly) NSDate* expirationDate;

/**
 * 确定会话是否保持活跃并连接到一个用户。
 */
@property(nonatomic,readonly) BOOL isConnected;

/**
 * 全局共享的会话实例。
 */
+ (Session*)session;

/**
 * 设置全局共享的会话实例。
 *
 * 会话并没有保持（retained），因此你要手动保持。 第一个会话实例会自动保持在这里。
 */
+ (void)setSession:(Session*)session;

/**
 * 构建一个全局的共享会话单例。
 *
 * @param secret 应用的secret。（可选参数）
 */
+ (Session*)sessionForApplication:(NSString*)key secret:(NSString*)secret
  delegate:(id<SessionDelegate>)delegate;

/**
 * 构建一个全局的共享会话单例。
 *
 * @param getSessionProxy 一个代理auth.getSession的URL。（可选参数）
 */
+ (Session*)sessionForApplication:(NSString*)key getSessionProxy:(NSString*)getSessionProxy
  delegate:(id<SessionDelegate>)delegate;

/**
 * 为应用构建一个会话。
 *
 * @param secret 应用的secret。（可选参数）
 * @param getSessionProxy 一个代理auth.getSession的URL。（可选参数）
 */
- (Session*)initWithKey:(NSString*)key secret:(NSString*)secret
  getSessionProxy:(NSString*)getSessionProxy;

/**
 * 为一个拥有给定key和secret的用户启动一个会话。
 */
- (void)begin:(RRUID)uid sessionKey:(NSString*)sessionKey sessionSecret:(NSString*)sessionSecret
  expires:(NSDate*)expires;

/**
 * 恢复一个uid，session key和secret都保存在磁盤上的会话。
 */
- (BOOL)resume;

/**
 * 取消登录，如果登录已经完成则不执行。
 */
- (void)cancelLogin;

/**
 * 结束当前会话并在磁盘上删除uid，session key以及secret。
 */
- (void)logout;

/**
 * 给服务器发送配置好的请求（request）来执行。
 */
- (void)send:(Request*)request;

@end

///////////////////////////////////////////////////////////////////////////////////////////////////

@protocol SessionDelegate <NSObject>

/**
 * 当用户成功登录并启动一个会话时调用。
 */
- (void)session:(Session*)session didLogin:(RRUID)uid;

@optional

/**
 * 当用户关闭登录而没有登录时调用。
 */
- (void)sessionDidNotLogin:(Session*)session;

/**
 * 当即将退出会话时调用。
 */
- (void)session:(Session*)session willLogout:(RRUID)uid;

/**
 * 当已经退出会话后调用。
 */
- (void)sessionDidLogout:(Session*)session;

@end
