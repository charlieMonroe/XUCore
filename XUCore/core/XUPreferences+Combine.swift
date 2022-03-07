//
//  XUPreferences+Combine.swift
//  XUCore
//
//  Created by Charlie Monroe on 1/24/22.
//  Copyright © 2022 Charlie Monroe Software. All rights reserved.
//

import Foundation
import Combine

extension XUPreferences {
	
	/// An additional wrapper layer.
	internal final class ChangeObservationWrapper {
		
		private var _observation: AnyObject?
		
		@available(macOS 10.15, *)
		@available(iOS 13.0, *)
		func observation(for preferences: XUPreferences) -> ChangeObservation {
			if let observation = _observation as? ChangeObservation {
				return observation
			}
			
			let observation = ChangeObservation(preferences: preferences)
			_observation = observation
			return observation
		}
		
	}
	
	@available(macOS 10.15, *)
	@available(iOS 13.0, *)
	public final class ChangeObservation: ObservableObject {
		
		/// You can observe changes to XUPreferences via this subject. The value passed is the key that changed.
		public let objectWillChange: PassthroughSubject<XUPreferences.Key, Never> = PassthroughSubject()
		
		/// Prefences to observe.
		public var preferences: XUPreferences
		
		fileprivate init(preferences: XUPreferences) {
			self.preferences = preferences
		}
		
	}
	
	/// ObservableObject for changes to the preferences. Subscribe to the objectWillChange subject.
	///  Here is how to use it:
	///
	/// ```
	/// @StateObject
	/// var preferencesObservation = XUPreferences.shared.changeObservation
	///
	/// [...]
	///
	/// Picker(selection: $preferencesObservation.preferences.mySetting) [...]
	/// ```
	@available(macOS 10.15, *)
	@available(iOS 13.0, *)
	public var changeObservation: ChangeObservation {
		return self._changeObservationObjectWrapper.observation(for: self)
	}
	
}
