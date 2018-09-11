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
