#import "PDFEncryptionUtils.h"

NSString *const PDFMD5FinishedException=@"PDFMD5FinishedException";



@implementation PDFMD5Engine

+(PDFMD5Engine *)engine { return [[[self class] new] autorelease]; }

+(NSData *)digestForData:(NSData *)data { return [self digestForBytes:data.bytes length:(int)data.length]; }

+(NSData *)digestForBytes:(const void *)bytes length:(int)length
{
	PDFMD5Engine *md5=[[self class] new];
	[md5 updateWithBytes:bytes length:length];
	NSData *res=[md5 digest];
	[md5 release];
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

-(id)initWithHandle:(CSHandle *)handle key:(NSData *)keydata
{
	if(self=[super initWithParentHandle:handle])
	{
		key=[keydata retain];

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
	[key release];
	[iv release];
#if (defined(USE_COMMON_CRYPTO) && USE_COMMON_CRYPTO) && TARGET_OS_OSX
	CFRelease(aeskey);
#endif
	[super dealloc];
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

