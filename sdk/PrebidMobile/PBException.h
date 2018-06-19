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

#import <Foundation/Foundation.h>

@interface PBException : NSException

/**
 * implement price check exception handling. Currently price check will throw exception if the user fails to provide the size
 * or demand source in the adunits. Additionally of the user has already registered the adunit & trying to register again 
 * then an exception is raised.
 */

typedef enum PBRaiseException {
    PBAdUnitNoSizeException,
    PBAdUnitNoDemandConfigException,
    PBAdUnitAlreadyRegisteredException,
    PBAdUnitNotRegisteredException,
    PBHostInvalidException,
    PBFreestarMissingFrameworkException
} PBRaiseException;

+ (NSException *)exceptionWithName:(enum PBRaiseException)exceptionName;

@end
