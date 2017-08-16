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

#import "PBFacebookAdLoader.h"
@import FBAudienceNetwork;

@interface PBFacebookAdLoader () <FBAdViewDelegate>

@property (nonatomic, strong) FBAdView *fbAdView;

@end

@implementation PBFacebookAdLoader

- (void)fbLoadAd:(NSDictionary *)info {
    //NSString *bidPayload = (NSString *)info[@"adm"];
    // TODO nicole remove
    NSString *bidPayload = @"{\"type\":\"ID\",\"bid_id\":\"4401013946958491377\",\"placement_id\":\"1995257847363113_1997038003851764\",\"sdk_version\":\"4.25.0-appnexus.bidding\",\"device_id\":\"87ECBA49-908A-428F-9DE7-4B9CED4F486C\",\"template\":7,\"payload\":\"null\"}";

    CGFloat width = [(NSString *)info[@"width"] floatValue];
    CGFloat height = [(NSString *)info[@"height"] floatValue];
    CGSize adSize = CGSizeMake(width, height);

    FBAdSize fbAdSize;
//    if (CGSizeEqualToSize(adSize, kFBAdSize320x50.size)) {
//        fbAdSize = kFBAdSize320x50;
//    } else if (adSize.height == kFBAdSizeHeight250Rectangle.size.height) {
//        fbAdSize = kFBAdSizeHeight250Rectangle;
//    } else if (adSize.height == kFBAdSizeHeight90Banner.size.height) {
//        fbAdSize = kFBAdSizeHeight90Banner;
//    } else if (adSize.height == kFBAdSizeHeight50Banner.size.height) {
//        fbAdSize = kFBAdSizeHeight50Banner;
//    } else {
//        //[self.pbDelegate ad:nil didFailWithError:nil];
//        return;
//    }

    [FBAdSettings setLogLevel:FBAdLogLevelVerbose];
    
    self.fbAdView = [[FBAdView alloc] initWithPlacementID:[self parsePlacementIdFromBidPayload:bidPayload]
                                                      adSize:kFBAdSizeHeight250Rectangle
                                          rootViewController:(UIViewController *)[NSObject new]];
    self.fbAdView.frame = CGRectMake(0, 0, self.fbAdView.bounds.size.width, self.fbAdView.bounds.size.height);
    self.fbAdView.delegate = self;
    CGRect fbAdFrame = self.fbAdView.frame;
    fbAdFrame.size = CGSizeMake(300, 250);//adSize;
    self.fbAdView.frame = fbAdFrame;
    [self.fbAdView loadAdWithBidPayload:bidPayload];
    UIWindow *window = [[UIApplication sharedApplication] keyWindow];
    UIView *topView = window.rootViewController.view;
    [topView addSubview:self.fbAdView];
}

- (NSString *)parsePlacementIdFromBidPayload:(NSString *)bidPayload {
    NSError *jsonError;
    NSData *objectData = [bidPayload dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:objectData
                                                         options:NSJSONReadingMutableContainers
                                                           error:&jsonError];
    return [json objectForKey:@"placement_id"];
}

#pragma mark FBAdViewDelegate methods

- (void)adView:(FBAdView *)adView didFailWithError:(NSError *)error {
    NSLog(@"Facebook mediated ad failed to load with error: %@", error);
    [self.delegate ad:adView didFailWithError:error];
}

- (void)adViewDidLoad:(FBAdView *)adView {
    NSLog(@"Ad was loaded and ready to be displayed22");
    NSLog(@"Facebook mediated ad did load.");
    [self.delegate didLoadAd:adView];
}

- (void)adViewWillLogImpression:(FBAdView *)adView {
    NSLog(@"Facebook mediated ad will log impression.");
    [self.delegate trackImpression];
}

- (void)adViewDidClick:(FBAdView *)adView {
    NSLog(@"Facebook mediated ad did click.");
    [self.delegate didClickAd:adView];
}

- (void)adViewDidFinishHandlingClick:(FBAdView *)adView {
    NSLog(@"Facebook mediated ad did finish handling click.");
    [self.delegate didFinishHandlingClick:adView];
}

- (UIViewController *)viewControllerForPresentingModalView {
    return [self.delegate viewControllerForPresentingModalView];
}

@end
