#import "CSStreamHandle.h"

@interface XADRARInputHandle:CSStreamHandle
{
	NSArray *parts;

	int part;
	off_t partend;

	uint32_t crc,correctcrc;
}

-(instancetype)initWithHandle:(CSHandle *)handle parts:(NSArray *)partarray;

-(void)resetStream;
-(int)streamAtMost:(int)num toBuffer:(void *)buffer;

-(void)startNextPart;

@end
