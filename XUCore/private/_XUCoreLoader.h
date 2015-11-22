//
//  _XUCoreLoader.h
//  XUCore
//
//  Created by Charlie Monroe on 11/21/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

#import <Foundation/Foundation.h>

/** This is a private class that does all the stuff other classes rely on being
 * performed during launch. Since Swift doesn't allow +load overrides, it is
 * necessary to have a private class that does all of this for us.
 */
@interface _XUCoreLoader : NSObject
@end
