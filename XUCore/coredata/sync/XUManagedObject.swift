//
//  XUManagedObject.swift
//  XUCore
//
//  Created by Charlie Monroe on 5/21/16.
//  Copyright © 2016 Charlie Monroe Software. All rights reserved.
//

import Foundation
import CoreData

/// These two static variables allow the mechanism described behind 
/// awakeFromNonSyncInsert()
private let _initializationLock: NSLock = NSLock(name: "com.charliemonroe.XUManagedObject.InitializationLock")
private var _currentInitInitiatedInSync: Bool = false


/// Theoretically, we could be adding insertion/deletion changes more than once,
/// since there is no way of knowing when the -createSyncChange method is called.
///
/// We will hence keep a local list of UUIDs for which we've created insertion/
/// deletion changes.
///
/// Note that set is used instead of Array to prevent duplicates.
private let _changesLock: NSLock = NSLock(name: "com.charliemonroe.XUManagedObject.ChangesLock")
private var _deletionChanges: Set<String> = Set()
private var _insertionChanges: Set<String> = Set()

/// This dictionary holds the last values of attributes. The dictionary has this
/// signature: [syncID:[attr:value]].
private var _attributeValueChanges: [String : [String : AnyObject]] = [:]

/// This dictionary holds the last values of relationships. The dictionary
/// has this signature: [syncID:[relationship:(syncID|[syncIDs])]].
private var _relationshipValueChanges: [String : [String : Set<String>]] = [:]

private extension XUManagedObject {
	@NSManaged private var ticdsSyncID: String
}


/// This is the base class for all synchronized objects. Upon insert, it generates
/// a syncUUID, which is used for tracking changes.
///
/// In your model, however, you need to create an attribute ticdsSyncID instead,
/// since this framework is designed to be compatible with existing stores that
/// use TICDS.
public class XUManagedObject: NSManagedObject {
	
	/// Call this when processing an insertion change - this will let the managed
	/// object class know that an object with this syncUUID has been inserted, so
	/// that it doesn't create an unnecessary sync change.
	public class func noticeSyncInsertionOfObjectWithID(syncUUID: String) {
		_changesLock.lock()
		_insertionChanges.insert(syncUUID)
		_changesLock.unlock()
	}
	
	
	private func _applyAttributeSyncChange(syncChange: XUAttributeSyncChange) {
		var value = syncChange.attributeValue
		if value is NSNull {
			value = nil
		}
		
		self.setValue(value, forKey: syncChange.attributeName)
	
		_changesLock.performLockedBlock {
			var changes = _attributeValueChanges[self.syncUUID] ?? [:]
			
			// Change it back to null if necessary
			if value == nil {
				value = NSNull()
			}
			
			changes[syncChange.attributeName] = value;
			
			_attributeValueChanges[self.syncUUID] = changes
		}
	}
	
	private func _applyDeletionSyncChange(syncChange: XUDeletionSyncChange) {
		// Delete
		let UUID = self.syncUUID
		self.managedObjectContext!.deleteObject(self)
		
		_changesLock.performLockedBlock {
			_deletionChanges.insert(UUID)
		}
	}
	
	private func _applyToManyRelationshipAdditionSyncChange(syncChange: XUToManyRelationshipAdditionSyncChange) {
		let targetUUID = syncChange.valueSyncID!
		let entityName = syncChange.valueEntityName!
		
		// We need to fetch this object. Since all synchable objects are subclasses
		// of XUManagedObject, we can look for XUManagedObject with such sync ID.
	 	let fetchRequest = NSFetchRequest(entityName: entityName)
		fetchRequest.predicate = NSPredicate(format: "ticdsSyncID == %@", targetUUID)
		
		guard let items = try? self.managedObjectContext!.executeFetchRequest(fetchRequest) else {
			XULog("Can't fetch items from MOC \(fetchRequest).")
			return
		}
		
		if items.count != 1 {
			XULog("Cannot find object with syncID \(targetUUID) - should be added for relationship \(syncChange.relationshipName)")
			return
		}
		
		var valueSet = (self.valueForKey(syncChange.relationshipName) as? Set<NSObject>) ?? Set()
		valueSet.insert(items.first! as! NSManagedObject)
		
		self.setValue(valueSet, forKey: syncChange.relationshipName)
		
		_changesLock.performLockedBlock {
			var relationshipValues = _relationshipValueChanges[self.syncUUID] ?? [:]
			
			var UUIDs = relationshipValues[syncChange.relationshipName] ?? Set()
			UUIDs.insert(targetUUID)
			
			relationshipValues[syncChange.relationshipName] = UUIDs
			_relationshipValueChanges[self.syncUUID] = relationshipValues
		}
	}
	
