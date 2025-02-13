/// Copyright 2015 Google Inc. All rights reserved.
///
/// Licensed under the Apache License, Version 2.0 (the "License");
/// you may not use this file except in compliance with the License.
/// You may obtain a copy of the License at
///
///    http://www.apache.org/licenses/LICENSE-2.0
///
///    Unless required by applicable law or agreed to in writing, software
///    distributed under the License is distributed on an "AS IS" BASIS,
///    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
///    See the License for the specific language governing permissions and
///    limitations under the License.

#import <Foundation/Foundation.h>

#import "Source/common/SNTCommonEnums.h"

@class SNTSyncManager;
@class MOLXPCConnection;

/// An instance of this class is passed to each stage of the sync process for storing data
/// that might be needed in later stages.
@interface SNTSyncState : NSObject

/// Configured session to use for requests.
@property NSURLSession *session;

/// Connection to the daemon control interface.
@property MOLXPCConnection *daemonConn;

/// The base API URL.
@property NSURL *syncBaseURL;

/// An XSRF token to send in the headers with each request.
@property NSString *xsrfToken;

/// Full sync interval in seconds, defaults to kDefaultFullSyncInterval. If push notifications are
/// being used this interval will be ignored in favor of pushNotificationsFullSyncInterval.
@property NSUInteger fullSyncInterval;

/// An token to subscribe to push notifications.
@property(copy) NSString *pushNotificationsToken;

/// Full sync interval in seconds while listening for push notifications, defaults to
/// kDefaultPushNotificationsFullSyncInterval.
@property NSUInteger pushNotificationsFullSyncInterval;

/// Leeway time in seconds when receiving a global rule sync push notification, defaults to
/// kDefaultPushNotificationsGlobalRuleSyncDeadline.
@property NSUInteger pushNotificationsGlobalRuleSyncDeadline;

/// Machine identifier and owner.
@property(copy) NSString *machineID;
@property(copy) NSString *machineOwner;

/// Settings sent from server during preflight that are set during postflight.
@property SNTClientMode clientMode;
@property NSString *allowlistRegex;
@property NSString *blocklistRegex;
@property NSNumber *blockUSBMount;
// Array of mount args for the forced remounting feature.
@property NSArray *remountUSBMode;

/// Clean sync flag, if True, all existing rules should be deleted before inserting any new rules.
@property BOOL cleanSync;

/// Batch size for uploading events.
@property NSUInteger eventBatchSize;

/// Array of bundle IDs to find binaries for.
@property NSArray *bundleBinaryRequests;

/// The header value for ContentEncoding when sending compressed content.
/// Either "deflate" (default) or "zlib".
@property(copy) NSString *compressedContentEncoding;

@end
