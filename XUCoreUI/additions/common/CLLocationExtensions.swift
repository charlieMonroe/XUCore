//
//  CLLocationExtensions.swift
//  XUCore
//
//  Created by Charlie Monroe on 5/11/17.
//  Copyright © 2017 Charlie Monroe Software. All rights reserved.
//

import Foundation
import CoreLocation

extension CLLocationCoordinate2D: @retroactive Equatable {
	
	public static func ==(lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
		return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
	}
	
	
	/// Returns distance to the other coordinate. Works by using map points.
	public func distance(to other: CLLocationCoordinate2D) -> CLLocationDistance {
		let point1 = CLLocation(latitude: self.latitude, longitude: self.longitude)
		let point2 = CLLocation(latitude: other.latitude, longitude: other.longitude)
		return point1.distance(from: point2)
	}
	
}
