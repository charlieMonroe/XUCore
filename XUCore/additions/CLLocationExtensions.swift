//
//  CLLocationExtensions.swift
//  XUCore
//
//  Created by Charlie Monroe on 5/11/17.
//  Copyright © 2017 Charlie Monroe Software. All rights reserved.
//

import Foundation
import MapKit

extension CLLocationCoordinate2D: Equatable {
	
	public static func ==(lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
		return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
	}
	
	
	/// Returns distance to the other coordinate. Works by using map points.
	public func distance(to other: CLLocationCoordinate2D) -> CLLocationDistance {
		let mp1 = MKMapPointForCoordinate(self)
		let mp2 = MKMapPointForCoordinate(other)
		return MKMetersBetweenMapPoints(mp1, mp2)
	}
	
}
