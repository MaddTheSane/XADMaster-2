/*
 * CSHandle.h
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
#include <stdint.h>
#import "XADTypes.h"
#import "ClangAnalyser.h"


#define CSHandleMaxLength 0x7fffffffffffffffll
#define CSHandle XADHandle


// Kludge 64-bit support for Mingw. TODO: Should this be used on Linux too?
#if defined(__MINGW32__) && !defined(__CYGWIN__)
#include <unistd.h>
#include <fcntl.h>
#define off_t off64_t
#define fseeko fseeko64
#define lseek lseek64
#define ftello ftello64
#endif

NS_ASSUME_NONNULL_BEGIN

XADEXTERN NSExceptionName const CSOutOfMemoryException;
XADEXTERN NSExceptionName const CSEndOfFileException;
XADEXTERN NSExceptionName const CSNotImplementedException;
XADEXTERN NSExceptionName const CSNotSupportedException;


XADEXPORT
@interface CSHandle:NSObject <NSCopying>
{
	CSHandle *parent;
	off_t bitoffs;
	uint8_t readbyte,readbitsleft;
	uint8_t writebyte,writebitsleft;
}

-(instancetype)init;
-(instancetype)initWithParentHandle:(CSHandle *)parenthandle;
-(instancetype)initAsCopyOf:(CSHandle *)other;
-(void)close;

// Methods implemented by subclasses

@property (NS_NONATOMIC_IOSONLY, readonly) off_t fileSize;
@property (NS_NONATOMIC_IOSONLY, readonly) off_t offsetInFile;
@property (NS_NONATOMIC_IOSONLY, readonly) BOOL atEndOfFile;

-(void)seekToFileOffset:(off_t)offs;
-(void)seekToEndOfFile;
-(void)pushBackByte:(int)byte;
-(int)readAtMost:(int)num toBuffer:(void *)buffer;
-(void)writeBytes:(int)num fromBuffer:(const void *)buffer;



// Utility methods

-(void)skipBytes:(off_t)bytes;

-(int8_t)readInt8;
-(uint8_t)readUInt8;

-(int16_t)readInt16BE;
-(int32_t)readInt32BE;
-(int64_t)readInt64BE;
-(uint16_t)readUInt16BE;
-(uint32_t)readUInt32BE;
-(uint64_t)readUInt64BE;

-(int16_t)readInt16LE;
-(int32_t)readInt32LE;
-(int64_t)readInt64LE;
-(uint16_t)readUInt16LE;
-(uint32_t)readUInt32LE;
-(uint64_t)readUInt64LE;

-(int16_t)readInt16InBigEndianOrder:(BOOL)isbigendian;
-(int32_t)readInt32InBigEndianOrder:(BOOL)isbigendian;
-(int64_t)readInt64InBigEndianOrder:(BOOL)isbigendian;
-(uint16_t)readUInt16InBigEndianOrder:(BOOL)isbigendian;
-(uint32_t)readUInt32InBigEndianOrder:(BOOL)isbigendian;
-(uint64_t)readUInt64InBigEndianOrder:(BOOL)isbigendian;

-(uint32_t)readID;

-(uint32_t)readBits:(int)bits;
-(uint32_t)readBitsLE:(int)bits;
-(int32_t)readSignedBits:(int)bits;
-(int32_t)readSignedBitsLE:(int)bits;
-(void)flushReadBits;

-(NSData *)readLine;
-(nullable NSString *)readLineWithEncoding:(NSStringEncoding)encoding;
-(nullable NSString *)readUTF8Line;

-(NSData *)fileContents NS_SWIFT_UNAVAILABLE("Call can throw exception");
-(NSData *)remainingFileContents NS_SWIFT_UNAVAILABLE("Call can throw exception");
-(NSData *)readDataOfLength:(int)length NS_SWIFT_UNAVAILABLE("Call can throw exception");
-(NSData *)readDataOfLengthAtMost:(int)length NS_SWIFT_UNAVAILABLE("Call can throw exception");
-(NSData *)copyDataOfLength:(int)length NS_SWIFT_UNAVAILABLE("Call can throw exception");
-(NSData *)copyDataOfLengthAtMost:(int)length NS_SWIFT_UNAVAILABLE("Call can throw exception");
-(void)readBytes:(int)num toBuffer:(void *)buffer NS_SWIFT_UNAVAILABLE("Call can throw exception");

-(off_t)readAndDiscardAtMost:(off_t)num NS_SWIFT_UNAVAILABLE("Call can throw exception");
-(void)readAndDiscardBytes:(off_t)num NS_SWIFT_UNAVAILABLE("Call can throw exception");

-(CSHandle *)subHandleOfLength:(off_t)length;
-(CSHandle *)subHandleFrom:(off_t)start length:(off_t)length;
-(CSHandle *)subHandleToEndOfFileFrom:(off_t)start;
-(CSHandle *)nonCopiedSubHandleOfLength:(off_t)length;
-(CSHandle *)nonCopiedSubHandleFrom:(off_t)start length:(off_t)length;
-(CSHandle *)nonCopiedSubHandleToEndOfFileFrom:(off_t)start;

-(void)writeInt8:(int8_t)val;
-(void)writeUInt8:(uint8_t)val;

-(void)writeInt16BE:(int16_t)val;
-(void)writeInt32BE:(int32_t)val;
//-(void)writeInt64BE:(int64_t)val;
-(void)writeUInt16BE:(uint16_t)val;
-(void)writeUInt32BE:(uint32_t)val;
//-(void)writeUInt64BE:(uint64_t)val;

-(void)writeInt16LE:(int16_t)val;
-(void)writeInt32LE:(int32_t)val;
-(void)writeInt64LE:(int64_t)val;
-(void)writeUInt16LE:(uint16_t)val;
-(void)writeUInt32LE:(uint32_t)val;
-(void)writeUInt64LE:(uint64_t)val;

-(void)writeID:(uint32_t)val;

-(void)writeBits:(int)bits value:(uint32_t)val;
-(void)writeSignedBits:(int)bits value:(int32_t)val;
-(void)flushWriteBits;

-(void)writeData:(NSData *)data;

//-(void)_raiseClosed;
-(void)_raiseMemory NS_SWIFT_UNAVAILABLE("Call throws exception") CLANG_ANALYZER_NORETURN;
-(void)_raiseEOF NS_SWIFT_UNAVAILABLE("Call throws exception") CLANG_ANALYZER_NORETURN;
-(void)_raiseNotImplemented:(SEL)selector NS_SWIFT_UNAVAILABLE("Call throws exception") CLANG_ANALYZER_NORETURN;
-(void)_raiseNotSupported:(SEL)selector NS_SWIFT_UNAVAILABLE("Call throws exception") CLANG_ANALYZER_NORETURN;

@property (NS_NONATOMIC_IOSONLY, readonly, copy, nullable) NSString *name;
@property (NS_NONATOMIC_IOSONLY, strong, nullable) CSHandle *parentHandle;

@end

@interface CSHandle (NSErrorMethods)
#pragma mark - NSError data reading methods
-(nullable NSData *)fileContentsWithError:(NSError**)error;
-(nullable NSData *)remainingFileContentsWithError:(NSError**)error;
-(nullable NSData *)readDataOfLength:(int)length error:(NSError**)error;
-(nullable NSData *)readDataOfLengthAtMost:(int)length error:(NSError**)error;
-(nullable NSData *)copyDataOfLength:(int)length error:(NSError**)error;
-(nullable NSData *)copyDataOfLengthAtMost:(int)length error:(NSError**)error;
-(BOOL)readBytes:(int)num toBuffer:(void *)buffer error:(NSError**)error;

-(off_t)readAndDiscardAtMost:(off_t)num error:(NSError**)error NS_REFINED_FOR_SWIFT;
-(BOOL)readAndDiscardBytes:(off_t)num error:(NSError**)error;

#pragma mark -
@end

static inline int16_t CSInt16BE(const uint8_t *b) { return ((int16_t)b[0]<<8)|(int16_t)b[1]; }
static inline int32_t CSInt32BE(const uint8_t *b) { return ((int32_t)b[0]<<24)|((int32_t)b[1]<<16)|((int32_t)b[2]<<8)|(int32_t)b[3]; }
static inline int64_t CSInt64BE(const uint8_t *b) { return ((int64_t)b[0]<<56)|((int64_t)b[1]<<48)|((int64_t)b[2]<<40)|((int64_t)b[3]<<32)|((int64_t)b[4]<<24)|((int64_t)b[5]<<16)|((int64_t)b[6]<<8)|(int64_t)b[7]; }
static inline uint16_t CSUInt16BE(const uint8_t *b) { return ((uint16_t)b[0]<<8)|(uint16_t)b[1]; }
static inline uint32_t CSUInt32BE(const uint8_t *b) { return ((uint32_t)b[0]<<24)|((uint32_t)b[1]<<16)|((uint32_t)b[2]<<8)|(uint32_t)b[3]; }
static inline uint64_t CSUInt64BE(const uint8_t *b) { return ((uint64_t)b[0]<<56)|((uint64_t)b[1]<<48)|((uint64_t)b[2]<<40)|((uint64_t)b[3]<<32)|((uint64_t)b[4]<<24)|((uint64_t)b[5]<<16)|((uint64_t)b[6]<<8)|(uint64_t)b[7]; }
static inline int16_t CSInt16LE(const uint8_t *b) { return ((int16_t)b[1]<<8)|(int16_t)b[0]; }
static inline int32_t CSInt32LE(const uint8_t *b) { return ((int32_t)b[3]<<24)|((int32_t)b[2]<<16)|((int32_t)b[1]<<8)|(int32_t)b[0]; }
static inline int64_t CSInt64LE(const uint8_t *b) { return ((int64_t)b[7]<<56)|((int64_t)b[6]<<48)|((int64_t)b[5]<<40)|((int64_t)b[4]<<32)|((int64_t)b[3]<<24)|((int64_t)b[2]<<16)|((int64_t)b[1]<<8)|(int64_t)b[0]; }
static inline uint16_t CSUInt16LE(const uint8_t *b) { return ((uint16_t)b[1]<<8)|(uint16_t)b[0]; }
static inline uint32_t CSUInt32LE(const uint8_t *b) { return ((uint32_t)b[3]<<24)|((uint32_t)b[2]<<16)|((uint32_t)b[1]<<8)|(uint32_t)b[0]; }
static inline uint64_t CSUInt64LE(const uint8_t *b) { return ((uint64_t)b[7]<<56)|((uint64_t)b[6]<<48)|((uint64_t)b[5]<<40)|((uint64_t)b[4]<<32)|((uint64_t)b[3]<<24)|((uint64_t)b[2]<<16)|((uint64_t)b[1]<<8)|(uint64_t)b[0]; }

static inline void CSSetInt16BE(uint8_t *b,int16_t n) { b[0]=(n>>8)&0xff; b[1]=n&0xff; }
static inline void CSSetInt32BE(uint8_t *b,int32_t n) { b[0]=(n>>24)&0xff; b[1]=(n>>16)&0xff; b[2]=(n>>8)&0xff; b[3]=n&0xff; }
static inline void CSSetUInt16BE(uint8_t *b,uint16_t n) { b[0]=(n>>8)&0xff; b[1]=n&0xff; }
static inline void CSSetUInt32BE(uint8_t *b,uint32_t n) { b[0]=(n>>24)&0xff; b[1]=(n>>16)&0xff; b[2]=(n>>8)&0xff; b[3]=n&0xff; }
static inline void CSSetInt16LE(uint8_t *b,int16_t n) { b[1]=(n>>8)&0xff; b[0]=n&0xff; }
static inline void CSSetInt32LE(uint8_t *b,int32_t n) { b[3]=(n>>24)&0xff; b[2]=(n>>16)&0xff; b[1]=(n>>8)&0xff; b[0]=n&0xff; }
static inline void CSSetInt64LE(uint8_t *b,int64_t n) { b[7]=(n>>56)&0xff; b[6]=(n>>48)&0xff; b[5]=(n>>40)&0xff; b[4]=(n>>32)&0xff; b[3]=(n>>24)&0xff; b[2]=(n>>16)&0xff; b[1]=(n>>8)&0xff; b[0]=(n>>0)&0xff;}
static inline void CSSetUInt16LE(uint8_t *b,uint16_t n) { b[1]=(n>>8)&0xff; b[0]=n&0xff; }
static inline void CSSetUInt32LE(uint8_t *b,uint32_t n) { b[3]=(n>>24)&0xff; b[2]=(n>>16)&0xff; b[1]=(n>>8)&0xff; b[0]=n&0xff; }
static inline void CSSetUInt64LE(uint8_t *b,uint64_t n) { b[7]=(n>>56)&0xff; b[6]=(n>>48)&0xff; b[5]=(n>>40)&0xff; b[4]=(n>>32)&0xff; b[3]=(n>>24)&0xff; b[2]=(n>>16)&0xff; b[1]=(n>>8)&0xff; b[0]=(n>>0)&0xff;}


NS_ASSUME_NONNULL_END
