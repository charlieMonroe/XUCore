//
//  MKPolygonAdditions.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/30/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation
import MapKit

public extension MKPolygon {
	
	fileprivate class func _parseCoordinates(fromString string: String) -> [CLLocation] {
		let polygonStrings = string.components(separatedBy: "),(")
		let exteriorRingString = polygonStrings.first!
		
		let coordinatesRegex = XURegex(pattern: "([-\\d\\.]+\\s[-\\d\\.]+)", andOptions: .caseless)
		let matches = exteriorRingString.allOccurrencesOfRegex(coordinatesRegex)
		return matches.map({ (match) -> CLLocation in
			return self._parseCoordinate(fromString: match)
		})
	}
	
	fileprivate class func _parseCoordinate(fromString coordinateString: String) -> CLLocation {
		let points = coordinateString.components(separatedBy: " ")
		let lon = points.first!
		let lat = points.last!
		return CLLocation(latitude: lat.doubleValue, longitude: lon.doubleValue)
	}
	
	/// Parses the string as WKT and returns an MKPolygon.
	/// If the string is a point, a single-point polygon is returned.
	/// Nil is returned if no points are found.
	public convenience init?(wktString string: String!) {
		if string == nil {
			return nil
		}
		
		/** We currently only support points and polygons. */
		let coordinates = MKPolygon._parseCoordinates(fromString: string)
		if coordinates.count == 0 {
			return nil
		}
		
		var coords: [CLLocationCoordinate2D] = [ ]
		for coordObj in coordinates {
			coords.append(coordObj.coordinate)
		}
		
		self.init(coordinates: &coords, count: coordinates.count)
	}
	
	/// Returns the center of the polygon by approximation. Puts the polygon
	/// into a rectangle and returns the center of the rectangle.
	public var centerCoordinate: CLLocationCoordinate2D {
		let points = self.points()
		let pointCount = self.pointCount
		if pointCount == 1 {
			// It's a single point, that's the center
			return MKCoordinateForMapPoint(points[0])
		}
		
		/** Find minX, minY, maxX, maxY */
		var minX = DBL_MAX
		var minY = DBL_MAX
		var maxX = 0.0
		var maxY = 0.0
		
		for i in 0..<pointCount {
			let point = points[i]
			minX = min(minX, point.x)
			minY = min(minY, point.y)
			maxX = max(maxX, point.x)
			maxY = max(maxY, point.y)
		}
		
		/** Now find the center. */
		let centerPoint = MKMapPoint(x: minX + (maxX - minX) / 2.0, y: minY + (maxY - minY) / 2.0)
		return MKCoordinateForMapPoint(centerPoint)
	}
	
	/// Returns the center of the polygon by approximation. Puts the polygon
	/// into a rectangle and returns the center of the rectangle.
	public var centerLocation: CLLocation {
		let coordinate = self.centerCoordinate
		return CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
	}
	
}


