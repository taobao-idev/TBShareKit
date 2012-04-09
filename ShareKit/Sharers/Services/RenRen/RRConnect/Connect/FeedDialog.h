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

#import "Dialog.h"
#import "Request.h"

@interface FeedDialog : Dialog {
  int _templateId;
  NSString* _templateData;
  NSString* _bodyGeneral;
	NSString* _userMessage;
	NSString* _userMessagePrompt;
	Request* _getSessionRequest;
}

@property(nonatomic) int templateId;
@property(nonatomic,copy) NSString* templateData;
@property(nonatomic,copy) NSString* bodyGeneral;
@property(nonatomic,copy) NSString* userMessage;
@property(nonatomic,copy) NSString* userMessagePrompt;

@end
