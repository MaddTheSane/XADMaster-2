/*
 * CCITTHandle.h
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
#import "../XADPrefixCode.h"
#pragma clang diagnostic pop

XADEXTERN NSExceptionName const CCITTCodeException;

XADEXPORT
@interface CCITTFaxHandle:CSByteStreamHandle
{
	int columns,white;
	int column,colour,bitsleft;
}

-(instancetype)initWithInputBufferForHandle:(CSHandle *)handle columns:(int)cols white:(int)whitevalue;

-(void)resetByteStream;
-(uint8_t)produceByteAtOffset:(off_t)pos;

-(void)startNewLine;
-(void)findNextSpanLength;

@end

XADEXPORT
@interface CCITTFaxT41DHandle:CCITTFaxHandle
{
	XADPrefixCode *whitecode,*blackcode;
}

-(instancetype)initWithHandle:(CSHandle *)handle columns:(int)cols white:(int)whitevalue;

-(void)startNewLine;
-(void)findNextSpanLength;

@end

XADEXPORT
@interface CCITTFaxT6Handle:CCITTFaxHandle
{
	int *prevchanges,numprevchanges;
	int *currchanges,numcurrchanges;
	int prevpos,previndex,currpos,currcol,nexthoriz;
	XADPrefixCode *maincode,*whitecode,*blackcode;
}

-(instancetype)initWithHandle:(CSHandle *)handle columns:(int)columns white:(int)whitevalue;

-(void)resetByteStream;
-(void)startNewLine;
-(void)findNextSpanLength;

@end

