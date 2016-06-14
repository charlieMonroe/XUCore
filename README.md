# XUCore

This is a core framework that we're using in our apps. It extends existing types by adding convenience methods, but also introduces a lot of classes that allow you to add certain functionality to your app with a single line of code.

If you decide to use this in your own project, some acknowledgement is required.

## History

We're currently almost done reorganizing the framework. Originally, this was just files in a separate repository and those got included directly in the projects, now they are put together. For historical reasons, the framework contains a bunch of classes (or sets of functions) that are prefixed as `FC`. We're migrating those to the `XU` prefix nomenclature as they get rewritten in Swift.

The `FC` classes stay available as subclasses of the `XU` classes, but are deprecated and must not be used since they are soon to be removed entirely.

## Usage

As simple as `@import XUCore;` in Objective-C or `import XUCore` in Swift.

Most classes now have proper documentation, so feel free to go through it. More and more features start being Swift-only, so using this framework from ObjC isn't a good idea.

## Deprecation

All Objective-C code that is currently present in the framework is deprecated for use in Swift with the exception of:

- additions - there are two types of additions that are still in ObjC - one set extends classes that are not really used in Swift (`NSArray`, `NSDictionary` and `NSString`), or they use `CommonCrypto`, which still isn't available as a module to be easily imported and I haven't had time to get it working in Swift yet.
- XURegex - it leverages on C++ code, which cannot be used from Swift.
- XUExceptionHandler - obviously needs to be written in ObjC, since there is no way to catch ObjC exceptions in Swift.

## Documentation

The framework contains several groups with certain functionality.

### Additions

Various additional functionality on various classes (ObjC categories or Swift extensions). A few notable examples:

- `ArrayExtensions` - extending `SequenceType`, `Array`, etc.
- `DictionaryExtensions` - very convenient methods mostly for dealing with JSON dictionaries.
- `NSDecimalNumberAdditions` - Swift-ified version of `NSDecimalNumber`.
- `NSLockAdditions` - perform a locked block while catching exceptions and unlocking the lock when the exception is thrown to prevent dead-lock.
- `NSMutableURLRequestAdditions` - various methods for setting header values.
- `NSURLExtensions` - extension for various resource values.
- `NSXMLAdditions` - convenience methods for getting values on Xpaths.
- `StringExtensions` - extending `String` with many various improvements.

### AppStore

You can mark menu items with tag 127 and automatically hide them. Also, includes an in-app purchases manager which can take simplify the StoreKit interaction.

### Core

- `XUAbstract` - a `@noreturn` function that can be used for creating abstract methods.
- `XUApplicationSetup` - class that reads the `Info.plist` file and provides information from it. You can subclass it to include your own setup.
- `XUAppScopeBookmarksManager` - saves app-scope `NSURL` bookmarks.
- `XUBlockThreading` - easier API for executing blocks.
- `XUExceptionHandler` - class that allows you to catch and deal with ObjC exceptions in Swift code.
- `XUPowerAssertion` - Swift wrapper around the IOKit power assertion API.
- `XUPreferences` - convenience functions for reading and writing to `NSUserDefaults`.
- `XUString` - plain C-style string in Swift. Access characters directly, etc. Mostly useful for various transformations.
- `XUSubclassCollector` - collect all subclasses of a certain class. Note that when there are subclasses with generics, this will return all possible combinations of the generics used in the app.

### CoreData

Mostly sync engine. Originally 
