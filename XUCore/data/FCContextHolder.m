//
//  FCContextHolder.m
//  Rottenwood
//
//  Created by Charlie Monroe on 1/3/13.
//
//

#import "FCContextHolder.h"

#import "FCLog.h"

@implementation FCContextHolder

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;


-(NSURL *)_applicationDocumentsDirectoryURL{
	return [[NSFileManager defaultManager] URLForDirectory:NSApplicationSupportDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:NULL];
}
-(NSManagedObjectContext *)managedObjectContext{
	NSAssert([NSThread isMainThread], @"Not main thread");
	
	if (![NSThread isMainThread]){
		@throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"not main thread" userInfo:nil];
	}
	
	@synchronized(self){
		if (_managedObjectContext != nil) {
			return _managedObjectContext;
		}
		
		NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
		if (coordinator != nil) {
			_managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
			[_managedObjectContext setPersistentStoreCoordinator:coordinator];
			//[_managedObjectContext setRetainsRegisteredObjects:YES];
			[_managedObjectContext setPropagatesDeletesAtEndOfEvent:NO];
		}
		return _managedObjectContext;
	}
}
-(NSManagedObjectModel *)managedObjectModel{
	NSAssert([NSThread isMainThread], @"Not main thread");
	@synchronized(self){
		if (_managedObjectModel != nil) {
			return _managedObjectModel;
		}
		NSURL *modelURL = [[NSBundle mainBundle] URLForResource:[self modelFileName] withExtension:@"momd"];
		_managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
		return _managedObjectModel;
	}
}
-(NSString *)modelFileName{
	[[NSException exceptionWithName:@"FCContextHolderAbstractionException" reason:@"-modelFileModel" userInfo:nil] raise];
	return nil;
}
-(NSPersistentStoreCoordinator *)persistentStoreCoordinator{
	NSAssert([NSThread isMainThread], @"Not main thread");
	@synchronized(self){
		if (_persistentStoreCoordinator != nil) {
			return _persistentStoreCoordinator;
		}
		
		NSURL *storeURL = [[[self _applicationDocumentsDirectoryURL] URLByAppendingPathComponent:[self persistentStoreFileName]] URLByAppendingPathExtension:@"sqlite"];
		
		NSError *error = nil;
		_persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
		if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:@{ NSMigratePersistentStoresAutomaticallyOption : @(YES) } error:&error]) {
			FCLog(@"%s - persistent store coordinator failed adding persistent store at URL %@ - error %@", __FCFUNCTION__, storeURL, error);
		}
		
		return _persistentStoreCoordinator;
	}
}
-(NSString *)persistentStoreFileName{
	[[NSException exceptionWithName:@"FCContextHolderAbstractionException" reason:@"-persistentStoreFileName" userInfo:nil] raise];
	return nil;
}
-(void)saveContext{
	NSAssert([NSThread isMainThread], @"Not main thread");
	NSManagedObjectContext *managedObjectContext = [self managedObjectContext];
	[managedObjectContext performBlockAndWait:^{
		NSError *error = nil;
		[managedObjectContext processPendingChanges];
		if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
			FCLog(@"%s - managed object context failed saving - error %@", __FCFUNCTION__, error);
		}
	}];
}


@end