	private func _applyToManyRelationshipDeletionSyncChange(syncChange: XUToManyRelationshipDeletionSyncChange) {
		let targetUUID = syncChange.valueSyncID!
		
		guard var valueSet = self.valueForKey(syncChange.relationshipName) as? Set<XUManagedObject> else {
			XULog("Trying to apply to-many-relationship-deletion sync change on a property that doesn't return a Set with XUManagedObjects.")
			return
		}
		
		// Need to find the object
		guard let objectToDelete = valueSet.find({ $0.syncUUID == targetUUID }) else {
			XULog("Cannot remove object with syncID \(targetUUID) - should be removed for relationship \(syncChange.relationshipName)")
			return
		}
		
		valueSet.remove(objectToDelete)
		self.setValue(valueSet, forKey: syncChange.relationshipName)
		
		_changesLock.performLockedBlock {
			var relationshipValues = _relationshipValueChanges[self.syncUUID] ?? [:]
			
			// Don't care if the array doesn't exist
			var UUIDs = relationshipValues[syncChange.relationshipName] ?? Set()
			UUIDs.remove(targetUUID)
			
			relationshipValues[syncChange.relationshipName] = UUIDs
			_relationshipValueChanges[self.syncUUID] = relationshipValues
		}
	}
	
	private func _applyToOneRelationshipSyncChange(syncChange: XUToOneRelationshipSyncChange) {
		guard let targetUUID = syncChange.valueSyncID else {
			// Removing relationship - don't really care if the _relationshipValueChanges
			// actually contains a value
			if self.valueForKey(syncChange.relationshipName) != nil {
				// It's already nil -> do not set it, since it could mark the entity
				// as updated.
				return
			}
		
			self.setValue(nil, forKey: syncChange.relationshipName)
		
			_changesLock.performLockedBlock({
				var relationshipValues = _relationshipValueChanges[self.syncUUID] ?? [:]
				
				relationshipValues[syncChange.relationshipName] = Set()
				_relationshipValueChanges[self.syncUUID] = relationshipValues
			})
			
			return
		}
		
		/// We need to fetch this object. Since all synchable objects are subclasses
		/// of XUManagedObject, we can look for XUManagedObject with such sync ID.
		guard let entityName = syncChange.valueEntityName else {
			fatalError("-[XUManagedObject _applyToOneRelationshipSyncChange:] - targetUUID != nil and entityName == nil!")
		}
		
		let fetchRequest = NSFetchRequest(entityName: entityName)
		fetchRequest.predicate = NSPredicate(format: "ticdsSyncID == %@", targetUUID)
		
		guard let items = try? self.managedObjectContext!.executeFetchRequest(fetchRequest) else {
			XULog("Can't fetch items from MOC \(fetchRequest).")
			return
		}
		
		if items.count != 1 {
			XULog("Cannot find object with syncID \(targetUUID) - should be added for relationship \(syncChange.relationshipName)")
			return
		}
		
		let value = items.first!
		self.setValue(value, forKey: syncChange.relationshipName)
		
		_changesLock.performLockedBlock {
			var relationshipValues = _relationshipValueChanges[self.syncUUID] ?? [:]
			
			relationshipValues[syncChange.relationshipName] = Set(arrayLiteral: targetUUID)
			_relationshipValueChanges[self.syncUUID] = relationshipValues
		}
	}
		
	private func _createDeletionChanges() -> [XUSyncChange] {
		_changesLock.lock()
		
		if _deletionChanges.contains(self.syncUUID) {
			_changesLock.unlock()
			return []
		}
		
		_deletionChanges.insert(self.syncUUID)
		_changesLock.unlock()
		
		let deletionSyncChange = XUDeletionSyncChange(object: self)
		XULog("Created deletion sync change for \(self.syncUUID) [\(self.dynamicType)]")
		
		return [ deletionSyncChange ]
	}
	
	private func _createInsertionChanges() -> [XUSyncChange] {
		_changesLock.lock()
		
		if _insertionChanges.contains(self.syncUUID) {
			_changesLock.unlock()
			return []
		}
		
		_insertionChanges.insert(self.syncUUID)
		_changesLock.unlock()
		
		let syncChange = XUInsertionSyncChange(object: self)
		XULog("Created insertion sync change for \(self.syncUUID) [\(self.dynamicType)]")
		
		return self._createRelationshipChanges() + [syncChange]
	}
	
