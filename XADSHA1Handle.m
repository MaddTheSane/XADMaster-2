/*
 * XADSHA1Handle.m
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
#import "XADSHA1Handle.h"
#if defined(USE_COMMON_CRYPTO) && USE_COMMON_CRYPTO
#include <CommonCrypto/CommonDigest.h>
typedef CC_SHA1_CTX XADSHA1;
#define XADSHA1_Init CC_SHA1_Init
#define XADSHA1_Update CC_SHA1_Update
#define XADSHA1_Final CC_SHA1_Final
#define XADSHA1_DIGEST_LENGTH CC_SHA1_DIGEST_LENGTH
#else
#include "Crypto/sha.h"
typedef SHA_CTX XADSHA1;
#define XADSHA1_Init SHA1_Init
#define XADSHA1_Update SHA1_Update
#define XADSHA1_Final SHA1_Final
#define XADSHA1_DIGEST_LENGTH SHA1_DIGEST_LENGTH
#endif

@implementation XADSHA1Handle
{
	NSData *digest;
	
	XADSHA1 context;
}

-(id)initWithHandle:(CSHandle *)handle length:(off_t)length correctDigest:(NSData *)correctdigest;
{
	if((self=[super initWithParentHandle:handle length:length]))
	{
		digest=[correctdigest copy];
	}
	return self;
}

-(void)resetStream
{
	XADSHA1_Init(&context);
	[parent seekToFileOffset:0];
}

-(int)streamAtMost:(int)num toBuffer:(void *)buffer
{
	int actual=[parent readAtMost:num toBuffer:buffer];
	XADSHA1_Update(&context,buffer,actual);
	return actual;
}

-(BOOL)hasChecksum { return YES; }

-(BOOL)isChecksumCorrect
{
	if(digest.length!=XADSHA1_DIGEST_LENGTH) return NO;

	XADSHA1 copy;
	copy=context;

	uint8_t buf[XADSHA1_DIGEST_LENGTH];
	XADSHA1_Final(buf,&copy);

	return memcmp(digest.bytes,buf,XADSHA1_DIGEST_LENGTH)==0;
}

-(double)estimatedProgress { return parent.estimatedProgress; }

@end


