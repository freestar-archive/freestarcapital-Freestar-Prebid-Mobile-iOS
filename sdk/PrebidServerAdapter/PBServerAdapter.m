/*   Copyright 2017 Prebid.org, Inc.
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import <AdSupport/AdSupport.h>
#import "PrebidCache.h"
#import <sys/utsname.h>
#import <UIKit/UIKit.h>

#import "PBBidResponse.h"
#import "PBBidResponseDelegate.h"
#import "PBLogging.h"
#import "PBServerAdapter.h"
#import "PBServerFetcher.h"
#import "PBTargetingParams.h"
#import "PBServerRequestBuilder.h"
#import "PBException.h"
#import "PBAnalyticsEvent.h"
#import "PBAnalyticsManager.h"
#import "PBGlobalFunctions.h"

static NSString *const kAPNAdServerCacheIdKey = @"hb_cache_id";
static int const kBatchCount = 10;

@interface PBServerAdapter ()

@property (nonatomic, strong) NSString *accountId;

@property (assign) PBPrimaryAdServerType primaryAdServer;

@property (nonatomic, assign, readwrite) PBServerHost host;

@end

@implementation PBServerAdapter

- (nonnull instancetype)initWithAccountId:(nonnull NSString *)accountId andAdServer:(PBPrimaryAdServerType) adServer{
    if (self = [super init]) {
        _accountId = accountId;
        _isSecure = TRUE;
        _host = PBServerHostAppNexus;
        _primaryAdServer = adServer;
    }
    return self;
}

- (nonnull instancetype)initWithAccountId:(nonnull NSString *)accountId andHost:(PBServerHost) host andAdServer:(PBPrimaryAdServerType) adServer{
    if (self = [super init]) {
        _accountId = accountId;
        _isSecure = TRUE;
        _host = host;
        _primaryAdServer = adServer;
    }
    return self;
}

- (void)requestBidsWithAdUnits:(nullable NSArray<PBAdUnit *> *)adUnits
                  withDelegate:(nonnull id<PBBidResponseDelegate>)delegate {
    
    [[PBServerRequestBuilder sharedInstance] setHost:_host];
    
    //batch the adunits to group of 10 & send to the server instead of this bulk request
    int adUnitsRemaining = (int)[adUnits count];
    int j = 0;
    
    while(adUnitsRemaining) {
        NSRange range = NSMakeRange(j, MIN(kBatchCount, adUnitsRemaining));
        NSArray<PBAdUnit *> *subAdUnitArray = [adUnits subarrayWithRange:range];
        adUnitsRemaining-=range.length;
        j+=range.length;
        
        NSURLRequest *request = [[PBServerRequestBuilder sharedInstance] buildRequest:subAdUnitArray withAccountId:self.accountId withSecureParams:self.isSecure];
        __weak typeof(self) weakSelf = self;
        [[PBServerFetcher sharedInstance] makeBidRequest:request withCompletionHandler:^(NSDictionary *adUnitToBidsMap, NSError *error) {
            __strong typeof(self) strongSelf = weakSelf;
            if (error) {
                [delegate didCompleteWithError:error];
                return;
            }
            
            NSMutableArray<NSDictionary*> *bidResponses = [[NSMutableArray alloc] init];
            for (NSString *adUnitId in [adUnitToBidsMap allKeys]) {
                NSArray *bidsArray = (NSArray *)[adUnitToBidsMap objectForKey:adUnitId];
                NSMutableArray *bidResponsesArray = [[NSMutableArray alloc] init];
                for (NSDictionary *bid in bidsArray) {
                    NSMutableDictionary *adServerTargetingCopy = [bid[@"ext"][@"prebid"][@"targeting"] mutableCopy];
                    if (adServerTargetingCopy != nil) {
                        // Check if resposne has cache id, since prebid server cache would fail for some reason and not set cache id on the response
                        // If cache id is not present, we do not pass the bid back
                        bool hasCacheID = NO;
                        for (NSString *key in adServerTargetingCopy.allKeys) {
                            if ([key containsString:@"hb_cache_id"]) {
                                hasCacheID = YES;
                            }
                        }
                        if (hasCacheID) {
                            PBBidResponse *bidResponse = [PBBidResponse bidResponseWithAdUnitId:adUnitId adServerTargeting:bid[@"ext"][@"prebid"][@"targeting"]];
                            bidResponse.responseInfo = bid;
                            PBLogDebug(@"Bid Successful with rounded bid targeting keys are %@ for adUnit id is %@", [bidResponse.customKeywords description], adUnitId);
                            [bidResponsesArray addObject:bidResponse];
                            
                            // analytics
                            NSDictionary *analyticsEventInfo = @{
                                                                 @"bidderCode" : ObjectOrNull(bid[@"seat"]),
                                                                 @"width" : ObjectOrNull(bid[@"w"]),
                                                                 @"height" : ObjectOrNull(bid[@"h"]),
                                                                 @"statusMessage" : @"",
                                                                 @"adId" : ObjectOrNull(bid[@"adid"]),
                                                                 @"ad" : ObjectOrNull(bid[@"adm"]),
                                                                 @"cpm" : ObjectOrNull(bid[@"price"]),
                                                                 @"creativeId" : ObjectOrNull(bid[@"crid"]),
                                                                 @"pubapiId" : @"",
                                                                 @"currencyCode" : ObjectOrNull(@"USD"),
                                                                 @"requestId" : ObjectOrNull(bid[@"id"]),
                                                                 @"responseTimestamp" : @([[NSDate date] timeIntervalSince1970]),
                                                                 @"requestTimestamp" : @([[NSDate date] timeIntervalSince1970]),
                                                                 @"bidder" : ObjectOrNull(bid[@"seat"]),
                                                                 @"adUnitCode" : ObjectOrNull(adUnitId),
                                                                 @"timeToRespond" : @(60),
                                                                 @"adjustment" : @(NO),
                                                                 @"ttl" : @(300)
                                                                 };
                            NSArray *keysForNullValues = [analyticsEventInfo allKeysForObject:[NSNull null]];
                            NSMutableDictionary *prunedAnalyticsInfo = [analyticsEventInfo mutableCopy];
                            // remove NSNulls
                            [prunedAnalyticsInfo removeObjectsForKeys:keysForNullValues];
                            [bidResponses addObject:prunedAnalyticsInfo];
                        }
                    }
                }
                if (bidResponsesArray.count == 0) {
                    // use code 0 to represent the no bid case for now
                    [delegate didCompleteWithError:[NSError errorWithDomain:@"prebid.org" code:0 userInfo:nil] ];
                } else {
                    [delegate didReceiveSuccessResponse:bidResponsesArray];
                }
            }
            [strongSelf trackBidResponses:bidResponses];
        }];
    }
}

- (void)trackBidResponses:(NSArray*)bidResponses {
    if (bidResponses == nil || bidResponses.count == 0) {
        return;
    }
    NSDictionary *infoWrapper = @{ @"bidResponses" : bidResponses };
    PBAnalyticsEvent *event = [[PBAnalyticsEvent alloc] initWithEventType:PBAnalyticsEventBidResponse];
    event.info = infoWrapper;
    [[PBAnalyticsManager sharedInstance] trackEvent:event];
}

@end
