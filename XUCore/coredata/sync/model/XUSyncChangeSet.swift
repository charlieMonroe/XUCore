//
//  XUSyncChangeSet.swift
//  XUCore
//
//  Created by Charlie Monroe on 5/22/16.
//  Copyright © 2016 Charlie Monroe Software. All rights reserved.
//

import Foundation
import CoreData

/// To make the syncing more efficient, we group XUSyncChanges in to change sets.
/// This allows XUSyncEngine to go just through a few change sets, instead of
/// potentially hundreds or even thousands of actual changes.
public final class XUSyncChangeSet: NSObject, NSCoding {
	
	private struct CodingKeys {
		static let changes: String = "Changes"
		static let timestamp: String = "Timestamp"
	}
	
	/// A set of changes within this change set.
	public let changes: [XUSyncChange]
	
	/// Timestamp of the sync change set.
	public let timestamp: TimeInterval


	/// Desginated initializer.
	public init(changes: [XUSyncChange]) {
		self.changes = changes
		self.timestamp = Date.timeIntervalSinceReferenceDate
		
		super.init()
	}
	
	
	public func encode(with coder: NSCoder) {
		coder.encode(self.changes, forKey: CodingKeys.changes)
		coder.encode(self.timestamp, forKey: CodingKeys.timestamp)
	}
	
	public init?(coder decoder: NSCoder) {
		let timestamp = decoder.decodeDouble(forKey: CodingKeys.timestamp)
		
		guard let changes = decoder.decodeObject(forKey: CodingKeys.changes) as? [XUSyncChange], timestamp != 0.0 else {
			XULog("Failing to decode XUSyncChangeSet as it's missing some value from coder: \(decoder)")
			return nil
		}
		
		self.changes = changes
		self.timestamp = timestamp
		
		super.init()
	}

}
