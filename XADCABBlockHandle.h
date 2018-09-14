#import "CSBlockStreamHandle.h"
#import "XADCABBlockReader.h"


@interface XADCABBlockHandle:CSBlockStreamHandle
{
	XADCABBlockReader *blocks;
	uint8_t inbuffer[32768+6144];
}

-(instancetype)initWithBlockReader:(XADCABBlockReader *)blockreader;

-(void)resetBlockStream;
-(int)produceBlockAtOffset:(off_t)pos;

-(void)resetCABBlockHandle;
-(int)produceCABBlockWithInputBuffer:(uint8_t *)buffer length:(int)length atOffset:(off_t)pos length:(int)uncomplength;

@end

@interface XADCABCopyHandle:XADCABBlockHandle

-(int)produceCABBlockWithInputBuffer:(uint8_t *)buffer length:(int)length atOffset:(off_t)pos length:(int)uncomplength;

@end
