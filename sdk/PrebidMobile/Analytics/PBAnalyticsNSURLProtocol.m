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

#import "PBAnalyticsNSURLProtocol.h"

#import <Foundation/Foundation.h>
#import "PBCanonicalRequest.h"
#import "PBNSURLSessionDemux.h"
#import "PBLogging.h"
#import "PBAnalyticsManager.h"
#import "PBBidManager.h"
#import "NSURL+Query.h"
#import "PBBidResponse.h"
#import "PBAnalyticsEvent.h"
#import "PBGlobalFunctions.h"

#define PrebidCacheDomain @"prebid-cache.pub.network"
#define DFPAdManagerDomain @"pubads.g.doubleclick.net"
#define DFPAdManagerDomainPath @"pubads.g.doubleclick.net/gampad/"

typedef void (^ChallengeCompletionHandler)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential * credential);

@interface PBAnalyticsNSURLProtocol() <NSURLSessionDataDelegate>

@property (atomic, strong, readwrite) NSThread *clientThread;       ///< The thread on which we should call the client.

/*! The run loop modes in which to call the client.
 *  \details The concurrency control here is complex.  It's set up on the client
 *  thread in -startLoading and then never modified.  It is, however, read by code
 *  running on other threads (specifically the main thread), so we deallocate it in
 *  -dealloc rather than in -stopLoading.  We can be sure that it's not read before
 *  it's set up because the main thread code that reads it can only be called after
 *  -startLoading has started the connection running.
 */

@property (atomic, copy, readwrite) NSArray *modes;
@property (atomic, assign, readwrite) NSTimeInterval startTime;          ///< The start time of the request; written by client thread only; read by any thread.
@property (atomic, strong, readwrite) NSURLSessionDataTask *task;               ///< The NSURLSession task for that request; client thread only.
@property (atomic, strong, readwrite) NSMutableData *receivedData;
//@property (atomic, strong, readwrite) NSURLAuthenticationChallenge *    pendingChallenge;
//@property (atomic, copy,   readwrite) ChallengeCompletionHandler        pendingChallengeCompletionHandler;  ///< The completion handler that matches pendingChallenge; main thread only.

@end

@implementation PBAnalyticsNSURLProtocol

#pragma mark * Subclass specific additions

+ (void)start
{
    [NSURLProtocol registerClass:self];
}

/*! Returns the session demux object used by all the protocol instances.
 *  \details This object allows us to have a single NSURLSession, with a session delegate,
 *  and have its delegate callbacks routed to the correct protocol instance on the correct
 *  thread in the correct modes.  Can be called on any thread.
 */

+ (PBNSURLSessionDemux *)sharedDemux
{
    static dispatch_once_t      sOnceToken;
    static PBNSURLSessionDemux * sDemux;
    dispatch_once(&sOnceToken, ^{
        NSURLSessionConfiguration *     config;
        
        config = [NSURLSessionConfiguration defaultSessionConfiguration];
        // You have to explicitly configure the session to use your own protocol subclass here
        // otherwise you don't see redirects <rdar://problem/17384498>.
        config.protocolClasses = @[ self ];
        sDemux = [[PBNSURLSessionDemux alloc] initWithConfiguration:config];
    });
    return sDemux;
}

#pragma mark * NSURLProtocol overrides

/*! Used to mark our recursive requests so that we don't try to handle them (and thereby
 *  suffer an infinite recursive death).
 */

static NSString * kOurRecursiveRequestFlagProperty = @"org.prebid.dts.PBAnalyticsNSURLProtocol";
static NSString * kOurPrebidCacheRequestFlagProperty = @"io.freestar.prebid-cache.PBAnalyticsNSURLProtocol";
static NSString * kOurDFPFlagRequestProperty = @"io.freestar.dfp.PBAnalyticsNSURLProtocol";

