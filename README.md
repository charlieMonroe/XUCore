# XUCore

This is a core library that we're using in our apps.

It is a set of class categories/extensions, utilities for logging, localization, regex searches, etc. etc.

If you decide to use this in your own project, some acknowledgement is required.

## History

We're currently in the middle of reorganizing the framework. Originally, this was just files in a separate repository and those got included directly in the projects, now they are put together. For historical reasons, the framework contains a bunch of classes

## Usage

As simple as `@import XUCore;` in Objective-C or `import XUCore` in Swift. 

Most classes now have proper documentation, so feel free to go through it.

## Deprecation

All Objective-C code that is currently present in the framework is deprecated for use in Swift with the exception of:

- additions - there are two types of additions that are still in ObjC - one set extends classes that are not really used in Swift (`NSArray`, `NSDictionary` and `NSString`), or they use `CommonCrypto`, which still isn't available as a module to be easily imported and I haven't had time to get it working in Swift yet.
- XURegex - it leverages on C++ code, which cannot be used from Swift.
- XUExceptionHandler - obviously needs to be written in ObjC, since there is no way to catch ObjC exceptions in Swift.
- XUString - soon to be rewritten

In addition to this, you can (temporarily), use the following classes/functions from ObjC:

- FCLog - in Swift, use XULog, though.
- FCLocalizationSupport - in Swift, use XULocalizationSupport.
