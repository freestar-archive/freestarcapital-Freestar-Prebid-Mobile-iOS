
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

#import "PBLogging.h"
#import "PBServerFetcher.h"

@interface PBServerFetcher ()

@property (nonatomic, strong) NSMutableArray *requestTIDs;

@end

@implementation PBServerFetcher

+ (instancetype)sharedInstance {
    static dispatch_once_t _dispatchHandle = 0;
    static PBServerFetcher *_sharedInstance = nil;
    
    dispatch_once(&_dispatchHandle, ^{
        if (_sharedInstance == nil)
            _sharedInstance = [[PBServerFetcher alloc] init];
        
    });
    return _sharedInstance;
}

- (void)makeBidRequest:(NSURLRequest *)request withCompletionHandler:(void (^)(NSDictionary *, NSError *))completionHandler {
    PBLogDebug(@"Bid request to Prebid Server: %@ params: %@", request.URL.absoluteString, [[NSString alloc] initWithData:[request HTTPBody] encoding:NSUTF8StringEncoding]);
    NSDictionary *params = [NSJSONSerialization JSONObjectWithData:[request HTTPBody]
                                                           options:kNilOptions
                                                             error:nil];
    // Map request tids to ad unit codes to check to make sure response lines up
    if (self.requestTIDs == nil) {
        self.requestTIDs = [[NSMutableArray alloc] init];
    }
    @synchronized(self.requestTIDs) {
        if(params[@"tid"] != nil){
            [self.requestTIDs addObject:params[@"tid"]];
        }
    }

    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[[NSOperationQueue alloc] init]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                               if (response != nil && data.length > 0) {
                                   PBLogDebug(@"Bid response from Prebid Server: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
                                   //NSDictionary *adUnitToBids = [self processData:data];
                                   NSDictionary *openRTBAdUnitBidMap = [self processOpenRTBData:data];
                                   dispatch_async(dispatch_get_main_queue(), ^{
                                       completionHandler(openRTBAdUnitBidMap, nil);
                                   });
                               } else {
                                   dispatch_async(dispatch_get_main_queue(), ^{
                                       completionHandler(nil, error);
                                   });
                               }
                           }];
}

- (NSDictionary *)processOpenRTBData:(NSData *)data {
    NSError *error;
    id object = [NSJSONSerialization JSONObjectWithData:data
                                                options:kNilOptions
                                                  error:&error];
    if (error) {
        PBLogError(@"Error parsing ad server response");
        return [[NSMutableDictionary alloc] init];
    }
    if (!object) {
        return [[NSMutableDictionary alloc] init];
    }
    NSMutableDictionary *adUnitToBidsMap = [[NSMutableDictionary alloc] init];
    if ([object isKindOfClass:[NSDictionary class]]) {
        NSDictionary *response = (NSDictionary *)object;
        if ([[response objectForKey:@"seatbid"] isKindOfClass:[NSArray class]]) {
            NSArray *seatbids = (NSArray *)[response objectForKey:@"seatbid"];
            for (id seatbid in seatbids) {
                if ([seatbid isKindOfClass:[NSDictionary class]]) {
                    NSDictionary *seatbidDict = (NSDictionary *)seatbid;
                    if ([[seatbidDict objectForKey:@"bid"] isKindOfClass:[NSArray class]]) {
                        NSArray *bids = (NSArray *)[seatbidDict objectForKey:@"bid"];
                        for (id bid in bids) {
                            if ([bid isKindOfClass:[NSDictionary class]]) {
                                NSDictionary *bidDict = (NSDictionary *)bid;
                                // remove this code once we have the imp url sent from the PBS
                                NSMutableDictionary *modifiedBidDict = [self setstubburl:bidDict];
                                NSMutableArray *adUnitBids = [[NSMutableArray alloc] init];
                                if ([adUnitToBidsMap objectForKey:modifiedBidDict[@"impid"]] != nil) {
                                    adUnitBids = [adUnitToBidsMap objectForKey:modifiedBidDict[@"impid"]];
                                }
                                [adUnitBids addObject:modifiedBidDict];
                                [adUnitToBidsMap setObject:adUnitBids forKey:modifiedBidDict[@"impid"]];
                                //end remove
                                /*NSMutableArray *adUnitBids = [[NSMutableArray alloc] init];
                                if ([adUnitToBidsMap objectForKey:bidDict[@"impid"]] != nil) {
                                    adUnitBids = [adUnitToBidsMap objectForKey:bidDict[@"impid"]];
                                }
                                [adUnitBids addObject:bidDict];
                                [adUnitToBidsMap setObject:adUnitBids forKey:bidDict[@"impid"]];*/
                            }
                        }
                    }
                }
            }
        }
    }
    return adUnitToBidsMap;
}