+ (BOOL)canInitWithRequest:(NSURLRequest *)request
{
    BOOL        shouldAccept;
    NSURL *     url;
    NSString *  scheme;
    
    // check to see if analytics is enabled
    shouldAccept = [PBAnalyticsManager sharedInstance].isEnabled;
    if (!shouldAccept) {
        return NO;
    }
    
    // Check the basics.  This routine is extremely defensive because experience has shown that
    // it can be called with some very odd requests <rdar://problem/15197355>.
    
    shouldAccept = (request != nil);
    if (shouldAccept) {
        url = [request URL];
        shouldAccept = (url != nil);
    }
    
    // Decline our recursive requests.
    if (shouldAccept) {
        shouldAccept = ([self propertyForKey:kOurRecursiveRequestFlagProperty inRequest:request] == nil);
    }
    
    // Get the scheme.
    if (shouldAccept) {
        scheme = [[url scheme] lowercaseString];
        // matches http and https
        shouldAccept = [scheme hasPrefix:@"http"];
    }
    
    // check for correct domain
    if (shouldAccept) {
        if ([self isPrebidCacheRequestWithURL:url]) {
            //            PBLogDebug(@"accept prebid cache request %@", url);
            NSString *uuid = [request.URL pb_queryValueForKey:@"uuid"];
            // bidWon event
            PBBidResponse *bidWon = [[PBBidManager sharedInstance] usedBidWithCacheUUID:uuid];
            [self trackBidWon:bidWon];
            // we don't need to manage this request
            shouldAccept = NO;
        } else if ([self isDFPRequestWithURL:url]) {
            //            PBLogDebug(@"accept DFP request %@", url);
            shouldAccept = YES;
        } else {
            // do not manage this request
            shouldAccept = NO;
        }
    }
    
    return shouldAccept;
}

+ (BOOL)isPrebidCacheRequestWithURL:(NSURL*)url {
    NSURLComponents *urlComponents = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:YES];
    BOOL isPrebidCacheRequest = [url.absoluteString containsString:PrebidCacheDomain];
    isPrebidCacheRequest = isPrebidCacheRequest && [[[urlComponents host] lowercaseString] isEqualToString:PrebidCacheDomain];
    return isPrebidCacheRequest;
}

+ (BOOL)isDFPRequestWithURL:(NSURL*)url {
    NSURLComponents *urlComponents = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:YES];
    BOOL isDFPRequest = [url.absoluteString containsString:DFPAdManagerDomainPath];
    isDFPRequest = isDFPRequest && [[[urlComponents host] lowercaseString] isEqualToString:DFPAdManagerDomain];
    return isDFPRequest;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request
{
    NSURLRequest *      result;
    
    if (request == nil) {
        return nil;
    }
    // can be called on any thread
    
    // Canonicalising a request is quite complex, so all the heavy lifting has
    // been shuffled off to a separate module.
    
    result = CanonicalRequestForRequest(request);
    
    // if request cannot be canonicalised, return original request
    if (result == nil) {
        return request;
    }
    
    //    PBLogDebug(@"canonicalized %@ to %@", [request URL], [result URL]);
    return result;
}

- (id)initWithRequest:(NSURLRequest *)request cachedResponse:(NSCachedURLResponse *)cachedResponse client:(id <NSURLProtocolClient>)client
{
    if (request == nil || client == nil) {
        return nil;
    }
    // cachedResponse may be nil
    // can be called on any thread
    
    self = [super initWithRequest:request cachedResponse:cachedResponse client:client];
    if (self != nil) {
        // All we do here is log the call.
        //        PBLogDebug(@"init for %@ from <%@ %p>", [request URL], [client class], client);
    }
    return self;
}

- (void)dealloc
{
    self->_task = nil;
    //    assert(self->_pendingChallenge == nil);         // we should have cancelled it by now
    //    assert(self->_pendingChallengeCompletionHandler == nil);    // we should have cancelled it by now
}

