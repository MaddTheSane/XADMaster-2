/*
 * XADSkipHandle.h
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
#import <Foundation/Foundation.h>
#import "CSHandle.h"

typedef struct XADSkipRegion
{
	off_t actual,skip;
} XADSkipRegion;

//static inline XADSkip XADMakeSkip(off_t start,off_t length) { XADSkip skip={start,length}; return skip; }

@interface XADSkipHandle:CSHandle
{
	XADSkipRegion *regions;
	int numregions;
}

-(instancetype)initWithHandle:(CSHandle *)handle NS_DESIGNATED_INITIALIZER;
-(instancetype)initAsCopyOf:(XADSkipHandle *)other NS_DESIGNATED_INITIALIZER;

-(void)addSkipFrom:(off_t)start length:(off_t)length;
-(void)addSkipFrom:(off_t)start to:(off_t)end;
-(off_t)actualOffsetForSkipOffset:(off_t)skipoffset;
-(off_t)skipOffsetForActualOffset:(off_t)actualoffset;

@property (NS_NONATOMIC_IOSONLY, readonly) off_t fileSize;
@property (NS_NONATOMIC_IOSONLY, readonly) off_t offsetInFile;
@property (NS_NONATOMIC_IOSONLY, readonly) BOOL atEndOfFile;

-(void)seekToFileOffset:(off_t)offs;
-(void)seekToEndOfFile;
-(int)readAtMost:(int)num toBuffer:(void *)buffer;

@end
