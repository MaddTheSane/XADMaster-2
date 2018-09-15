/*
 * CSMultiFileHandle.h
 *
 * Copyright (c) 2017-present, MacPaw Inc. All rights reserved.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
 * MA 02110-1301  USA
 */
#import "CSSegmentedHandle.h"
#import "CSFileHandle.h"

NS_ASSUME_NONNULL_BEGIN

#define CSMultiFileHandle XADMultiFileHandle

XADEXPORT
@interface CSMultiFileHandle:CSSegmentedHandle
{
	NSArray<NSString*> *paths;
}

+(nullable CSHandle *)handleWithPathArray:(NSArray<NSString*> *)patharray;
+(nullable CSHandle *)handleWithPaths:(NSString *)firstpath,...;

// Initializers
-(nullable instancetype)initWithPaths:(NSArray<NSString*> *)patharray;
-(instancetype)initAsCopyOf:(CSMultiFileHandle *)other;

// Public methods
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSArray<NSString*> *paths;

// Implemented by this class
@property (NS_NONATOMIC_IOSONLY, readonly) NSInteger numberOfSegments;
-(off_t)segmentSizeAtIndex:(NSInteger)index;
-(CSHandle *)handleAtIndex:(NSInteger)index;

// Internal methods
-(void)_raiseError;

@end

NS_ASSUME_NONNULL_END
