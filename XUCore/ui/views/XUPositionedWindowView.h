//
//  XUPositionedWindowView.h
//  Downie
//
//  Created by Charlie Monroe on 9/10/14.
//  Copyright (c) 2014 Charlie Monroe Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface XUPositionedWindowView : NSView

-(NSRect)frameForWindowBounds:(NSRect)bounds andRealFrame:(NSRect)realFrame;

@property (readwrite, weak, nullable, nonatomic) IBOutlet NSWindow *connectedToWindow;

/** Override this to NO if you don't want the view to be connected
 * under some cirtumstances. By default YES.
 */
@property (readonly, nonatomic) BOOL shouldBeConnectedOnAwakeFromNib;

@end
