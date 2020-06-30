//
//  PBUserAgentBuilder.m
//  PrebidMobileFS
//
//  Created by Dean Chang on 6/30/20.
//  Copyright © 2020 Freestar. All rights reserved.
//

#import "PBUserAgentBuilder.h"
#import <UIKit/UIKit.h>

@implementation PBUserAgentBuilder

//eg. Darwin/16.3.0
static NSString * safariVersion() {
    NSBundle *webKit = [NSBundle bundleWithIdentifier:@"com.apple.WebKit"];
    NSString *version = [[webKit infoDictionary] objectForKey:@"CFBundleVersion"];
    if (version.length > 0) {
        version = [version substringFromIndex:1];
        NSArray *versions = [version componentsSeparatedByString:@"."];
        if (versions.count >= 3) {
            version = [NSString stringWithFormat:@"%@.%@.%@", versions[0], versions[1], versions[2]];
        }
    }
    return [NSString stringWithFormat:@"AppleWebKit/%@", version];
}

static NSString * osVersion() {
    NSOperatingSystemVersion version = [[NSProcessInfo processInfo] operatingSystemVersion];
    return [NSString stringWithFormat:@"%li_%li_%li", (long)version.majorVersion, (long)version.minorVersion, (long)version.patchVersion];
}

static NSString* deviceName()
{
    return [[UIDevice currentDevice] model];
}

// Mozilla/5.0 (iPhone; CPU iPhone OS 12_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148
+ (NSString*)getUserAgent {
    return [NSString stringWithFormat:@"Mozilla/5.0 (%@; CPU %@ OS %@ like Mac OS X) %@ (KHTML, like Gecko) Mobile/15E148", deviceName(), deviceName(), osVersion(), safariVersion()];
}

@end
