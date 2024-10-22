Pod::Spec.new do |s|
	s.name     = 'XUCore'
	s.version  = '1.4.2'
	s.license  = 'MIT License'
	s.summary  = 'A core library used by Charlie Monroe Software.'
	s.homepage = 'http://github.com/charlieMonroe/XUCore/'
	s.author   = 'Charlie Monroe'
	s.source   = { :git => 'https://github.com/charlieMonroe/XUCore.git', :tag => 'core_1.4.2' }
	
	s.swift_version = '5'

	s.source_files = 'XUCore/additions/*.{h,m,swift}', 'XUCore/core/*.{h,m,swift}', 'XUCore/coredata/*.swift', 'XUCore/coredata/sync/*.{h,m,swift}', 'XUCore/coredata/sync/model/*.swift', 'XUCore/debug/*.swift', 'XUCore/deserialization/*.swift', 'XUCore/documents/*.swift', 'XUCore/localization/*.swift', 'XUCore/localization/*.lproj/*.strings', 'XUCore/misc/*.swift', 'XUCore/network/*.swift', 'XUCore/private/*.{h,m,swift}', 'XUCore/regex/*.{h,m,mm,swift}', 'XUCore/regex/re2/*.{h,cc}', 'XUCore/regex/re2/util/*.{h,cc}', 'XUCore/transformers/*.swift'
	s.ios.source_files = 'XUCoreMobile/XUCore.h', 'XUCore/core/iOS/*.swift', 'XUCore/localization/iOS/*.swift'
	s.osx.source_files = 'XUCore/XUCore.h', 'XUCore/additions/macOS/*.{h,m,swift}', 'XUCore/core/macOS/*.swift'
	
	s.resources = 'XUCore/coredata/sync/model/*.{xcdatamodeld,xcdatamodel}'
		
	s.xcconfig = { 'GCC_WARN_INHIBIT_ALL_WARNINGS' => 'YES' }

	s.private_header_files = 'XUCore/regex/re2/*.h', 'XUCore/regex/re2/util/*.h'

	s.frameworks = 'Foundation', 'CoreData'
	
	s.ios.deployment_target = '12.0'
	s.osx.deployment_target = '10.12'
	
	s.requires_arc = true
	
end
