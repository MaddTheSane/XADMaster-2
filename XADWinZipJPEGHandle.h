#import "CSBlockStreamHandle.h"

#import "WinZipJPEG/Decompressor.h"

@interface XADWinZipJPEGHandle:CSBlockStreamHandle
{
	WinZipJPEGDecompressor *decompressor;
	uint8_t buffer[65536];
}

-(instancetype)initWithHandle:(CSHandle *)handle length:(off_t)length;

-(void)resetBlockStream;
-(int)produceBlockAtOffset:(off_t)pos;

@end

