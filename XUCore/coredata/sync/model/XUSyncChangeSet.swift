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
public final class XUSyncChangeSet: Codable {
	
	private enum CodingKeys: String, CodingKey {
		case changes
		case numberOfChanges
		case timestamp
	}
	
	/// A set of changes within this change set.
	public let changes: [XUSyncChange]
	
	/// Timestamp of the sync change set.
	public let timestamp: TimeInterval


	/// Desginated initializer.
	public init(changes: [XUSyncChange]) {
		self.changes = changes
		self.timestamp = Date.timeIntervalSinceReferenceDate
	}
	
	
	public func encode(to encoder: Encoder) throws {
		let values = encoder.container(keyedBy: CodingKeys.self)
		
		values.encode(self.changes, forKey: .changes)
		values.encode(self.timestamp, forKey: .timestamp)
	}
	
	public init(from decoder: Decoder) throws {
		let values = try decoder.container(keyedBy: CodingKeys.self)
		self.timestamp = try values.decode(TimeInterval.self, forKey: .timestamp)
		self.changes = try values.decode([XUSyncChange].self, forKey: .changes)
	}

}
