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

#import "AppDelegate.h"

#import <PrebidMobile/PBBannerAdUnit.h>
#import <PrebidMobile/PBException.h>
#import <PrebidMobile/PBInterstitialAdUnit.h>
#import <PrebidMobile/PBTargetingParams.h>
#import <PrebidMobile/PrebidMobile.h>
#import <PrebidMobile/PBLogging.h>
#import "Constants.h"
#import "SettingsViewController.h"

@interface AppDelegate ()

@property (strong, nonatomic) UITabBarController *tabBarController;

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [self enablePrebidLogs];
    [self setupPrebidAndRegisterAdUnits];

    SettingsViewController *settingsViewController = [[SettingsViewController alloc] init];
    settingsViewController.title = @"Ad Settings";
    UINavigationController *settingsNavController = [[UINavigationController alloc] initWithRootViewController:settingsViewController];

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    self.window.rootViewController = settingsNavController;
    [self.window makeKeyAndVisible];

    // Override point for customization after application launch.
    return YES;
}

- (void)enablePrebidLogs {
    [PBLogManager setPBLogLevel:PBLogLevelAll];
}

- (BOOL)setupPrebidAndRegisterAdUnits {
    @try {
        // Prebid Mobile setup!
        [self setupPrebidLocationManager];

        PBBannerAdUnit *__nullable adUnit1 = [[PBBannerAdUnit alloc] initWithAdUnitIdentifier:kAdUnit1Id andConfigId:kAdUnit1ConfigId];
        PBInterstitialAdUnit *__nullable adUnit2 = [[PBInterstitialAdUnit alloc] initWithAdUnitIdentifier:kAdUnit2Id andConfigId:kAdUnit2ConfigId];
        
        [adUnit1 addSize:CGSizeMake(300, 250)];
        [adUnit1 addSize:CGSizeMake(300, 50)];
   
   //     [self setPrebidTargetingParams];

        [PrebidMobile registerAdUnits:@[adUnit1] withAccountId:kAccountId withHost:kPBServerHost andPrimaryAdServer:PBPrimaryAdServerDFP];
        
//        PBBannerAdUnit *__nullable adUnit1 = [[PBBannerAdUnit alloc] initWithAdUnitIdentifier:@"inline_article_ad_1" andConfigId:@"a0ddc571-ab60-40da-b64e-053d3db1bcee"];
//        [adUnit1 addSize:CGSizeMake(300, 250)];
//
//        PBBannerAdUnit *__nullable adUnit2 = [[PBBannerAdUnit alloc] initWithAdUnitIdentifier:@"inline_article_ad_2" andConfigId:@"68939aa1-2348-4086-9d0f-d06bc3447644"];
//        [adUnit2 addSize:CGSizeMake(300, 250)];
//
//        PBBannerAdUnit *__nullable adUnit3 = [[PBBannerAdUnit alloc] initWithAdUnitIdentifier:@"inline_article_ad_3" andConfigId:@"959c1b56-4d0f-4c27-b0c1-b7943c62a95a"];
//        [adUnit3 addSize:CGSizeMake(300, 250)];
//
//        PBBannerAdUnit *__nullable adUnit4 = [[PBBannerAdUnit alloc] initWithAdUnitIdentifier:@"inline_article_ad_4" andConfigId:@"105a2f50-6977-4030-b54b-b9a0a51f6c5c"];
//        [adUnit4 addSize:CGSizeMake(300, 250)];
//
//        PBBannerAdUnit *__nullable adUnit5 = [[PBBannerAdUnit alloc] initWithAdUnitIdentifier:@"inline_article_ad_5" andConfigId:@"59265a1a-b4be-4a79-93e9-ea8aede48481"];
//        [adUnit5 addSize:CGSizeMake(300, 250)];
//
//        PBBannerAdUnit *__nullable adUnit6 = [[PBBannerAdUnit alloc] initWithAdUnitIdentifier:@"inline_article_ad_6" andConfigId:@"81049806-2a2a-48c1-b383-cfed920e433c"];
//        [adUnit6 addSize:CGSizeMake(300, 250)];
//
//        PBBannerAdUnit *__nullable adUnit7 = [[PBBannerAdUnit alloc] initWithAdUnitIdentifier:@"interstitial_1" andConfigId:@"e259bdc7-9965-4bc9-a1c8-34ac3596716a"];
//        [adUnit7 addSize:CGSizeMake(320, 480)];
//
//        PBBannerAdUnit *__nullable adUnit8 = [[PBBannerAdUnit alloc] initWithAdUnitIdentifier:@"mpu_comments_1" andConfigId:@"d2803717-a515-4a8b-9696-64f47bc763c6"];
//        [adUnit8 addSize:CGSizeMake(300, 250)];
//
//        PBBannerAdUnit *__nullable adUnit9 = [[PBBannerAdUnit alloc] initWithAdUnitIdentifier:@"mpu_comments_2" andConfigId:@"264d5bf7-e8f3-4912-b7cb-432f008c4fd6"];
//        [adUnit9 addSize:CGSizeMake(300, 250)];
//
//        PBBannerAdUnit *__nullable adUnit10 = [[PBBannerAdUnit alloc] initWithAdUnitIdentifier:@"puff_ad_1" andConfigId:@"3fb3665c-f5af-4b9b-8206-2c430ddb2f99"];
//        [adUnit10 addSize:CGSizeMake(300, 250)];
        
        //[self setPrebidTargetingParams];
        //[PrebidMobile registerAdUnits:@[adUnit1, adUnit2, adUnit3, adUnit4, adUnit5, adUnit6, adUnit7, adUnit8, adUnit9, adUnit10] withAccountId:@"ff48cb82-f3d0-4893-875b-1b44a96bf3e3" withHost:kPBServerHost andPrimaryAdServer:PBPrimaryAdServerDFP];
        
    } @catch (PBException *ex) {
        NSLog(@"%@",[ex reason]);
    } @finally {
        return YES;
    }
}

- (void)setupPrebidLocationManager {
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    self.locationManager.distanceFilter = kCLDistanceFilterNone;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyKilometer;
    // Check for iOS 8. Without this guard the code will crash with "unknown selector" on iOS 7.
    if ([self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        [self.locationManager requestWhenInUseAuthorization];
    }
    [self.locationManager startUpdatingLocation];
}

- (void)setPrebidTargetingParams {
    [[PBTargetingParams sharedInstance] setAge:25];
    [[PBTargetingParams sharedInstance] setGender:PBTargetingParamsGenderFemale];
    //[[PBTargetingParams sharedInstance] setCustomTargeting:@"state" withValues:@[@"NJ", @"CA"]];
    
}

// Location Manager Delegate Methods
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    [[PBTargetingParams sharedInstance] setLocation:[locations lastObject]];
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


@end