	private func _createRelationshipChangesForRelationship(relationship: NSRelationshipDescription) -> [XUSyncChange] {
		let inverseRelationship = relationship.inverseRelationship
		if relationship.toMany && inverseRelationship != nil && !inverseRelationship!.toMany {
			// With relationships that have inverse relationships, prefer the -to-one
			// side of the relationship
			return []
		}
		
		if relationship.toMany && inverseRelationship != nil && inverseRelationship!.toMany && relationship.name.caseInsensitiveCompare(inverseRelationship!.name) == .OrderedDescending {
			// Both relationships (this and the inverse) are -to-many - in order, 
			// not to sync both sides, just sync the relationship that is first 
			// alphabetically
			return []
		}
		
		if !relationship.toMany && inverseRelationship != nil && !inverseRelationship!.toMany && relationship.name.caseInsensitiveCompare(inverseRelationship!.name) == .OrderedDescending {
			// Both relationships (this and the inverse) are -to-one - in order, 
			// not to sync both sides, just sync the relationship that is first 
			// alphabetically
			return []
		}
		
		if relationship.toMany {
			return self._createToManyRelationshipChangesForRelationship(relationship)
		} else {
			return self._createToOneRelationshipChangesForRelationship(relationship)
		}
	}
	
	private func _createRelationshipChanges() -> [XUSyncChange] {
		let objectRelationshipsByName = self.entity.relationshipsByName
		var changes: [XUSyncChange] = []
		for (_, relationship) in objectRelationshipsByName {
			changes += self._createRelationshipChangesForRelationship(relationship)
		}
		return changes
	}
	
	private func _createToManyRelationshipChangesForRelationship(relationship: NSRelationshipDescription) -> [XUSyncChange] {
		let relationshipName = relationship.name
		guard let objects = self.valueForKey(relationshipName) as? Set<XUManagedObject> else {
			fatalError("\(self.dynamicType).\(relationshipName) returned a non-Set value.")
		}
		
		guard let commitedObjects = self.committedValuesForKeys([relationshipName])[relationshipName] as? Set<XUManagedObject> else {
			fatalError("\(self.dynamicType).committedValuesForKeys(\(relationshipName)) returned a non-Set value.")
		}
		
		var changes: [XUSyncChange] = []
	
		var addedObjects: Set<XUManagedObject> = Set()
		var removedObjects: Set<XUManagedObject> = Set()
		for obj in objects {
			if !commitedObjects.contains(obj) {
				addedObjects.insert(obj)
			}
		}
	
		for obj in commitedObjects {
			if !objects.contains(obj) {
				removedObjects.insert(obj)
			}
		}
	
		// We now make sure that the last values saved are non-nil.
		_changesLock.performLockedBlock {
			var objDict = _relationshipValueChanges[self.syncUUID] ?? [:]
			
			let UUIDs: Set<String> = Set(commitedObjects.map({ $0.syncUUID }))
			objDict[relationshipName] = UUIDs
			
			_relationshipValueChanges[self.syncUUID] = objDict;
		}
	
		for obj in addedObjects {
			let objUUID = obj.syncUUID
	
			_changesLock.lock()
			
			var objDict = _relationshipValueChanges[self.syncUUID] ?? [:]
	
			// We represent to-many relationships as a list of UUIDs.
			var UUIDs = objDict[relationshipName] ?? Set()
			if UUIDs.contains(objUUID) {
				// We've already seen this change
				_changesLock.unlock()
				continue
			}
			
			UUIDs.insert(objUUID)
			
			objDict[relationshipName] = UUIDs
			_relationshipValueChanges[self.syncUUID] = objDict;
			
			_changesLock.unlock()
	
			let syncChange = XUToManyRelationshipAdditionSyncChange(object: self, relationshipName: relationshipName, andValue: obj)
			XULog("Created to-many addition sync change for [\(self.dynamicType) \(relationshipName)]{\(self.syncUUID)} \(obj.dynamicType) [\(objUUID)]")
	
			changes.append(syncChange)
		}
	
		for obj in removedObjects {
			let objUUID = obj.syncUUID
			
			_changesLock.lock()
			
			var objDict = _relationshipValueChanges[self.syncUUID] ?? [:]
			
			// We represent to-many relationships as a list of UUIDs.
			var UUIDs = objDict[relationshipName] ?? Set()
			if !UUIDs.contains(objUUID) {
				// We've already seen this change
				_changesLock.unlock()
				continue
			}
			
			UUIDs.remove(objUUID)
			
			objDict[relationshipName] = UUIDs
			_relationshipValueChanges[self.syncUUID] = objDict;
			
			_changesLock.unlock()
	
			let syncChange = XUToManyRelationshipDeletionSyncChange(object: self, relationshipName: relationshipName, andValue: obj)
			XULog("Created to-many deletion sync change for [\(self.dynamicType) \(relationshipName)]{\(self.syncUUID)} \(obj.dynamicType) [\(objUUID)]")
			
			changes.append(syncChange)
		}
	
		return changes
	}
	
