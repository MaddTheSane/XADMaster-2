/*
 * CSBzip2Handle.h
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

#define CSBzip2Handle XADBzip2Handle

extern NSExceptionName const CSBzip2Exception;
extern NSErrorDomain const CSBzip2ErrorDomain;

typedef NS_ERROR_ENUM(CSBzip2ErrorDomain, CSBzip2Error) {
	CSBzip2ErrorSequence = -1, //!< BZ_SEQUENCE_ERROR
	CSBzip2ErrorParameter = -2, //!< BZ_PARAM_ERROR
	CSBzip2ErrorMemory = -3, //!< BZ_MEM_ERROR
	CSBzip2ErrorData = -4, //!< BZ_DATA_ERROR
	CSBzip2ErrorInvalidMagic = -5, //!< BZ_DATA_ERROR_MAGIC
	CSBzip2ErrorIO = -6, //!< BZ_IO_ERROR
	CSBzip2ErrorUnexpectedEndOfFile = -7, //!< BZ_UNEXPECTED_EOF
	CSBzip2ErrorOutBufferFull = -8, //!< BZ_OUTBUFF_FULL
	CSBzip2ErrorConfiguration = -9 //!< BZ_CONFIG_ERROR
};

@interface CSBzip2Handle:CSStreamHandle

+(CSBzip2Handle *)bzip2HandleWithHandle:(CSHandle *)handle;
+(CSBzip2Handle *)bzip2HandleWithHandle:(CSHandle *)handle length:(off_t)length;

// Initializers.
-(instancetype)initWithHandle:(CSHandle *)handle length:(off_t)length;

// Implemented by this class.
-(void)resetStream;
-(int)streamAtMost:(int)num toBuffer:(void *)buffer;

// Checksum functions for XADMaster.
@property (NS_NONATOMIC_IOSONLY, readonly) BOOL hasChecksum;
@property (NS_NONATOMIC_IOSONLY, readonly, getter=isChecksumCorrect) BOOL checksumCorrect;

// Internal methods.
-(void)_raiseBzip2:(int)error NS_SWIFT_UNAVAILABLE("Call throws");

@end
