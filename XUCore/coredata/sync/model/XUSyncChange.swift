//
//  XUSyncChange.swift
//  XUCore
//
//  Created by Charlie Monroe on 5/21/16.
//  Copyright © 2016 Charlie Monroe Software. All rights reserved.
//

import Foundation
import CoreData

/// This is a base class for all sync changes. Unlike TICDS, we use subclassing
/// instead of attributes to distinguish between sync changes.
///
/// Unfortunately, the initial idea was that it would be required for
/// XUManagedObject to be an actual entity, but this kind of went downhill due
/// to maintaining backward compatibility with TICDS...
@objc(XUSyncChange)
public class XUSyncChange: NSManagedObject {
	
	/// Change set this change belongs to. Nil during initialization, hence nullable,
	/// but otherwise should be nonnull.
	@NSManaged public private(set) var changeSet: XUSyncChangeSet!
	
	/// Name of the entity.
	@NSManaged public private(set) var objectEntityName: String
	
	/// This is generally all we need to identify the object.
	@NSManaged public private(set) var objectSyncID: String
	
	/// Object that is being sync'ed. Only stored locally.
	public private(set) weak var syncObject: XUManagedObject!
	
	/// Timestamp of the change.
	@NSManaged public private(set) var timestamp: TimeInterval
	
	/// Creates a new sync change.
	public init(object: XUManagedObject) {
		let ctx = object.managedObjectContext!.documentSyncManager!.syncManagedObjectContext
		super.init(entity: NSEntityDescription.entity(forEntityName: NSStringFromClass(type(of: self)), in:ctx)!, insertInto: ctx)
		
		self.syncObject = object
		
		self.objectEntityName = object.entity.name!
		self.objectSyncID = object.syncUUID
		self.timestamp = Date.timeIntervalSinceReferenceDate
	}

	internal override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
		super.init(entity: entity, insertInto: context)
	}

}
