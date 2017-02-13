//
//  XUJSONDeserializationLog.swift
//  XUCore
//
//  Created by Charlie Monroe on 2/13/17.
//  Copyright © 2017 Charlie Monroe Software. All rights reserved.
//

import Foundation

extension XUJSONDeserializer {
	
	public struct LogEntry: CustomDebugStringConvertible {
		
		/// Severity of the issue. May be only .Warning or .Error
		public let severity: DeserializationError
		
		/// Object that was being deserialized.
		public let objectClass: AnyClass
		
		/// Key, for which the issue occurred.
		public let key: String
		
		/// Additional information about the issue.
		public let additionalInformation: String
		
		public var debugDescription: String {
			return "\(self.severity): \(objectClass).\(key): \(additionalInformation)"
		}
		
		public init(severity: DeserializationError, objectClass: AnyClass, key: String, additionalInformation: String = "") {
			self.severity = severity
			self.objectClass = objectClass
			self.key = key
			self.additionalInformation = additionalInformation
		}
	}
	
}