	private func _createToOneRelationshipChangesForRelationship(relationship: NSRelationshipDescription) -> [XUSyncChange] {
		let relationshipName = relationship.name
		
		let genericValue = self.valueForKey(relationshipName)
		let value = genericValue as? XUManagedObject
		let valueClassName = "\((value?.dynamicType as Any) ?? ("<<none>>" as Any))"
		if genericValue != nil && value == nil {
			XULog("Skipping sync of [\(self.dynamicType) \(relationshipName)]{\(self.syncUUID)} because value isn't subclass of XUManagedObject (\(valueClassName)).")
			return []
		}
	
		// In order to prevent an infinite loop of change syncs, we need to
		// take a look if the update is indeed from the user
		_changesLock.lock()
		
		var objDict = _relationshipValueChanges[self.syncUUID] ?? [:]
	
		let objValue = objDict[relationshipName]
		if objValue != nil {
			// We represent nil values as NSNull
			if (value == nil && (objValue == nil || objValue!.isEmpty)) || value?.syncUUID == objValue?.first {
				// It's the same -> unlock the lock and continue
				_changesLock.unlock()
				return []
			}
		}
	
		// Update the property value
		if value == nil {
			objDict[relationshipName] = Set()
		} else {
			objDict[relationshipName] = Set(arrayLiteral: value!.syncUUID)
		}
		
		_relationshipValueChanges[self.syncUUID] = objDict
	
		_changesLock.unlock()
	
	
		let syncChange = XUToOneRelationshipSyncChange(object: self, relationshipName: relationshipName, andValue:value)
		XULog("Creating to-one relationship change on [\(self.dynamicType) \(relationshipName)]{\(self.syncUUID)} -> \(valueClassName){\(value?.syncUUID ?? "<<none>>")}")
		return [syncChange]
	}

	private func _createUpdateChanges() -> [XUSyncChange] {
		var changes: [XUSyncChange] = []
		
		for property in self.entity.properties {
			let propertyName = property.name
			
			if let relationship = self.entity.relationshipsByName[propertyName] {
				// This is a relationship change
				changes += self._createRelationshipChangesForRelationship(relationship)
				continue
			}
			
			// This is a simple value change:
			// In order to prevent an infinite loop of change syncs, we need
			// to take a look if the update is indeed from the user
			_changesLock.lock()
			var objDict = _attributeValueChanges[self.syncUUID] ?? [:]
			let value = self.valueForKey(propertyName)

			let objValue = objDict[propertyName]
			if objValue != nil {
				// We represent nil values as NSNull
				if (value == nil && objValue is NSNull) {
					// It's the same -> unlock the lock and continue
					_changesLock.unlock()
					continue
				} else if let nsValue = value as? NSObject, nsObjValue = objValue as? NSObject where nsValue.isEqual(nsObjValue) {
					_changesLock.unlock()
					continue
				}
			}

			// Update the property value
			if value == nil {
				objDict[propertyName] = NSNull()
			} else {
				objDict[propertyName] = value
			}

			_attributeValueChanges[self.syncUUID] = objDict
			_changesLock.unlock()

			let change = XUAttributeSyncChange(object: self, attributeName: propertyName, andValue: value)
			XULog("Creating value change on [\(self.dynamicType) \(propertyName)]{\(self.syncUUID)}")
			
			changes.append(change)
		}
		
		return changes
	}
	
