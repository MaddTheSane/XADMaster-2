/*
 * CSSegmentedHandle.h
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
#import "CSHandle.h"

#define CSSegmentedHandle XADSegmentedHandle

XADEXTERN NSExceptionName const CSNoSegmentsException;
XADEXTERN NSExceptionName const CSSizeOfSegmentUnknownException;

XADEXPORT
@interface CSSegmentedHandle:CSHandle
{
	NSInteger count;
	NSInteger currindex;
	CSHandle *currhandle;
	off_t *segmentends;
	NSArray *segmentsizes;
}

// Initializers
-(instancetype)init;
-(instancetype)initAsCopyOf:(CSSegmentedHandle *)other;

// Public methods
@property (NS_NONATOMIC_IOSONLY, readonly) CSHandle *currentHandle;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSArray<NSNumber*> *segmentSizes;

// Implemented by this class
@property (NS_NONATOMIC_IOSONLY, readonly) off_t fileSize;
@property (NS_NONATOMIC_IOSONLY, readonly) off_t offsetInFile;
@property (NS_NONATOMIC_IOSONLY, readonly) BOOL atEndOfFile;

-(void)seekToFileOffset:(off_t)offs;
-(void)seekToEndOfFile;
-(int)readAtMost:(int)num toBuffer:(void *)buffer;

@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString *name;

// Implemented by subclasses
@property (NS_NONATOMIC_IOSONLY, readonly) NSInteger numberOfSegments;
-(off_t)segmentSizeAtIndex:(NSInteger)index;
-(CSHandle *)handleAtIndex:(NSInteger)index;

// Internal methods
-(void)_open;
-(void)_setCurrentIndex:(NSInteger)newindex;
-(void)_raiseNoSegments;
-(void)_raiseSizeUnknownForSegment:(NSInteger)i;

@end
