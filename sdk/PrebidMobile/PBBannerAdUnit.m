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

#import "PBBannerAdUnit.h"

@implementation PBBannerAdUnit

- (nonnull instancetype)initWithAdUnitIdentifier:(nonnull NSString *)identifier andConfigId:(nonnull NSString *)configId {
    return [super initWithIdentifier:identifier andAdType:PBAdUnitTypeBanner andConfigId:configId];
}

- (nonnull instancetype)initWithAdUnitIdentifier:(nonnull NSString *)identifier {
    return [super initWithIdentifier:identifier andAdType:PBAdUnitTypeBanner];
}

- (void)addSize:(CGSize)adSize {
    [super addSize:adSize];
}

@end