- (void)startLoading
{
    NSMutableURLRequest *   recursiveRequest;
    NSMutableArray *        calculatedModes;
    NSString *              currentMode;
    
    // At this point we kick off the process of loading the URL via NSURLSession.
    // The thread that calls this method becomes the client thread.
    
    assert(self.clientThread == nil);           // you can't call -startLoading twice
    assert(self.task == nil);
    
    // Calculate our effective run loop modes.  In some circumstances (yes I'm looking at
    // you UIWebView!) we can be called from a non-standard thread which then runs a
    // non-standard run loop mode waiting for the request to finish.  We detect this
    // non-standard mode and add it to the list of run loop modes we use when scheduling
    // our callbacks.  Exciting huh?
    //
    // For debugging purposes the non-standard mode is "WebCoreSynchronousLoaderRunLoopMode"
    // but it's better not to hard-code that here.
    
    assert(self.modes == nil);
    calculatedModes = [NSMutableArray array];
    [calculatedModes addObject:NSDefaultRunLoopMode];
    currentMode = [[NSRunLoop currentRunLoop] currentMode];
    if ( (currentMode != nil) && ! [currentMode isEqual:NSDefaultRunLoopMode] ) {
        [calculatedModes addObject:currentMode];
    }
    self.modes = calculatedModes;
    assert([self.modes count] > 0);
    
    // Create new request that's a clone of the request we were initialised with,
    // except that it has our 'recursive request flag' property set on it.
    
    recursiveRequest = [[self request] mutableCopy];
    assert(recursiveRequest != nil);
    
    NSURL *url = [self request].URL;    
    if ([self.class isPrebidCacheRequestWithURL:url]) {
        [[self class] setProperty:@YES forKey:kOurPrebidCacheRequestFlagProperty inRequest:recursiveRequest];
    } else if ([self.class isDFPRequestWithURL:url]) {
        [[self class] setProperty:@YES forKey:kOurDFPFlagRequestProperty inRequest:recursiveRequest];
    }
    
    [[self class] setProperty:@YES forKey:kOurRecursiveRequestFlagProperty inRequest:recursiveRequest];
    
    self.startTime = [NSDate timeIntervalSinceReferenceDate];
    //    if (currentMode == nil) {
    //        PBLogDebug(@"start %@", [recursiveRequest URL]);
    //    } else {
    //        PBLogDebug(@"start %@ (mode %@)", [recursiveRequest URL], currentMode);
    //    }
    
    // Latch the thread we were called on, primarily for debugging purposes.
    self.clientThread = [NSThread currentThread];
    
    // Once everything is ready to go, create a data task with the new request.
    self.task = [[[self class] sharedDemux] dataTaskWithRequest:recursiveRequest delegate:self modes:self.modes];
    assert(self.task != nil);
    
    [self.task resume];
}

- (void)stopLoading
{
    // The implementation just cancels the current load (if it's still running).
    //    PBLogDebug(@"stop (elapsed %.1f)", [NSDate timeIntervalSinceReferenceDate] - self.startTime);
    
    assert(self.clientThread != nil);           // someone must have called -startLoading
    
    // Check that we're being stopped on the same thread that we were started
    // on.  Without this invariant things are going to go badly (for example,
    // run loop sources that got attached during -startLoading may not get
    // detached here).
    //
    // I originally had code here to bounce over to the client thread but that
    // actually gets complex when you consider run loop modes, so I've nixed it.
    // Rather, I rely on our client calling us on the right thread, which is what
    // the following assert is about.
    
    assert([NSThread currentThread] == self.clientThread);
    
    if (self.task != nil) {
        [self.task cancel];
        self.task = nil;
        // The following ends up calling -URLSession:task:didCompleteWithError: with NSURLErrorDomain / NSURLErrorCancelled,
        // which specificallys traps and ignores the error.
    }
    // Don't nil out self.modes; see property declaration comments for a a discussion of this.
}

