/*
 * LZWHandle.h
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
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wquoted-include-in-framework-header"
#import "../CSByteStreamHandle.h"
#import "../LZW.h"
#pragma clang diagnostic pop

XADEXTERN NSExceptionName const LZWInvalidCodeException;

XADEXPORT
@interface LZWHandle:CSByteStreamHandle
{
	BOOL early;

	LZW *lzw;
	int symbolsize;

	int currbyte;
	uint8_t buffer[4096];
}

-(instancetype)initWithHandle:(CSHandle *)handle earlyChange:(BOOL)earlychange;

-(void)clearTable;

-(void)resetByteStream;
-(uint8_t)produceByteAtOffset:(off_t)pos;

@end
