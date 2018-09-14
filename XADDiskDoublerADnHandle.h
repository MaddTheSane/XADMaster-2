#import "CSBlockStreamHandle.h"

@interface XADDiskDoublerADnHandle:CSBlockStreamHandle
{
	uint8_t outbuffer[8192];
}

-(instancetype)initWithHandle:(CSHandle *)handle length:(off_t)length;

-(int)produceBlockAtOffset:(off_t)pos;

@end
