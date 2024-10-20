/*
 * XADSWFGeometry.h
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
#import "CSHandle.h"
#pragma clang diagnostic pop

typedef struct
{
	int x,y;
} SWFPoint;

typedef struct
{
	int x,y,width,height;
} SWFRect;

typedef struct
{
	int a00,a01,a02;
	int a10,a11,a12;
} SWFMatrix;

static inline SWFPoint SWFMakePoint(int x,int y) { SWFPoint res={x,y}; return res; }
XADEXTERN SWFPoint SWFPointOnLine(SWFPoint a,SWFPoint b,float t);

static inline SWFRect SWFMakeRect(int x,int y,int width,int height) { SWFRect res={x,y,width,height}; return res; }
XADEXTERN SWFRect SWFParseRect(CSHandle *fh);
XADEXTERN void SWFWriteRect(SWFRect rect,CSHandle *fh);

static inline SWFMatrix SWFMakeMatrix(int a00,int a01,int a02,int a10,int a11,int a12) { SWFMatrix res={a00,a01,a02,a10,a11,a12}; return res; }
static inline SWFMatrix SWFTranslationMatrix(int x,int y) { return SWFMakeMatrix(1<<16,0,x,0,1<<16,y); }
XADEXTERN SWFMatrix SWFParseMatrix(CSHandle *fh);
XADEXTERN void SWFWriteMatrix(SWFMatrix mtx,CSHandle *fh);
XADEXTERN SWFMatrix SWFMultiplyMatrices(SWFMatrix a,SWFMatrix b);
XADEXTERN SWFMatrix SWFScalingMatrix(float x_scale,float y_scale);
XADEXTERN SWFMatrix SWFRotationMatrix(float degrees);

//SWFMatrix SWFMatrixFromAffineTransform(NSAffineTransform *t);
//NSAffineTransform *SWFAffineTransformFromMatrix(SWFMatrix m);

#define SWFZeroPoint SWFMakePoint(0,0)
#define SWFEmptyRect SWFMakeRect(0,0,0,0)
#define SWFIdentityMatrix SWFTranslationMatrix(0,0)

XADEXTERN int SWFCountBits(uint32_t val);
XADEXTERN int SWFCountBits2(uint32_t val1,uint32_t val2);
XADEXTERN int SWFCountBits4(uint32_t val1,uint32_t val2,uint32_t val3,uint32_t val4);
XADEXTERN int SWFCountSignedBits(int32_t val);
XADEXTERN int SWFCountSignedBits2(int32_t val1,int32_t val2);
XADEXTERN int SWFCountSignedBits4(int32_t val1,int32_t val2,int32_t val3,int32_t val4);
XADEXTERN int SWFCountSignedBitsPoint(SWFPoint point);
