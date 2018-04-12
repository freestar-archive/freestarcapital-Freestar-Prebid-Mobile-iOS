//
//  PBBidManager+FSAdditions.m
//  PrebidMobile
//
//  Created by Dean Chang on 5/4/18.
//  Copyright © 2018 Nicole Hedley. All rights reserved.
//

#import "PBBidManager+FSAdditions.h"
#import "PBLogging.h"

@interface PBBidManager (Private)

@property (nonatomic, strong) NSMutableSet<PBAdUnit *> *adUnits;

- (void)resetAdUnit:(PBAdUnit *)adUnit;
- (void)requestBidsForAdUnits:(NSArray<PBAdUnit *> *)adUnits;

@end

@implementation PBBidManager (FSAdditions)

- (void)refreshAllBids {
    if (!self.adUnits || self.adUnits.count == 0) {
        PBLogWarn(@"No ad units registered for bid refresh.");
        return;
    }
    
    for (PBAdUnit *adUnit in self.adUnits) {
        [self resetAdUnit:adUnit];
    }
    [self requestBidsForAdUnits:[self.adUnits allObjects]];
}

@end
