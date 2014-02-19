// Copyright Engageclick 2013
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import <Foundation/Foundation.h>
#import <sys/types.h>
#import <sys/socket.h>
#import <ifaddrs.h>
#import <netinet/in.h>
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonHMAC.h>
#import <UIKit/UIKit.h>
#import <UIKit/UIDevice.h>
#include <sys/sysctl.h>
#include <net/if.h>
#include <net/if_dl.h>
#import <AdSupport/AdSupport.h>



#define ECAD_SDK_VERION @"1.0.3"

#define ECAD_USER_AGENT_KEY @"ua"
#define ECAD_APP_KEY @"app"
#define ECAD_MACSHA1_KEY @"mac_sha1"
#define ECAD_MACMD5_KEY @"mac_md5"
#define ECAD_TOKENSHA1_KEY @"token_sha1"
#define ECAD_TOKENMD5_KEY @"token_md5"
#define ECAD_IP_KEY @"ip"
#define ECAD_FORMAT_KEY @"format"
#define ECAD_REQUESTER_KEY @"requester"
#define ECAD_TIMESTAMP_KEY @"ts"
#define ECAD_BANNER_TYPE_KEY @"banner_type"
#define ECAD_ACTION_TYPE_KEY @"at"
#define ECAD_APP_NAME_KEY @"app_name"
#define ECAD_APP_VERSION_KEY @"app_version"
#define ECAD_FIRST_LAUNCH_KEY @"first_launch"
#define ECAD_DEBUG_KEY @"debug"
#define ECAD_SDK_VERION_KEY @"version"
#define ECAD_AGE_KEY @"age"
#define ECAD_GENDER_KEY @"gender"
#define ECAD_LNG_KEY @"lng"
#define ECAD_LAT_KEY @"lat"
#define ECAD_ORIENTATION_KEY @"orientation"
#define ECAD_DEVICE_WIDTH_KEY @"device_width"
#define ECAD_DEVICE_HEIGHT_KEY @"device_height"
#define ECAD_PARENT_HEIGHT_KEY @"parent_height"
#define ECAD_PARENT_WIDTH_KEY @"parent_width"
#define ECAD_MRAID_KEY @"mraid"
#define ECAD_TRACKING_KEY @"tracking_data"
#define ECAD_ADVERTISER_IDENTIFIER_KEY @"id4ads"

NSString *UserAgentString(void);

@interface ECAdUtilities : NSObject
+ (NSString*) getIP;
+ (NSString*) getMacMD5Hash;
+ (NSString*) getMacSHA1Hash;
+ (NSString*) getTimestamp;
+ (NSString*) getAppName;
+ (NSString*) getAppVersion;
+ (CGSize)    getScreenResolution;
+ (NSString*) getDeviceOrientation;
+ (NSString*) getShortAppVersion;
+ (NSString*) getScreenScale;

@end
