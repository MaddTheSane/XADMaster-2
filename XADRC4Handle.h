/*
 * XADRC4Handle.h
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
#import "CSStreamHandle.h"

@class XADRC4Engine;

XADEXPORT
@interface XADRC4Handle:CSStreamHandle
{
	off_t startoffs;
	NSData *key;
	XADRC4Engine *rc4;
}

-(instancetype)init UNAVAILABLE_ATTRIBUTE;
-(instancetype)initWithHandle:(CSHandle *)handle key:(NSData *)keydata NS_DESIGNATED_INITIALIZER;

-(void)resetStream;
-(int)streamAtMost:(int)num toBuffer:(void *)buffer;

@end

XADEXPORT
@interface XADRC4Engine:NSObject
{
	uint8_t s[256];
	int i,j;
}

+(XADRC4Engine *)engineWithKey:(NSData *)key;

-(instancetype)init UNAVAILABLE_ATTRIBUTE;
-(instancetype)initWithKey:(NSData *)key NS_DESIGNATED_INITIALIZER;

-(NSData *)encryptedData:(NSData *)data;

-(void)encryptBytes:(unsigned char *)bytes length:(int)length;
-(void)skipBytes:(int)length;

@end

