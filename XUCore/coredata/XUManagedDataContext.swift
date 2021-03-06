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
@available(macOS, deprecated: 10.12, message: "Use NSPersistentContainer.")
open class XUManagedDataContext {
	
	public let managedObjectContext: NSManagedObjectContext
	public let persistentStore: NSPersistentStore
	public let persistentStoreCoordinator: NSPersistentStoreCoordinator
	
	
	/// Inits by reading/creating a database at `URL`.
	public init(persistentStoreURL: URL, objectModel model: NSManagedObjectModel? = nil, bundle: Bundle = Bundle.main, concurrencyType: NSManagedObjectContextConcurrencyType = .mainQueueConcurrencyType, persistentStoreOptions: [String : Any] = [NSMigratePersistentStoresAutomaticallyOption: true]) {
		self.managedObjectContext = NSManagedObjectContext(concurrencyType: concurrencyType)
		
		guard let objectModel = model ?? NSManagedObjectModel.mergedModel(from: [bundle]) else {
			fatalError("No models in main bundle.")
		}
		
		self.persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: objectModel)
		self.managedObjectContext.persistentStoreCoordinator = self.persistentStoreCoordinator
		
		let options = persistentStoreOptions
		
		var persistentStore: NSPersistentStore
		do {
			persistentStore = try self.persistentStoreCoordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: persistentStoreURL, options: options)
		} catch let firstError {
			XULog("Failed to add persistent store due to error \(firstError)")
			
			do {
				/// Try to delete the persistent store.
				let parentURL = persistentStoreURL.deletingLastPathComponent()
				try FileManager.default.removeItem(at: parentURL)
				try FileManager.default.createDirectory(at: parentURL, withIntermediateDirectories: true, attributes: nil)
				
				persistentStore = try self.persistentStoreCoordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: persistentStoreURL, options: options)
			} catch let secondError {
				XULog("Failed to create persistent store due to error \(secondError)")
				
				// Still nil - this mustn't happen!
				fatalError("Cannot create persistent store.")
			}
		}
	
		self.persistentStore = persistentStore
	}
	
	
	
}
