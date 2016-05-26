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
public class XUSyncChangeSet: NSManagedObject {

	/// Fetches all change sets in the supplied MOC.
	public class func allChangeSetsInManagedObjectContext(ctx: NSManagedObjectContext, withTimestampNewerThan timestamp: NSTimeInterval) -> [XUSyncChangeSet] {
		let request = NSFetchRequest(entityName: NSStringFromClass(self))
		let allValues = (try? ctx.executeFetchRequest(request)) ?? []
		let allChangeSets = (allValues as? [XUSyncChangeSet]) ?? []
		return allChangeSets.filter({ $0.timestamp > timestamp })
	}
	
	/// Returns the newest change set in MOC, if one exists.
	public class func newestChangeSetInManagedObjectContext(ctx: NSManagedObjectContext) -> XUSyncChangeSet? {
		let request = NSFetchRequest(entityName: NSStringFromClass(self))
		request.sortDescriptors = [ NSSortDescriptor(key: "timestamp", ascending: false) ]
		request.fetchLimit = 1
		
		let allValues = (try? ctx.executeFetchRequest(request))
		return allValues?.first as? XUSyncChangeSet
	}

	
	/// A set of changes within this change set.
	@NSManaged public private(set) var changes: Set<XUSyncChange>
	
	/// Timestamp of the sync change set.
	@NSManaged public private(set) var timestamp: NSTimeInterval


	/// Desginated initializer.
	public init(managedObjectContext ctx: NSManagedObjectContext, andChanges changes: [XUSyncChange]) {
		let entity = NSEntityDescription.entityForName("XUSyncChangeSet", inManagedObjectContext: ctx)!
		super.init(entity: entity, insertIntoManagedObjectContext: ctx)
		
		self.timestamp = NSDate.timeIntervalSinceReferenceDate()
		
		self.changes = Set(changes)
	}
	
	internal override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
		super.init(entity: entity, insertIntoManagedObjectContext: context)
	}

}
