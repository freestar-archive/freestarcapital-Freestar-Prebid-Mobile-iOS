/*   Copyright 2017 APPNEXUS INC
 
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

#import "PrebidMobileDFPIntMediationAdapter.h"

static NSString *const customEventErrorDomain = @"org.prebid.PrebidMobileMediationAdapter";

@interface PrebidMobileDFPIntMediationAdapter()

@property (strong, nonatomic) id adLoader;

@end

@implementation PrebidMobileDFPIntMediationAdapter

@synthesize delegate;
@synthesize viewControllerForPresentingModalView;

- (void)requestInterstitialAdWithParameter:(NSString *)serverParameter
                                     label:(NSString *)serverLabel
                                   request:(GADCustomEventRequest *)request {
    NSLog(@"got to mediation interstitial function");
    //    self.interstitial = [[SampleInterstitial alloc] init];
    //    self.interstitial.delegate = self;
    //    self.interstitial.adUnit = serverParameter;
    //    SampleAdRequest *adRequest = [[SampleAdRequest alloc] init];
    //    adRequest.testMode = request.isTesting;
    //    adRequest.keywords = request.userKeywords;
    //    [self.interstitial fetchAd:adRequest];
    PBCommonMediationAdapter *commonMediationAdapter = [[PBCommonMediationAdapter alloc] initWithCacheId:@"test_cacheId" andBidder:@"TestBidder" andMediationAdapterClass:self];
    self.adLoader = [commonMediationAdapter requestAdmAndLoadAd];
}

-(void)presentFromRootViewController:(UIViewController *)rootViewController {
    NSLog(@"got here");
}
//
//// Sent when an interstitial ad has loaded.
//- (void)interstitialDidLoad:(SampleInterstitial *)interstitial {
//    [self.delegate customEventInterstitialDidReceiveAd:self];
//}
//
//// Sent when an interstitial ad has failed to load.
//- (void)interstitial:(SampleInterstitial *)interstitial
//didFailToLoadAdWithErrorCode:(SampleErrorCode)errorCode {
//    NSError *error = [NSError errorWithDomain:customEventErrorDomain
//                                         code:errorCode
//                                     userInfo:nil];
//    [self.delegate customEventInterstitial:self didFailAd:error];
//}
//
//// Sent when an interstitial is about to be shown.
//- (void)interstitialWillPresentScreen:(SampleInterstitial *)interstitial {
//    [self.delegate customEventInterstitialWillPresent:self];
//}
//
//// Sent when an interstitial is about to be dismissed.
//- (void)interstitialWillDismissScreen:(SampleInterstitial *)interstitial {
//    [self.delegate customEventInterstitialWillDismiss:self];
//}
//
//// Sent when an interstitial has been dismissed.
//- (void)interstitialDidDismissScreen:(SampleInterstitial *)interstitial {
//    [self.delegate customEventInterstitialDidDismiss:self];
//}
//
//// Sent when an interstitial is clicked and an external application is launched.
//- (void)interstitialWillLeaveApplication:(SampleInterstitial *)interstitial {
//    [self.delegate customEventInterstitialWasClicked:self];
//    [self.delegate customEventInterstitialWillLeaveApplication:self];
//}


@end