	/// This applies the sync change. It asserts that [self syncUUID] ==
	/// [syncChange objectSyncID].
	public func applySyncChange(syncChange: XUSyncChange) {
		let previousValue = self.isApplyingSyncChange
		self.isApplyingSyncChange = true
	
		switch syncChange {
		case let change as XUAttributeSyncChange:
			self._applyAttributeSyncChange(change)
		case let change as XUDeletionSyncChange:
			self._applyDeletionSyncChange(change)
		case let change as XUToManyRelationshipAdditionSyncChange:
			self._applyToManyRelationshipAdditionSyncChange(change)
		case let change as XUToManyRelationshipDeletionSyncChange:
			self._applyToManyRelationshipDeletionSyncChange(change)
		case let change as XUToOneRelationshipSyncChange:
			self._applyToOneRelationshipSyncChange(change)
		default:
			// Insertion change needs to be handled by the sync engine itself since the
			// entity doesn't exist yet, hence it cannot be called on the entity
			
			XULog("Trying to process unknown sync change \(syncChange)")
			fatalError("XUManagedObjectInvalidSyncChange: Unknown sync change \(syncChange).")
		}
	
		self.isApplyingSyncChange = previousValue
	}
	
	/// It is discouraged to use -awakeFromInsert for one main reason - you usually
	/// populate fields with default values in -awakeFromInsert. This is completely
	/// unnecessary and contra-productive when the entity is being created by the sync
	/// engine, since it overrides all the values anyway.
	///
	/// Moreover, if you create new objects or relationships within -awakeFromInsert,
	/// you end up creating new sync changes which is definitely undesirable.
	///
	/// @note - you must NOT create new entities within -awakeFromInsert! It would
	///			lead to a deadlock. Use -awakeFromNonSyncInsert instead.
	@available(*, deprecated, message="Use awakeFromNonSyncInsert instead.")
 	public override func awakeFromInsert() {
		super.awakeFromInsert()
		
		if !self.isBeingCreatedBySyncEngine {
			self.awakeFromNonSyncInsert()
		}
	}
	
	/// This is called from -awakeFromInsert if the object is not being created by
	/// the sync engine.
	///
	/// @note - for this to work, all instances need to be created using
	///			-initWithEntity:insertIntoManagedObjectContext:
 	public func awakeFromNonSyncInsert() {
		// Sets a new TICDS Sync ID
		self.ticdsSyncID = String.UUIDString
	}

	/// This method will create sync change if necessary for this object.
	public func createSyncChanges() -> [XUSyncChange] {
		if self.managedObjectContext?.documentSyncManager == nil {
			XULog("Skipping creating sync change for object \(self) since there is no document sync manager!")
			return []
		}
		
		if self.inserted {
			return self._createInsertionChanges()
		}
		if self.updated {
			return self._createUpdateChanges()
		}
		if self.deleted {
			return self._createDeletionChanges()
		}
		
		return []
	}
	
	public convenience override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
		self.init(entity: entity, insertIntoManagedObjectContext: context)
	}
	
	public required init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?, asResultOfSyncAction isSync: Bool) {
		// We cannot assign _isBeingCreatedBySyncEngine = sync, since CoreData
		// re-allocates the object as an instance of a generated subclass,
		// which hence loses the data. The new instance also has a different
		// address.
		_initializationLock.lock()
		
		if _currentInitInitiatedInSync {
			_initializationLock.unlock()
			fatalError("Nested object creation within synchronization - this is likely caused by you inserting new entities into MOC from -awakeFromInsert. Use -awakeFromNonSyncInsert instead.")
		}
		
		_currentInitInitiatedInSync = isSync
		_initializationLock.unlock()
		
		defer {
			_initializationLock.lock()
			_currentInitInitiatedInSync = false
			_initializationLock.unlock()
		}
		
		super.init(entity: entity, insertIntoManagedObjectContext: context)
	}
	
	
	/// Marked as true if the engine is currently applying a sync change. If you
	/// are observing some changes made to the object, and creating further changes
	/// based on that observation, you can opt-out based on this property.
	public internal(set) var isApplyingSyncChange: Bool = false

	/// This is an important property that returns YES if the object is being 
	/// created by the sync engine - i.e. the entity was inserted into the context.
	///
	/// While it may seem unnecessary, you usually populate fields with initial 
	/// values within -awakeFromInsert.
	public var isBeingCreatedBySyncEngine: Bool {
		return _currentInitInitiatedInSync
	}

	/// Sync UUID. This property is only a proxy to the underlying ticdsSyncID 
	/// which is implemented for backward compatibility with existing stores.
	public var syncUUID: String {
		return self.ticdsSyncID
	}
	
}



/// This is just a compatibility class.
@available(*, deprecated)
public class TICDSSynchronizedManagedObject: XUManagedObject { }

