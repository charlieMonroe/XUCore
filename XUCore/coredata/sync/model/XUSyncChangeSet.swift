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
@objc(XUSyncChangeSet)
public final class XUSyncChangeSet: NSManagedObject {
	
	/// Fetches all change sets in the supplied MOC.
	public class func allChangeSets(inContext ctx: NSManagedObjectContext, withTimestampNewerThan timestamp: TimeInterval) -> [XUSyncChangeSet] {
		let request = NSFetchRequest<XUSyncChangeSet>(entityName: NSStringFromClass(self))
		let allValues = (try? ctx.fetch(request)) ?? []
		let allChangeSets = allValues
		return allChangeSets.filter({ $0.timestamp > timestamp })
	}
	
	/// Returns the newest change set in MOC, if one exists.
	public class func newestChangeSet(inContext ctx: NSManagedObjectContext) throws -> XUSyncChangeSet? {
		let request = NSFetchRequest<XUSyncChangeSet>(entityName: NSStringFromClass(self))
		request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
		request.fetchLimit = 1
		
		let allValues = try ctx.fetch(request)
		return allValues.first
	}

	
	/// A set of changes within this change set.
	@NSManaged public private(set) var changes: Set<XUSyncChange>
	
	/// Timestamp of the sync change set.
	@NSManaged public private(set) var timestamp: TimeInterval


	/// Desginated initializer.
	public init(managedObjectContext ctx: NSManagedObjectContext, andChanges changes: [XUSyncChange]) {
		let entity = NSEntityDescription.entity(forEntityName: "XUSyncChangeSet", in: ctx)!
		super.init(entity: entity, insertInto: ctx)
		
		self.timestamp = Date.timeIntervalSinceReferenceDate
		
		self.changes = Set(changes)
	}
	
	internal override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
		super.init(entity: entity, insertInto: context)
	}

}
