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

@protocol RequestDelegate;
@class Session;

@interface Request : NSObject {
  Session* _session;
  id<RequestDelegate> _delegate;
  NSString* _url;
  NSString* _method;
  id _userInfo;
  NSMutableDictionary* _params;
	NSObject* _dataParam;
	NSString* _dataName;
  NSDate* _timestamp;
  NSURLConnection* _connection;
  NSMutableData* _responseText;
}

/**
 * 为全局会话创建一个新的API request。
 */
+ (Request*)request;

/**
 * 为全局会话创建一个新的API request的delegate。
 */
+ (Request*)requestWithDelegate:(id<RequestDelegate>)delegate;

/**
 * 为某个全局会话创建一个新的API request。
 */
+ (Request*)requestWithSession:(Session*)session;

/**
 * 使用delegate为全局会话创建一个新的API request。
 */
+ (Request*)requestWithSession:(Session*)session delegate:(id<RequestDelegate>)delegate;

@property(nonatomic,assign) id<RequestDelegate> delegate;

/**
 * 执行的请求所指向的URL。
 */
@property(nonatomic,readonly) NSString* url;

/**
 * 将要调用的API方法。
 */
@property(nonatomic,readonly) NSString* method;

/**
 * 请求的用户用来帮助确定请求意义的对象。
 */
@property(nonatomic,retain) id userInfo;

/**
 * 传给API方法的参数Dictionary。
 */
@property(nonatomic,readonly) NSDictionary* params;

/**
 * 数据参数。
 *
 * 用在如photos.upload的接口调用中
 */
@property(nonatomic,readonly) NSObject* dataParam;

/**
 * 数据名称。
 *
 * 用在如photos.upload的接口调用中
 */
@property(nonatomic,readonly) NSString* dataName;

/**
 * 请求发送给服务器的时间戳。
 */
@property(nonatomic,readonly) NSDate* timestamp;

/**
 * 表明请求已经发出并等待回应的状态。
 */
@property(nonatomic,readonly) BOOL loading;

/**
 * 创建与会话对应的请求。
 */
- (id)initWithSession:(Session*)session;

/**
 * 异步调用API服务器的方法。
 */ 
- (void)call:(NSString*)method params:(NSDictionary*)params;

- (void)call:(NSString*)method params:(NSDictionary*)params dataParam:(NSObject*)dataParam dataName:(NSString*)dataName;

/**
 * 异步调用服务器的方法。
 */ 
- (void)post:(NSString*)url params:(NSDictionary*)params;

/**
 * 在收到回应前停止一个活动的请求。
 */
- (void)cancel;

@end

///////////////////////////////////////////////////////////////////////////////////////////////////

@protocol RequestDelegate <NSObject>

@optional

/**
 * 请求发送给服务器之前调用。
 */
- (void)requestLoading:(Request*)request;

/**
 * 服务器回应后准备再次发送数据时调用。
 */
- (void)request:(Request*)request didReceiveResponse:(NSURLResponse*)response;

/**
 * 错误使请求无法成功时调用。
 */
- (void)request:(Request*)request didFailWithError:(NSError*)error;

/**
 * 当收到回应回应并解析为对象后应用。
 *
 * 结果对应可以是dictionary，array，string，number，依赖于API返回的数据。
 */
- (void)request:(Request*)request didLoad:(id)result;

/**
 * 请求取消的时候调用。
 */
- (void)requestWasCancelled:(Request*)request;

@end
