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

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/**
 * 定义用户ID的类型
 */
typedef unsigned int RRUID;

/**
 * 定义发生错误的域
 */
#define API_ERROR_DOMAIN @"api.renren.com"

///////////////////////////////////////////
//全局的数据

NSMutableArray* RRCreateNonRetainingArray();

