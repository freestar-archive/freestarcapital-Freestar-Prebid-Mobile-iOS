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

@import FBAudienceNetwork;
#import "PBFacebookInterstitialAdLoader.h"

@interface PBFacebookInterstitialAdLoader () <FBInterstitialAdDelegate>

@property (nonatomic, strong) FBInterstitialAd *fbInterstitialAd;

@end

@implementation PBFacebookInterstitialAdLoader

- (void)fbLoadAd:(NSDictionary *)info {
    //NSString *bidPayload = (NSString *)info[@"adm"];

    
    [FBAdSettings setLogLevel:FBAdLogLevelVerbose];
    
    NSString *instlBidPayload = @"{\"type\":\"ID\",\"bid_id\":\"1711944616674078449\",\"placement_id\":\"1995257847363113_1997038003851764\",\"sdk_version\":\"4.25.0-appnexus.bidding\",\"device_id\":\"87ECBA49-908A-428F-9DE7-4B9CED4F486C\",\"template\":102,\"payload\":\"null\"}";
    self.fbInterstitialAd = [[FBInterstitialAd alloc] initWithPlacementID:[self parsePlacementIdFromBidPayload:instlBidPayload]];
    self.fbInterstitialAd.delegate = self;
    UIWindow *window = [[UIApplication sharedApplication] keyWindow];
//    UIView *topView = window.rootViewController.view;
//    [topView addSubview:self.fbInterstitialAd];
    
    [self.fbInterstitialAd loadAdWithBidPayload:instlBidPayload];
    //[self.fbInterstitialAd loadAd];
    //[self.fbInterstitialAd showAdFromRootViewController:window.rootViewController];
    
}


- (NSString *)parsePlacementIdFromBidPayload:(NSString *)bidPayload {
    NSError *jsonError;
    NSData *objectData = [bidPayload dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:objectData
                                                         options:NSJSONReadingMutableContainers
                                                           error:&jsonError];
    return [json objectForKey:@"placement_id"];
}

#pragma mark FBInterstitialAdDelegate methods

- (void)interstitialAdDidLoad:(FBInterstitialAd *)interstitialAd {
    [self.fbInterstitialAd showAdFromRootViewController:[[UIApplication sharedApplication] keyWindow].rootViewController];
    NSLog(@"fb interstitial ad did load");
}

- (void)interstitialAd:(FBInterstitialAd *)interstitialAd didFailWithError:(NSError *)error {
    NSLog(@"fb interstitial ad did fail with error");
}

- (void)interstitialAdDidClick:(FBInterstitialAd *)interstitialAd {
    NSLog(@"fb interstitial ad did click");
}



@end
