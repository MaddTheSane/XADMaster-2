/*
 * CSInputBuffer.h
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

typedef struct CSInputBuffer
{
	__unsafe_unretained CSHandle *parent;
	off_t startoffs;
	BOOL eof;

	uint8_t *buffer;
	unsigned int bufsize,bufbytes,currbyte;

	uint32_t bits;
	unsigned int numbits;
} CSInputBuffer;



// Allocation and management

XADEXTERN CSInputBuffer *CSInputBufferAlloc(CSHandle *parent,int size);
XADEXTERN CSInputBuffer *CSInputBufferAllocWithBuffer(const uint8_t *buffer,int length,off_t startoffs);
XADEXTERN CSInputBuffer *CSInputBufferAllocEmpty(void);
XADEXTERN void CSInputBufferFree(CSInputBuffer *self);

XADEXTERN void CSInputSetMemoryBuffer(CSInputBuffer *self,uint8_t *buffer,int length,off_t startoffs);

static inline CSHandle *CSInputHandle(CSInputBuffer *self)
{
	return self->parent;
}



// Buffer and file positioning

XADEXTERN void CSInputRestart(CSInputBuffer *self);
XADEXTERN void CSInputFlush(CSInputBuffer *self);

XADEXTERN void CSInputSynchronizeFileOffset(CSInputBuffer *self);
XADEXTERN void CSInputSeekToFileOffset(CSInputBuffer *self,off_t offset);
XADEXTERN void CSInputSeekToBufferOffset(CSInputBuffer *self,off_t offset);
XADEXTERN void CSInputSetStartOffset(CSInputBuffer *self,off_t offset);
XADEXTERN off_t CSInputBufferOffset(CSInputBuffer *self);
XADEXTERN off_t CSInputFileOffset(CSInputBuffer *self);
XADEXTERN off_t CSInputBufferBitOffset(CSInputBuffer *self);

XADEXTERN void _CSInputFillBuffer(CSInputBuffer *self);




// Byte reading

#define CSInputBufferLookAhead 4

static inline void _CSInputBufferRaiseEOF(CSInputBuffer *self)
{
	if(self->parent) [self->parent _raiseEOF];
	else [NSException raise:CSEndOfFileException
	format:@"Attempted to read past the end of memory buffer."];
}

static inline int _CSInputBytesLeftInBuffer(CSInputBuffer *self)
{
	return self->bufbytes-self->currbyte;
}

static inline void _CSInputCheckAndFillBuffer(CSInputBuffer *self)
{
	if(!self->eof&&_CSInputBytesLeftInBuffer(self)<=CSInputBufferLookAhead) _CSInputFillBuffer(self);
}

static inline void CSInputSkipBytes(CSInputBuffer *self,int num)
{
	self->currbyte+=num;
}

static inline uint32_t _CSInputPeekByteWithoutEOF(CSInputBuffer *self,int offs)
{
	return self->buffer[self->currbyte+offs];
}

static inline int CSInputPeekByte(CSInputBuffer *self,int offs)
{
	_CSInputCheckAndFillBuffer(self);
	if(offs>=_CSInputBytesLeftInBuffer(self)) _CSInputBufferRaiseEOF(self);
	return _CSInputPeekByteWithoutEOF(self,offs);
}

static inline int CSInputNextByte(CSInputBuffer *self)
{
	int byte=CSInputPeekByte(self,0);
	CSInputSkipBytes(self,1);
	return byte;
}

static inline BOOL CSInputAtEOF(CSInputBuffer *self)
{
	_CSInputCheckAndFillBuffer(self);
	return _CSInputBytesLeftInBuffer(self)<=0;
}




// Bitstream reading

XADEXTERN void _CSInputFillBits(CSInputBuffer *self);
XADEXTERN void _CSInputFillBitsLE(CSInputBuffer *self);

XADEXTERN unsigned int CSInputNextBit(CSInputBuffer *self);
XADEXTERN unsigned int CSInputNextBitLE(CSInputBuffer *self);
XADEXTERN unsigned int CSInputNextBitString(CSInputBuffer *self,int numbits);
XADEXTERN unsigned int CSInputNextBitStringLE(CSInputBuffer *self,int numbits);
XADEXTERN unsigned int CSInputNextLongBitString(CSInputBuffer *self,int numbits);
XADEXTERN unsigned int CSInputNextLongBitStringLE(CSInputBuffer *self,int numbits);

XADEXTERN void CSInputSkipBits(CSInputBuffer *self,int numbits);
XADEXTERN void CSInputSkipBitsLE(CSInputBuffer *self,int numbits);
XADEXTERN BOOL CSInputOnByteBoundary(CSInputBuffer *self);
XADEXTERN void CSInputSkipToByteBoundary(CSInputBuffer *self);
XADEXTERN void CSInputSkipTo16BitBoundary(CSInputBuffer *self);

static inline unsigned int CSInputBitsLeftInBuffer(CSInputBuffer *self)
{
	_CSInputCheckAndFillBuffer(self);
	return _CSInputBytesLeftInBuffer(self)*8+(self->numbits&7);
}

static inline void _CSInputCheckAndFillBits(CSInputBuffer *self,int numbits)
{
	if(numbits>self->numbits) _CSInputFillBits(self);
}

static inline void _CSInputCheckAndFillBitsLE(CSInputBuffer *self,int numbits)
{
	if(numbits>self->numbits) _CSInputFillBitsLE(self);
}

static inline unsigned int CSInputPeekBitString(CSInputBuffer *self,int numbits)
{
	if(numbits==0) return 0;
	_CSInputCheckAndFillBits(self,numbits);
	return self->bits>>(32-numbits);
}

static inline unsigned int CSInputPeekBitStringLE(CSInputBuffer *self,int numbits)
{
	if(numbits==0) return 0;
	_CSInputCheckAndFillBitsLE(self,numbits);
	return self->bits&((1<<numbits)-1);
}

static inline void CSInputSkipPeekedBits(CSInputBuffer *self,int numbits)
{
	int numbytes=(numbits-(self->numbits&7)+7)>>3;
	CSInputSkipBytes(self,numbytes);

	if(_CSInputBytesLeftInBuffer(self)<0) _CSInputBufferRaiseEOF(self);

	self->bits<<=numbits;
	self->numbits-=numbits;
}

static inline void CSInputSkipPeekedBitsLE(CSInputBuffer *self,int numbits)
{
	int numbytes=(numbits-(self->numbits&7)+7)>>3;
	CSInputSkipBytes(self,numbytes);

	if(_CSInputBytesLeftInBuffer(self)<0) _CSInputBufferRaiseEOF(self);

	self->bits>>=numbits;
	self->numbits-=numbits;
}




// Multibyte reading

#define CSInputNextValueImpl(type,name,conv) \
static inline type name(CSInputBuffer *self) \
{ \
	_CSInputCheckAndFillBuffer(self); \
	type val=conv(self->buffer+self->currbyte); \
	CSInputSkipBytes(self,sizeof(type)); \
	return val; \
}

CSInputNextValueImpl(int16_t,CSInputNextInt16LE,CSInt16LE)
CSInputNextValueImpl(int32_t,CSInputNextInt32LE,CSInt32LE)
CSInputNextValueImpl(uint16_t,CSInputNextUInt16LE,CSUInt16LE)
CSInputNextValueImpl(uint32_t,CSInputNextUInt32LE,CSUInt32LE)
CSInputNextValueImpl(int16_t,CSInputNextInt16BE,CSInt16BE)
CSInputNextValueImpl(int32_t,CSInputNextInt32BE,CSInt32BE)
CSInputNextValueImpl(uint16_t,CSInputNextUInt16BE,CSUInt16BE)
CSInputNextValueImpl(uint32_t,CSInputNextUInt32BE,CSUInt32BE)




