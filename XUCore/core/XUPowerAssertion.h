//
//  XUPowerAssertion.h
//  Downie
//
//  Created by Charlie Monroe on 8/13/14.
//  Copyright (c) 2014 Charlie Monroe Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface XUPowerAssertion : NSObject

+(nullable instancetype)powerAssertionWithName:(nonnull NSString *)name;
+(nullable instancetype)powerAssertionWithName:(nonnull NSString *)name andTimeout:(NSTimeInterval)timeout;

/** May return nil if it fails to create the power assertion. */
-(nullable instancetype)initWithName:(nonnull NSString *)name andTimeout:(NSTimeInterval)timeout;

-(void)stop;

@property (readonly, assign, nonatomic) NSTimeInterval timeout;
@property (readonly, strong, nonnull, nonatomic) NSString *name;
@property (readwrite, weak, nonatomic) id context;

@end