-(NSMutableDictionary *) setstubburl:(NSDictionary *) bidDict{
    NSMutableDictionary *bidDictObject = [[NSMutableDictionary alloc] initWithDictionary:bidDict];
    [bidDictObject setObject:@"http://nym1-mobile.adnxs.com/it?e=wqT_3QLgBqBgAwAAAwDWAAUBCIuVm9UFEM7b0uLdipfjBBjkweW3vOPL7zsqNgkAAAECCPA_EQEHEAAA8D8ZEQkAIREJACkRCQAxCQmw4D8w78nrBTjFPUDFPUgCUJP27CVYxPBOYABoypJneM7ABIABAYoBA1VTRJIBAQbwUJgBAaABAagBAbABALgBA8ABBMgBAtABANgBAOABAPABAIoCO3VmKCdhJywgMjEyMDk2NSwgMTUyMDg4MDI2Nyk7dWYoJ3InLCA3OTM3OTIxOTYeAPCokgL1ASE2alV4MndqbHN1b0lFSlAyN0NVWUFDREU4RTR3QURnQVFBUkl4VDFRNzhuckJWZ0FZQXhvQUhBQWVBQ0FBUUNJQVFDUUFRR1lBUUdnQVFHb0FRT3dBUUM1QVNtTGlJTUFBUEFfd1FFcGk0aURBQUR3UDhrQjBiWl9ZTWZrX2pfWkFRQUFBQUFBQVBBXzRBRUE5UUVBQUFBQW1BSUFvQUlBdFFJQQEhAHYNCIh3QUlBeUFJQTRBSUE2QUlBLUFJQWdBTUJrQU1BbUFNQnFBUAXMmHVnTVJaR1ZtWVhWc2RDTk9XVTB5T2pNMk16QS6aAjkhSVEwbElBagUsEfgoeFBCT0lBUW9BRG9iPAD0FAHYAgDgAtTGPeoCNGl0dW5lcy5hcHBsZS5jb20vdXMvYXBwL2FwcG5leHVzLXNkay1hcHAvaWQ3MzY4Njk4MzOAAwCIAwGQAwCYAxegAwGqAwDAA5AcyAMA0gMoCAASJGU3NmQ4YWZkLTE2YjUtNDE5MS05M2FmLTUyMDJlZTYzNWRiYdgD-aN64AMA6AMC-AMAgAQAkgQGL3V0L3YymAQAogQLMTAuMS4xMy4xNTOoBOjLA7IEEQgCEAIY9AMgACgBKAIwADgDuAQAwAQAyAQA0gQRZGVmYXVsdCNOWU0yOjM2MzDaBAIIAOAEAPAEk_bsJYIFCTczNjg2OTgzM4gFAZgFAKAF____________AcAFAMkFSeAU8D_SBQkJCQxkAADYBQHgBQHwBbX7BfoFBAgAEACQBgGYBgA.&s=de2a0be5a0c391b37b0302aaaa1438f65435beee&referrer=itunes.apple.com%2Fus%2Fapp%2Fappnexus-sdk-app%2Fid736869833" forKey:@"burl"];
    
    return bidDictObject;
    
}

@end
