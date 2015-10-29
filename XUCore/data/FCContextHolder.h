//
//  FCContextHolder.h
//  Rottenwood
//
//  Created by Charlie Monroe on 1/3/13.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface FCContextHolder : NSObject

-(NSString*)modelFileName;
-(NSString*)persistentStoreFileName;
-(void)saveContext;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@end
