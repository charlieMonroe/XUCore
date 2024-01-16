//
//  XUPreferences+Sync.swift
//  XUCore
//
//  Created by Charlie Monroe on 3/9/18.
//  Copyright © 2018 Charlie Monroe Software. All rights reserved.
//

import Foundation

internal extension XUPreferences {
	
	/// Returns synchronization changes pending upload.
	func pendingSynchronizationChanges(for documentID: String) -> [(data: Data, changeSet: XUSyncChangeSet)] {
		let dataArray: [Data] = self.value(for: XUPreferences.Key(rawValue: "XUPendingSynchronizationChanges_" + documentID), defaultValue: [])
		return dataArray.compactMap {
			do {
				guard let changeSet = try NSKeyedUnarchiver.unarchivedObject(ofClass: XUSyncChangeSet.self, from: $0) else {
					XULog("Failed to unarchive change set with no particular error...")
					return nil
				}
				return ($0, changeSet)
			} catch {
				XULog("Failed to unarchive change set: \(error)")
				return nil
			}
		}
	}
	
	func setPendingSynchronizationChanges(_ changes: [Data], for documentID: String) {
		self.set(value: changes, forKey: XUPreferences.Key(rawValue: "XUPendingSynchronizationChanges_" + documentID))
	}
	
	
	/// Timestamp of the imported document from iCloud. This is used as base
	/// and we do not accept sync chages below this date. Will return nil if, e.g.
	/// the document originated on this computer.
	func timestampOfImport(for documentID: String) -> TimeInterval? {
		return self.value(for: XUPreferences.Key(rawValue: "XUImportTimeStamp_" + documentID))
	}
	
	func setTimestampOfImport(_ timestamp: TimeInterval, for documentID: String) {
		self.set(value: timestamp, forKey: XUPreferences.Key(rawValue: "XUImportTimeStamp_" + documentID))
	}
	
	
	/// Timestamp of the last synchronization change set seen from this computer.
	func timestampOfLastSynchronization(with computerID: String, ofDocumentWithIdentifier accountIdentifier: String) -> TimeInterval? {
		return self.value(for: XUPreferences.Key(rawValue: "XUTimestampOfLastSynchronization_\(accountIdentifier)_\(computerID)"))
	}
	
	func setTimestampOfLastSynchronization(_ timestamp: TimeInterval, with computerID: String, ofDocumentWithIdentifier accountIdentifier: String) {
		self.set(value: timestamp, forKey: XUPreferences.Key(rawValue: "XUTimestampOfLastSynchronization_\(accountIdentifier)_\(computerID)"))
	}
	
	
	/// Returns the last timestamp of a changeset generated on this computer for
	/// this document ID.
	func lastSynchronizationChangeTimestamp(for documentID: String) -> TimeInterval? {
		return self.value(for: XUPreferences.Key(rawValue: "XULastSynchronizationChangeTimestamp" + documentID))
	}
	
	func setLastSynchronizationChangeTimestamp(_ timestamp: TimeInterval, for documentID: String) {
		self.set(value: timestamp, forKey: XUPreferences.Key(rawValue: "XULastSynchronizationChangeTimestamp" + documentID))
	}
	
}
