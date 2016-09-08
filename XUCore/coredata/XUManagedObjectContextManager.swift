//
//  XUManagedObjectContextManager.swift
//  XUCore
//
//  Created by Charlie Monroe on 7/22/16.
//  Copyright © 2016 Charlie Monroe Software. All rights reserved.
//

import Foundation
import CoreData

/// Originally, part of XUCore as FCContextHolder - a simple class that will 
/// automatically create NSManagedObjectContext for you, as well as the coordinator,
/// etc. The idea here is that you subclass this class and add your own functionality
/// around the MOC that is provided to you by this manager.
///
/// In order for you to do so, you need to override the following vars:
///
/// - modelFileName
/// - persistentStoreFileName
///
open class XUManagedObjectContextManager {
	
	fileprivate var _managedObjectContext: NSManagedObjectContext!
	fileprivate var _managedObjectModel: NSManagedObjectModel!
	fileprivate var _persistentStoreCoordinator: NSPersistentStoreCoordinator!
	
	public final var managedObjectContext: NSManagedObjectContext {
		return _managedObjectContext
	}
	
	public final var managedObjectModel: NSManagedObjectModel {
		return _managedObjectModel
	}
	
	public final var persistentStoreCoordinator: NSPersistentStoreCoordinator {
		return _persistentStoreCoordinator
	}
	
	/// This will throw is there is any issue creating the MOC.
	public init() throws {
		// Model:
		guard let modelURL = Bundle.main.url(forResource: self.modelFileName, withExtension: "momd") else {
			throw NSError(domain: NSCocoaErrorDomain, code: NSFileNoSuchFileError, userInfo: nil)
		}
		
		_managedObjectModel = NSManagedObjectModel(contentsOf: modelURL)
		guard _managedObjectModel != nil else {
			throw NSError(domain: NSCocoaErrorDomain, code: NSFileNoSuchFileError, userInfo: nil)
		}
		
		let storeURL = self.persistentStoreLocationURL.appendingPathComponent(self.persistentStoreFileName).appendingPathExtension("sqlite")
		
		_persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
		try _persistentStoreCoordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL, options: [
			NSMigratePersistentStoresAutomaticallyOption: true
		])
		
		_managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
		_managedObjectContext.persistentStoreCoordinator = _persistentStoreCoordinator
		_managedObjectContext.propagatesDeletesAtEndOfEvent = false
		
	}
	
	/// File name of the CoreData model.
	open var modelFileName: String {
		XUThrowAbstractException()
	}
	
	/// Name of the persistent store file name. The file is stored in 
	/// self.persistentStoreLocationURL
	open var persistentStoreFileName: String {
		XUThrowAbstractException()
	}
	
	/// This points to the folder where the manager saves the persistent store.
	/// By default, this is within the app's Application Support folder.
	open var persistentStoreLocationURL: URL {
		return try! FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
	}
	
	/// Processes pending changes and saves context.
	open func saveContext() {
		let ctx = self.managedObjectContext
		ctx.performAndWait {
			ctx.processPendingChanges()
			if ctx.hasChanges {
				do {
					try ctx.save()
				} catch let err as NSError {
					XULog("Managed object context failed saving \(err)")
				}
			}
		}
	}
	
}
