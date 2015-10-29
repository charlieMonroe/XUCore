//
//  UIView+Enclosing.h
//  Navigator
//
//  Created by Charlie Monroe on 12/19/14.
//  Copyright (c) 2014 Mews Systems. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (Enclosing)

/** Returns a scroll view that's above this view in the hierarchy. 
 *
 * @note - called on a scroll view, returns self.
 */
-(UIScrollView *)enclosingScrollView;

/** Returns a table view that's above this view in the hierarchy.
 *
 * @note - called on a table view, returns self.
 */
-(UITableView *)enclosingTableView;

/** Returns a table view cell that's above this view in the hierarchy.
 *
 * @note - called on a table view cell, returns self.
 */
-(UITableViewCell *)enclosingTableViewCell;

@end
