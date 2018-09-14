#import "CSBlockStreamHandle.h"

@interface XADStuffItDESHandle:CSBlockStreamHandle
{
	uint8_t block[8];
	uint32_t A,B,C,D;
}

+(NSData *)keyForPasswordData:(NSData *)passworddata entryKey:(NSData *)entrykey MKey:(NSData *)mkey;

-(instancetype)initWithHandle:(CSHandle *)handle key:(NSData *)keydata;
-(instancetype)initWithHandle:(CSHandle *)handle length:(off_t)length key:(NSData *)keydata;

-(int)produceBlockAtOffset:(off_t)pos;

@end