#pragma mark * NSURLSession delegate callbacks

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task willPerformHTTPRedirection:(NSHTTPURLResponse *)response newRequest:(NSURLRequest *)newRequest completionHandler:(void (^)(NSURLRequest *))completionHandler
{
    NSMutableURLRequest *    redirectRequest;
    
#pragma unused(session)
#pragma unused(task)
    assert(task == self.task);
    assert(response != nil);
    assert(newRequest != nil);
#pragma unused(completionHandler)
    assert(completionHandler != nil);
    assert([NSThread currentThread] == self.clientThread);
    
    //    PBLogDebug(@"will redirect from %@ to %@", [response URL], [newRequest URL]);
    
    // The new request was copied from our old request, so it has our magic property.  We actually
    // have to remove that so that, when the client starts the new request, we see it.  If we
    // don't do this then we never see the new request and thus don't get a chance to change
    // its caching behaviour.
    //
    // We also cancel our current connection because the client is going to start a new request for
    // us anyway.
    
    assert([[self class] propertyForKey:kOurRecursiveRequestFlagProperty inRequest:newRequest] != nil);
    
    redirectRequest = [newRequest mutableCopy];
    [[self class] removePropertyForKey:kOurRecursiveRequestFlagProperty inRequest:redirectRequest];
    
    // Tell the client about the redirect.
    
    [[self client] URLProtocol:self wasRedirectedToRequest:redirectRequest redirectResponse:response];
    
    // Stop our load.  The CFNetwork infrastructure will create a new NSURLProtocol instance to run
    // the load of the redirect.
    
    // The following ends up calling -URLSession:task:didCompleteWithError: with NSURLErrorDomain / NSURLErrorCancelled,
    // which specificallys traps and ignores the error.
    
    [self.task cancel];
    
    [[self client] URLProtocol:self didFailWithError:[NSError errorWithDomain:NSCocoaErrorDomain code:NSUserCancelledError userInfo:nil]];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential *))completionHandler
{
#pragma unused(session)
#pragma unused(task)
    //    assert(task == self.task);
    //    assert(challenge != nil);
    //    assert(completionHandler != nil);
    //    assert([NSThread currentThread] == self.clientThread);
    if (completionHandler) {
        completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
    }
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler
{
    NSURLCacheStoragePolicy cacheStoragePolicy = NSURLCacheStorageNotAllowed;
    
    // cancel request if response is nil or dataTask is incorrect
    if (dataTask != self.task || response == nil) {
        if (response == nil) {
            response = [[NSHTTPURLResponse alloc] initWithURL:dataTask.originalRequest.URL statusCode:500 HTTPVersion:@"1.1" headerFields:nil];
        }
        [[self client] URLProtocol:self didReceiveResponse:response cacheStoragePolicy:cacheStoragePolicy];
        if (completionHandler) {
            completionHandler(NSURLSessionResponseCancel);
        }
    }
    
#pragma unused(session)
#pragma unused(dataTask)
    //    assert(dataTask == self.task);
    //    assert(response != nil);
    //    assert(completionHandler != nil);
    //    assert([NSThread currentThread] == self.clientThread);
    
    
    [[self client] URLProtocol:self didReceiveResponse:response cacheStoragePolicy:cacheStoragePolicy];
    if (completionHandler) {
        completionHandler(NSURLSessionResponseAllow);
    }
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
#pragma unused(session)
#pragma unused(dataTask)
    if (dataTask != self.task || data == nil) {
        [[self client] URLProtocol:self didLoadData:[NSData data]];
        return;
    }
    //    assert(dataTask == self.task);
    //    assert(data != nil);
    //    assert([NSThread currentThread] == self.clientThread);
    
    if (!_receivedData) {
        _receivedData = [NSMutableData data];
    }
    [_receivedData appendData:data];
    [[self client] URLProtocol:self didLoadData:data];
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask willCacheResponse:(NSCachedURLResponse *)proposedResponse completionHandler:(void (^)(NSCachedURLResponse *))completionHandler
{
#pragma unused(session)
#pragma unused(dataTask)
    //    assert(dataTask == self.task);
    //    assert(proposedResponse != nil);
    //    assert(completionHandler != nil);
    //    assert([NSThread currentThread] == self.clientThread);
    completionHandler(proposedResponse);
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
// An NSURLSession delegate callback.  We pass this on to the client.
{
#pragma unused(session)
#pragma unused(task)
    if (self.task != nil && task != self.task) {
        error = [NSError errorWithDomain:DFPAdManagerDomain
                                    code:666
                                userInfo:nil];
    }
    //    assert( (self.task == nil) || (task == self.task) );        // can be nil in the 'cancel from -stopLoading' case
    //    assert([NSThread currentThread] == self.clientThread);
    
    // Just log and then, in most cases, pass the call on to our client.
    
    if (error == nil) {
        
        [[self client] URLProtocolDidFinishLoading:self];
    } else if ( [[error domain] isEqual:NSURLErrorDomain] && ([error code] == NSURLErrorCancelled) ) {
        // Do nothing.  This happens in two cases:
        //
        // o during a redirect, in which case the redirect code has already told the client about
        //   the failure
        //
        // o if the request is cancelled by a call to -stopLoading, in which case the client doesn't
        //   want to know about the failure
    } else {
        [[self client] URLProtocol:self didFailWithError:error];
    }
    
    BOOL isDFPResponse = ([[self class] propertyForKey:kOurDFPFlagRequestProperty inRequest:task.currentRequest]) != nil;
    if (isDFPResponse) {
        if (_receivedData && _receivedData.length > 0) {
            NSString *response = [[NSString alloc] initWithData:_receivedData encoding:NSUTF8StringEncoding];
            NSMutableDictionary *dfpResponseInfo = [[NSMutableDictionary alloc] init];
            if ([task.response isKindOfClass:[NSHTTPURLResponse class]]) {
                NSDictionary *headers = [(NSHTTPURLResponse*)task.response allHeaderFields];
                NSString *size = headers[@"x-afma-ad-size"];
                if (size) {
                    dfpResponseInfo[@"size"] = size;
                }
                // TODO: handle passing of all relevant headers
            }
            
            // track dfp response analytics event
            if (response) {
                dfpResponseInfo[@"source"] = @{ @"source" : response };
                [[self class] trackDFPResponseWithInfo:dfpResponseInfo];
            }
        }
    }
    
    _receivedData = nil;
    // We don't need to clean up the connection here; the system will call, or has already called,
    // -stopLoading to do that.
}

#pragma mark - tracking methods

+ (void)trackBidWon:(PBBidResponse*)bidWon {
    if (bidWon.customKeywords.count == 0) {
        return;
    }
    
    NSDictionary *bidResponseInfo = @{
                                      @"bidderCode" : ObjectOrNull(bidWon.responseInfo[@"seat"]),
                                      @"width" : ObjectOrNull(bidWon.responseInfo[@"w"]),
                                      @"height" : ObjectOrNull(bidWon.responseInfo[@"h"]),
                                      @"statusMessage" : @"",
                                      @"adId" : ObjectOrNull(bidWon.responseInfo[@"adid"]),
                                      @"cpm" : ObjectOrNull(bidWon.responseInfo[@"price"]),
                                      @"creativeId" : ObjectOrNull(bidWon.responseInfo[@"crid"]),
                                      @"adUrl" : ObjectOrNull(bidWon.responseInfo[@"iurl"]),
                                      @"requestId" : ObjectOrNull(bidWon.responseInfo[@"id"]),
                                      @"responseTimestamp" : @([[NSDate date] timeIntervalSince1970]),
                                      @"requestTimestamp" : @([[NSDate date] timeIntervalSince1970]),
                                      @"bidder" : ObjectOrNull(bidWon.responseInfo[@"seat"]),
                                      @"adUnitCode" : ObjectOrNull(bidWon.adUnitId),
                                      @"timeToRespond" : @(60),
                                      @"pbHg" : ObjectOrNull(bidWon.customKeywords[@"hb_pb"])
                                      };
    
    NSArray *keysForNullValues = [bidResponseInfo allKeysForObject:[NSNull null]];
    NSMutableDictionary *prunedAnalyticsInfo = [bidResponseInfo mutableCopy];
    // remove NSNulls
    [prunedAnalyticsInfo removeObjectsForKeys:keysForNullValues];
    NSDictionary *eventInfo = @{ @"bidResponse" : prunedAnalyticsInfo };
    PBAnalyticsEvent *event = [[PBAnalyticsEvent alloc] initWithEventType:PBAnalyticsEventBidWon];
    event.info = eventInfo;
    [[PBAnalyticsManager sharedInstance] trackEvent:event];
}

+ (void)trackDFPResponseWithInfo:(NSDictionary*)dfpResponseInfo {
    if (dfpResponseInfo.count == 0) {
        return;
    }
    
    NSDictionary *eventInfo = @{ @"dfpResponse" : dfpResponseInfo };
    PBAnalyticsEvent *event = [[PBAnalyticsEvent alloc] initWithEventType:PBAnalyticsEventDFPResponse];
    event.info = eventInfo;
    [[PBAnalyticsManager sharedInstance] trackEvent:event];
}

@end
