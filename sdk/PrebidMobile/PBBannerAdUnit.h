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

#import "PBAdUnit.h"

@interface PBBannerAdUnit : PBAdUnit

/**
 * Initializes the BannerAdUnit with an identifier
 * @param identifier : the identifier is a developer specific identity given for each of the ad unit created
 * @param configId : the config id with the demand sources from prebid server
 */
- (nonnull instancetype)initWithAdUnitIdentifier:(nonnull NSString *)identifier andConfigId:(nonnull NSString *)configId;

/**
 * Initializes the BannerAdUnit with an identifier
 * @param identifier : the identifier is a developer specific identity given for each of the ad unit created
 */
- (nonnull instancetype)initWithAdUnitIdentifier:(nonnull NSString *)identifier;

/**
 * addSize adds the size object to the BannerAdUnit object created
 * @param adSize : width & height of the ad that needs to be fetched
 */
- (void)addSize:(CGSize)adSize;

@end
