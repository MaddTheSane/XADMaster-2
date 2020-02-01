/*
 * PDFEncryptionUtils.m
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
#import "PDFEncryptionUtils.h"
#if defined(USE_COMMON_CRYPTO) && USE_COMMON_CRYPTO
#include <CommonCrypto/CommonCrypto.h>
#include <Security/Security.h>
typedef CC_MD5_CTX XADMD5;
#define XADMD5_Init CC_MD5_Init
#define XADMD5_Update CC_MD5_Update
#define XADMD5_Final CC_MD5_Final
#else
#import "../Crypto/md5.h"
#import "../Crypto/aes.h"
typedef MD5_CTX XADMD5;
#define XADMD5_Init MD5_Init
#define XADMD5_Update MD5_Update
#define XADMD5_Final MD5_Final
#endif

#import "../Crypto/aes.h"


NSString *const PDFMD5FinishedException=@"PDFMD5FinishedException";



@implementation PDFMD5Engine
{
	XADMD5 md5;
	unsigned char digest_bytes[16];
	BOOL done;
}

+(PDFMD5Engine *)engine { return [[self class] new]; }

+(NSData *)digestForData:(NSData *)data { return [self digestForBytes:data.bytes length:(int)data.length]; }

+(NSData *)digestForBytes:(const void *)bytes length:(int)length
{
	PDFMD5Engine *md5=[[self class] new];
	[md5 updateWithBytes:bytes length:length];
	NSData *res=[md5 digest];
	return res;
}

-(id)init
{
	if(self=[super init])
	{
		XADMD5_Init(&md5);
		done=NO;
	}
	return self;
}

-(void)updateWithData:(NSData *)data { [self updateWithBytes:data.bytes length:data.length]; }

-(void)updateWithBytes:(const void *)bytes length:(unsigned long)length
{
	if(done) [NSException raise:PDFMD5FinishedException format:@"Attempted to update a finished %@ object",[self class]];
	XADMD5_Update(&md5,bytes,(unsigned int)length);
}

-(NSData *)digest
{
	if(!done) { XADMD5_Final(digest_bytes,&md5); done=YES; }
	return [NSData dataWithBytes:digest_bytes length:16];
}

-(NSString *)hexDigest
{
	if(!done) { XADMD5_Final(digest_bytes,&md5); done=YES; }
	return [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
	digest_bytes[0],digest_bytes[1],digest_bytes[2],digest_bytes[3],
	digest_bytes[4],digest_bytes[5],digest_bytes[6],digest_bytes[7],
	digest_bytes[8],digest_bytes[9],digest_bytes[10],digest_bytes[11],
	digest_bytes[12],digest_bytes[13],digest_bytes[14],digest_bytes[15]];
}

-(NSString *)description
{
	if(done) return [NSString stringWithFormat:@"<%@ with digest %@>",[self class],[self hexDigest]];
	else return [NSString stringWithFormat:@"<%@, unfinished>",[self class]];
}

@end




@implementation PDFAESHandle
{
	off_t startoffs;
	
	NSData *key,*iv;
	
#if (defined(USE_COMMON_CRYPTO) && USE_COMMON_CRYPTO) && TARGET_OS_OSX
	SecKeyRef aeskey;
#else
	aes_decrypt_ctx aes;
#endif
	uint8_t ivbuffer[16],streambuffer[16];
}

-(id)initWithHandle:(CSHandle *)handle key:(NSData *)keydata
{
	if(self=[super initWithParentHandle:handle])
	{
		key=keydata;

		iv=[parent copyDataOfLength:16];
		startoffs=parent.offsetInFile;

		[self setBlockPointer:streambuffer];

#if (defined(USE_COMMON_CRYPTO) && USE_COMMON_CRYPTO) && TARGET_OS_OSX
		NSDictionary *keyStuff = @{(id)kSecAttrKeyType : (id)kSecAttrKeyTypeAES};
		aeskey = SecKeyCreateFromData((CFDictionaryRef)keyStuff, (CFDataRef)key, NULL);
#else
		aes_decrypt_key([key bytes],(int)[key length]*8,&aes);
#endif
	}
	return self;
}

-(void)dealloc
{
#if (defined(USE_COMMON_CRYPTO) && USE_COMMON_CRYPTO) && TARGET_OS_OSX
	CFRelease(aeskey);
#endif
}

-(void)resetBlockStream
{
	[parent seekToFileOffset:startoffs];
	memcpy(ivbuffer,[iv bytes],16);
}

-(int)produceBlockAtOffset:(off_t)pos
{
	uint8_t inbuf[16];
	[parent readBytes:16 toBuffer:inbuf];
#if (defined(USE_COMMON_CRYPTO) && USE_COMMON_CRYPTO) && TARGET_OS_OSX
	SecTransformRef decrypt = SecDecryptTransformCreate(aeskey, NULL);
	SecTransformSetAttribute(decrypt, kSecEncryptionMode, kSecModeCBCKey, NULL);
	SecTransformSetAttribute(decrypt, kSecIVKey, (CFDataRef)[NSData dataWithBytesNoCopy:ivbuffer length:16 freeWhenDone:NO], NULL);
	NSData *encData = [NSData dataWithBytes:inbuf length:sizeof(inbuf)];
	
	SecTransformSetAttribute(decrypt, kSecTransformInputAttributeName,
							 (CFDataRef)encData, NULL);
	
	NSData *decryptedData = CFBridgingRelease(SecTransformExecute(decrypt, NULL));
	[decryptedData getBytes:streambuffer length:16];
	CFRelease(decrypt);
	
#else
	
	aes_cbc_decrypt(inbuf,streambuffer,16,ivbuffer,&aes);
#endif

	if(parent.atEndOfFile)
	{
		[self endBlockStream];
		int val=streambuffer[15];
		if(val>0&&val<=16)
		{
			for(int i=1;i<val;i++) if(streambuffer[15-i]!=val) return 0;
			return 16-val;
		}
		else return 0;
	}
	else return 16;
}

@end

