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

/*! Returns a canonical form of the supplied request.
 *  \details The Foundation URL loading system needs to be able to canonicalize URL
 *  requests for various reasons (for example, to look for cache hits).  The default
 *  HTTP/HTTPS protocol has a complex chunk of code to perform this function.  Unfortunately
 *  there's no way for third party code to access this.  Instead, we have to reimplement
 *  it all ourselves.  This is split off into a separate file to emphasise that this
 *  is standard boilerplate that you probably don't need to look at.
 *
 *  IMPORTANT: While you can take most of this code as read, you might want to tweak
 *  the handling of the "Accept-Language" in the CanonicaliseHeaders routine.
 *  \param request The request to canonicalise; must not be nil.
 *  \returns The canonical request; should never be nil.
 */

#import <Foundation/Foundation.h>

extern NSMutableURLRequest *CanonicalRequestForRequest(NSURLRequest *request);
