/*
 * XADDeflateHandle.h
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
#import "XADLZSSHandle.h"
#import "XADPrefixCode.h"

typedef NS_ENUM(int, XADDeflateVariant) {
	XADDeflateVariantNormal = 0,
	XADDeflateVariantDeflate64 = 1,
	XADDeflateVariantStuffitX = 2,
	XADDeflateVariantNSIS = 3
};
#define XADNormalDeflateVariant XADDeflateVariantNormal
#define XADDeflate64DeflateVariant XADDeflateVariantDeflate64
#define XADStuffItXDeflateVariant XADDeflateVariantStuffitX
#define XADNSISDeflateVariant XADDeflateVariantNSIS

@interface XADDeflateHandle:XADLZSSHandle
{
	XADDeflateVariant variant;

	XADPrefixCode *literalcode,*distancecode;
	XADPrefixCode *fixedliteralcode,*fixeddistancecode;
	BOOL storedblock,lastblock;
	int storedcount;

	int order[19];
}

-(instancetype)initWithHandle:(CSHandle *)handle length:(off_t)length;
-(instancetype)initWithHandle:(CSHandle *)handle length:(off_t)length variant:(XADDeflateVariant)deflatevariant;

-(void)setMetaTableOrder:(const int *)order;

-(void)resetLZSSHandle;
-(int)nextLiteralOrOffset:(int *)offset andLength:(int *)length atPosition:(off_t)pos;

-(void)readBlockHeader;
-(XADPrefixCode *)allocAndParseMetaCodeOfSize:(int)size;
-(XADPrefixCode *)fixedLiteralCode;
-(XADPrefixCode *)fixedDistanceCode;

@end
