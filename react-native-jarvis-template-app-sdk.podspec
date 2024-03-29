require "json"

package = JSON.parse(File.read(File.join(__dir__, "package.json")))
# folly_compiler_flags = '-DFOLLY_NO_CONFIG -DFOLLY_MOBILE=1 -DFOLLY_USE_LIBCPP=1 -Wno-comma -Wno-shorten-64-to-32'

# reactVersion = JSON.parse(File.read(File.join(__dir__, "..", "react-native", "package.json")))["version"]
folly_version = '2021.04.26.00'
boost_compiler_flags = '-Wno-documentation'

# rnVersion = reactVersion.split('.')[1]

folly_prefix = ""
# if rnVersion.to_i >= 64
#   folly_prefix = "RCT-"
# end
folly_prefix = "RCT-"

# folly_flags = '-DFOLLY_NO_CONFIG -DFOLLY_MOBILE=1 -DFOLLY_USE_LIBCPP=1 -DRNVERSION=' + rnVersion
folly_flags = '-DFOLLY_NO_CONFIG -DFOLLY_MOBILE=1 -DFOLLY_USE_LIBCPP=1'
 
folly_compiler_flags = folly_flags + ' ' + '-Wno-comma -Wno-shorten-64-to-32'


Pod::Spec.new do |s|
  s.name         = "react-native-jarvis-template-app-sdk"
  s.version      = package["version"]
  s.summary      = package["description"]
  s.homepage     = package["homepage"]
  s.license      = package["license"]
  s.authors      = package["author"]

  s.platforms    = { :ios => "10.0" }
  s.source       = { :git => "https://github.com/Viatick-co/react-native-jarvis-template-app-sdk.git", :tag => "#{s.version}" }

  s.source_files = "ios/**/*.{h,m,mm,swift}"

  # s.compiler_flags = folly_compiler_flags + " -DRCT_NEW_ARCH_ENABLED=1"
  # s.pod_target_xcconfig    = {
  #     "HEADER_SEARCH_PATHS" => "\"$(PODS_ROOT)/boost\"",
  #     "CLANG_CXX_LANGUAGE_STANDARD" => "c++17"
  # }


  s.pod_target_xcconfig    = {
    "USE_HEADERMAP" => "YES",
    "HEADER_SEARCH_PATHS" => "\"$(PODS_TARGET_SRCROOT)/ReactCommon\" \"$(PODS_TARGET_SRCROOT)\" \"$(PODS_ROOT)/#{folly_prefix}Folly\" \"$(PODS_ROOT)/boost\" \"$(PODS_ROOT)/boost-for-react-native\" \"$(PODS_ROOT)/DoubleConversion\" \"$(PODS_ROOT)/Headers/Private/React-Core\" "
  }
  s.compiler_flags = folly_compiler_flags + ' ' + boost_compiler_flags
  s.xcconfig               = {
    "CLANG_CXX_LANGUAGE_STANDARD" => "c++14",
    "HEADER_SEARCH_PATHS" => "\"$(PODS_ROOT)/boost\" \"$(PODS_ROOT)/boost-for-react-native\" \"$(PODS_ROOT)/glog\" \"$(PODS_ROOT)/#{folly_prefix}Folly\" \"${PODS_ROOT}/Headers/Public/React-hermes\" \"${PODS_ROOT}/Headers/Public/hermes-engine\"",
                               "OTHER_CFLAGS" => "$(inherited)" + " " + folly_flags  }
  
  s.requires_arc = true


  # s.dependency "React-Core"
  # s.dependency "linphone-sdk"

  # s.dependency "React-Codegen"
  # s.dependency "RCT-Folly"
  # s.dependency "RCTRequired"
  # s.dependency "RCTTypeSafety"
  # s.dependency "ReactCommon/turbomodule/core"
  # s.dependency 'React-callinvoker'
  # s.dependency "#{folly_prefix}Folly"

  s.dependency "linphone-sdk"

  s.dependency "React"
  s.dependency 'FBLazyVector'
  s.dependency 'FBReactNativeSpec'
  s.dependency 'RCTRequired'
  s.dependency 'RCTTypeSafety'
  s.dependency 'React-Core'
  s.dependency 'React-CoreModules'
  s.dependency 'React-Core/DevSupport'
  s.dependency 'React-RCTActionSheet'
  s.dependency 'React-RCTNetwork'
  s.dependency 'React-RCTAnimation'
  s.dependency 'React-RCTLinking'
  s.dependency 'React-RCTBlob'
  s.dependency 'React-RCTSettings'
  s.dependency 'React-RCTText'
  s.dependency 'React-RCTImage'
  s.dependency 'React-Core/RCTWebSocket'
  s.dependency 'React-cxxreact'
  s.dependency 'React-jsi'
  s.dependency 'React-jsiexecutor'
  s.dependency 'React-jsinspector'
  s.dependency 'ReactCommon/turbomodule/core'
  s.dependency 'Yoga'
  s.dependency 'React-callinvoker'

  s.dependency "#{folly_prefix}Folly"


  # Don't install the dependencies when we run `pod install` in the old architecture.
  # if ENV['RCT_NEW_ARCH_ENABLED'] == '1' then
  #   s.compiler_flags = folly_compiler_flags + " -DRCT_NEW_ARCH_ENABLED=1"
  #   s.pod_target_xcconfig    = {
  #       "HEADER_SEARCH_PATHS" => "\"$(PODS_ROOT)/boost\"",
  #       "CLANG_CXX_LANGUAGE_STANDARD" => "c++17"
  #   }
    
  #   s.dependency "React-Codegen"
  #   s.dependency "RCT-Folly"
  #   s.dependency "RCTRequired"
  #   s.dependency "RCTTypeSafety"
  #   s.dependency "ReactCommon/turbomodule/core"
  # end
end
