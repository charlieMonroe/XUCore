//
//  MKGeometryAdditions.swift
//  XUCore
//
//  Created by Charlie Monroe on 5/11/16.
//  Copyright © 2016 Charlie Monroe Software. All rights reserved.
//

import Foundation
import MapKit

extension MKCoordinateRegion {
	
	/// Returns true is the region contains this location.
	public func containsLocation(_ location: CLLocationCoordinate2D) -> Bool {
		let minLatitude = self.center.latitude - self.span.latitudeDelta
		let maxLatitude = self.center.latitude + self.span.latitudeDelta
		
		let minLongitude = self.center.longitude - self.span.longitudeDelta
		let maxLongitude = self.center.longitude + self.span.longitudeDelta
		
		return (location.latitude >= minLatitude && location.latitude <= maxLatitude)
			&& (location.longitude >= minLongitude && location.longitude <= maxLongitude)
	}
	
	/// Convenience wrapper for CLLocation.
	public func containsLocation(_ location: CLLocation) -> Bool {
		return self.containsLocation(location.coordinate)
	}
	
}
