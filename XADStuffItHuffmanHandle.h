#import "CSByteStreamHandle.h"
#import "XADPrefixCode.h"

@interface XADStuffItHuffmanHandle:CSByteStreamHandle
{
	XADPrefixCode *code;
}

-(instancetype)initWithHandle:(CSHandle *)handle;
-(instancetype)initWithHandle:(CSHandle *)handle length:(off_t)length;

-(void)resetByteStream;
-(void)parseTree;
-(uint8_t)produceByteAtOffset:(off_t)pos;

@end
