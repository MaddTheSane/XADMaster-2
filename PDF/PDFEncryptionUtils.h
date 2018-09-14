#import <Foundation/Foundation.h>
#import "../CSHandle.h"
#import "../CSBlockStreamHandle.h"

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

extern NSString *const PDFMD5FinishedException;



@interface PDFMD5Engine:NSObject
{
	XADMD5 md5;
	unsigned char digest_bytes[16];
	BOOL done;
}

+(instancetype)engine;
+(NSData *)digestForData:(NSData *)data;
+(NSData *)digestForBytes:(const void *)bytes length:(int)length;

-(instancetype)init;

-(void)updateWithData:(NSData *)data;
-(void)updateWithBytes:(const void *)bytes length:(unsigned long)length;

-(NSData *)digest;
-(NSString *)hexDigest;

-(NSString *)description;

@end




@interface PDFAESHandle:CSBlockStreamHandle
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

-(instancetype)initWithHandle:(CSHandle *)handle key:(NSData *)keydata;

-(void)resetBlockStream;
-(int)produceBlockAtOffset:(off_t)pos;

@end

