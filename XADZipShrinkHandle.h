#import "CSByteStreamHandle.h"
#import "LZW.h"

@interface XADZipShrinkHandle:CSByteStreamHandle
{
	LZW *lzw;
	int symbolsize;

	int currbyte;
	uint8_t buffer[8192];
}

-(instancetype)initWithHandle:(CSHandle *)handle length:(off_t)length;

-(void)resetByteStream;
-(uint8_t)produceByteAtOffset:(off_t)pos;

@end
