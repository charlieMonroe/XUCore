Pod::Spec.new do |s|
	s.name     = 'XUCoreUI'
	s.version  = '1.0.4'
	s.license  = 'MIT License'
	s.summary  = 'A core library used by Charlie Monroe Software.'
	s.homepage = 'http://github.com/charlieMonroe/XUCore/'
	s.author   = 'Charlie Monroe'
	s.source   = { :git => 'https://github.com/charlieMonroe/XUCore.git', :tag => 'ui_1.0.4' }
	
	s.swift_version = '5'

	s.source_files = 'XUCoreUI/additions/common/*.swift', 'XUCoreUI/app_store/common/*.swift', 'XUCoreUI/network/common/*.swift', 'XUCoreUI/network/common/oauth2/*.swift', 'XUCoreUI/ui/common/*.swift', 'XUCoreUI/ui/common/views/*.swift'
	s.ios.source_files = 'XUCoreUI iOS/XUCoreUI.h', 'XUCoreUI iOS/additions/*.swift', 'XUCoreUI iOS/core/*.swift', 'XUCoreUI iOS/debug/*.swift', 'XUCoreUI iOS/localization/*.swift', 'XUCoreUI iOS/network/oauth2/*.swift', 'XUCoreUI iOS/ui/*/*.swift'
	s.osx.source_files = 'XUCoreUI/XUCoreUI.h', 'XUCoreUI/additions/*.swift', 'XUCoreUI/app_store/*.swift', 'XUCoreUI/core/*.{swift,m}', 'XUCoreUI/debug/*.swift', 'XUCoreUI/exception_handling/*.swift', 'XUCoreUI/localization/*.swift', 'XUCoreUI/network/*.swift', 'XUCoreUI/network/oauth2/*.swift', 'XUCoreUI/ui/*/*.swift'
	
	s.dependency 'XUCore'
	
	s.resources = ''
	s.ios.resources = 'XUCoreUI iOS/ui/*/*.xib'
	s.osx.resources = 'XUCoreUI/exception_handling/*.xib', 'XUCoreUI/network/oauth2/*.xib', 'XUCoreUI/ui/*/*.xib', 'XUCoreUI/Media.xcassets'

	s.frameworks = 'Foundation', 'CoreData'
	
	s.ios.deployment_target = '10.0'
	s.osx.deployment_target = '10.11'
	
	s.requires_arc = true
	
end