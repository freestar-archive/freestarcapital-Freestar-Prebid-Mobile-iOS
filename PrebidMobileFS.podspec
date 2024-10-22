Pod::Spec.new do |s|

  s.name         = "PrebidMobileFS"
  s.version      = "#{version}#"
  s.summary      = "PrebidMobile is a lightweight framework that integrates directly with Prebid Server."
  s.description  = <<-DESC
    Prebid-Mobile-SDK is a lightweight framework that integrates directly with Prebid Server to increase yield for publishers by adding more mobile buyers."
    DESC
  s.homepage     = "https://www.prebid.org"


  s.license      = { :type => "Apache License, Version 2.0", :text => <<-LICENSE
    Copyright 2017 Prebid.org, Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
    LICENSE
    }

  s.author       = { "Prebid.org, Inc." => "info@prebid.org" }
  s.platform     = :ios, "8.0"
  s.source       = { :http => 'https://storage.googleapis.com/freestar-sdk/PrebidMobileFS/Freestar-Prebid-Mobile-iOS-#{version}#.tar.gz' } 
  s.source_files = 'sdk/PrebidMobileFS.framework/Headers/*.{h}'
  s.vendored_frameworks = 'sdk/PrebidMobileFS.framework'
  s.preserve_paths =  'sdk/PrebidMobileFS.framework/*'
  s.dependency  "FSCache"
  s.framework  = ['CoreTelephony', 'SystemConfiguration', 'UIKit', 'Foundation']
  s.requires_arc = true
  s.xcconfig = {
    :LIBRARY_SEARCH_PATHS => '$(inherited)',
    :OTHER_CFLAGS => '$(inherited)',
    :OTHER_LDFLAGS => '$(inherited)',
    :HEADER_SEARCH_PATHS => '$(inherited)',
    :FRAMEWORK_SEARCH_PATHS => '$(inherited)'
  }

end
