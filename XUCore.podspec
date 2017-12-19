Pod::Spec.new do |s|
	s.name     = 'XUCore'
	s.version  = '1.0'
	s.platform = :ios
	s.license  = 'MIT License'
	s.summary  = 'A core library used by Charlie Monroe Software.'
	s.homepage = 'http://github.com/charlieMonroe/XUCore/'
	s.author   = 'Charlie Monroe'
	s.source   = { :git => 'http://github.com/charlieMonroe/XUCore/XUCore.git', :branch => 'swift4' }
	s.source_files = 'Categories', 'Classes', 'Helper'
	s.frameworks = 'UIKit', 'CoreLocation', 'MapKit'
	s.platform = :ios, '10.0'
	s.requires_arc = true
end