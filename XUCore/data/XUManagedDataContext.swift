//
//  XUManagedDataContext.swift
//  XUCore
//
//  Created by Charlie Monroe on 2/23/16.
//  Copyright © 2016 Charlie Monroe Software. All rights reserved.
//

import Foundation
import CoreData

/// This is a very simple class that creates a NSManagedObjectContext and either
/// creates or reads persistent storage. This class also contains several helper
/// methods that help fetching entities.
public class XUManagedDataContext {
	
	public let managedObjectContext: NSManagedObjectContext
	public let persistentStore: NSPersistentStore
	public let persistentStoreCoordinator: NSPersistentStoreCoordinator
	
	
	/// Inits by reading/creating a database at `URL`.
	public init(persistentStoreURL: NSURL) {
		self.managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)

		guard let objectModel = NSManagedObjectModel.mergedModelFromBundles([ XUMainBundle ]) else {
			fatalError("No models in main bundle.")
		}
		
		self.persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: objectModel)
		self.managedObjectContext.persistentStoreCoordinator = self.persistentStoreCoordinator
		
		let options = [
			NSMigratePersistentStoresAutomaticallyOption: true,
			NSSQLitePragmasOption: [ "journal_mode": "DELETE" ]
		]
		
		var persistentStore = try? self.persistentStoreCoordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: persistentStoreURL, options: options)
		if persistentStore == nil {
			/// Try to delete the persistent store.
			if let parentURL = persistentStoreURL.URLByDeletingLastPathComponent {
				_ = try? NSFileManager.defaultManager().removeItemAtURL(parentURL)
				_ = try? NSFileManager.defaultManager().createDirectoryAtURL(parentURL, withIntermediateDirectories: true, attributes: nil)
			} else {
				// Shouldn't really happen...
				_ = try? NSFileManager.defaultManager().removeItemAtURL(persistentStoreURL)
			}
			
			persistentStore = try? self.persistentStoreCoordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: persistentStoreURL, options: options)
		}
		
		if persistentStore == nil {
			// Still nil - this mustn't happen!
			fatalError("Cannot create persistent store.")
		}
		
		self.persistentStore = persistentStore!
	}
	
	
	
}
