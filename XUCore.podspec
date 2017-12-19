Pod::Spec.new do |s|
	s.name     = 'XUCore'
	s.version  = '1.0'
	s.license  = 'MIT License'
	s.summary  = 'A core library used by Charlie Monroe Software.'
	s.homepage = 'http://github.com/charlieMonroe/XUCore/'
	s.author   = 'Charlie Monroe'
	s.source   = { :git => 'http://github.com/charlieMonroe/XUCore/XUCore.git', :branch => 'swift4' }

	s.source_files = 'XUCore/additions/*.{h,m,swift}', 'XUCore/core/*.{h,m,swift}', 'XUCore/coredata/*.swift', 'XUCore/coredata/sync/*.swift', 'XUCore/coredata/sync/model/*.swift', 'XUCore/debug/*.swift', 'XUCore/deserialization/*.swift', 'XUCore/documents/*.swift', 'XUCore/localization/*.swift'
	s.ios.source_files = 'XUCore/additions/iOS/*.swift', 'XUCore/core/iOS/*.swift', 'XUCore/localization/iOS/*.swift', 'XUCore/misc/*.swift'
	s.osx.source_files = 'XUCore/additions/macOS/*.swift', 'XUCore/app_store/*.swift', 'XUCore/core/macOS/*.swift', 'XUCore/exception_handling/*.swift', 'XUCore/localization/macOS/*.swift', 'XUCore/misc/macOS/*.swift'
	
	s.resources = 'XUCore/coredata/sync/model/*.{xcdatamodeld,xcdatamodel}', 'XUCore/exception_handling/*.xib'

	s.frameworks = 'CoreLocation', 'CoreData'
	s.ios.frameworks = 'UIKit', 'MapKit'
	s.osx.frameworks = 'AppKit'
	
	s.platform = :ios, '10.0'
	s.requires_arc = true
end