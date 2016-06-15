# XUSync

## What is XUSync

Simply said, `XUSync` is a simple-to-use, lightweight CoreData sync framework. Sync over iCloud to be precise - but other sync options should be fairly easy to add - Dropbox sync is included as well, but needs to be added to the app itself since it needs to link against the Dropbox framework.

## Why XUSync?

Sure, there are existing solutions - but have you actually tried using them?

- Apple's iCloud documents (`UIManagedDocument`) - whoa, are you crazy? Just iOS, hence no OS X support. Also very buggy. There are some attempts to create an OS X counterpart for `UIManagedDocument` (e.g. [`BSManagedDocument`](https://github.com/karelia/BSManagedDocument)), but I found none of them to really work well.
- [TICDS](https://github.com/nothirst/TICoreDataSync) - fairly nice (main inspiration for `XUSync` taken from there), but has a lot of issues, branch with iCloud support is still considered experimental, users of my apps have been reporting some data not syncing through, unnecessarily complicated (in comparison to `XUSync`, required 350 extra lines of code), spawns way too many threads (which I believe leads to some race conditions within the framework), etc, etc.
- other libraries - mostly not working at all, or not well

## Limitations

As I mentioned, the framework is meant to be lightweight. It should be easy to use, requiring only a few lines of code (~50 LOC). This comes with some limitations:

- to prevent race conditions and so on, `XUSync` reads all files on a separate thread, but all the actual syncing stuff (MOC interaction) happens on the main thread. It usually shouldn't be a big deal unless there is a lot of changes. But this shouldn't be the regular scenario.
- it's document-based, i.e. you always need to have something that's called a document within the framework. If you're dealing with a simple CoreData database, just consider it a single document with a fixed ID.

## How to use?

### Quick Start

- include the `XUSyncEngine` framework in your OS X app, `XUSyncEngineMobile` in your iOS app. 
- in your data model, each root class of your entities must include the `ticdsSyncID` attribute (String). If you're starting a new project, consider creating an entity `XUManagedObject` and inheriting all your entities from it.
- all your CoreData classes must inherit from `XUManagedObject`
- __never__ create anything in `-awakeFromInsert`. Use `XUManagedObject`'s `-awakeFromNonSyncInsert` - see below and `XUManagedObject.h` for more info.
- create app sync manager
- create a document sync manager per document

Unlike TICDS, you don't need to include any data models, since it's all included in the framework.


### XUApplicationSyncManager

This class handles discovering and downloading documents from the iCloud. To begin, instantiate this class with a name of your iCloud store and a delegate. The name of the iCloud store can be anything, usually the name of your app, though. This naming thing allows you to have multiple separate databases within one app, all syncing over iCloud.

The delegate should only have one method implemented:

```
-(void)applicationSyncManager:(nonnull XUApplicationSyncManager *)manager didFindNewDocumentWithID:(nonnull NSString *)documentID;
```

You can check against deleted/hidden documents and ignore this call, or call

```
-(void)downloadDocumentWithID:(nonnull NSString *)documentID toURL:(nonnull NSURL *)fileURL withCompletionHandler:(nonnull void(^)(BOOL success, NSURL * __nullable documentURL, NSError * __nullable error))completionHandler;
```

This will download the document to specific fileURL and you will be notified how it went via the `completionHandler` - always on the main thread.

_Note:_ Usually, when syncing for the first time, the `-downloadDocumentWithID:...` method will fail a few times. This is caused by the OS not having completely downloaded the document yet. While `XUSync` does use `NSFileCoordinator` for reading the database and according to the documentation it should wait until it's downloaded (If the device has not yet downloaded the file at the given URL, this method blocks (potentially for a long time) while the file is downloaded.), it often does not.

Just ignore it. The app sync manager will call the delegate again in a few to repeat the try.


### XUDocumentSyncManager

Once you're done with the app sync manager, you need to create an instance of `XUDocumentSyncManager` for each document (or just one in case of a single-document app).

```
-(nonnull instancetype)initWithManagedObjectContext:(nonnull NSManagedObjectContext *)managedObjectContext applicationSyncManager:(nonnull XUApplicationSyncManager *)appSyncManager andUUID:(nonnull NSString *)UUID;
```

Pass in the MOC, that you want to sync, the `appSyncManager` that this document sync manager should be owned by and a UUID of the document (unique per document).

The document sync manager will sync periodically (or you can force the sync via a method); and it will automatically create sync changes when your MOC gets to be saved.

That's it! Almost.

### XUManagedDocument

In order for this to work, you need to base all your classes with `XUManagedObject`. The framework also includes a `TICDSSynchronizedManagedObject` class for compatibility with TICDS. Due to backward compatibility with TICDS, your data model's root classes must always include the `ticdsSyncID` attribute, instead of the `syncUUID` which is exposed via the header file.

Due to how things work, it is absolutely forbidden to implement anything in `-awakeFromInsert`. Use `XUManagedObject`'s `-awakeFromNonSyncInsert` - see `XUManagedObject.h` for more info.

BTW this was causing a lot of issues in TICDS - you usually need to populate attributes and relationships within `-awakeFromInsert`. It doesn't really matter for regular attributes (even though it's unnecessary), but it matters if you create some basic relationships on the entity (e.g. if your entity represents a building, you may create some floors, etc.).


