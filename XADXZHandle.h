#import "CSStreamHandle.h"

@interface XADXZHandle:CSStreamHandle
{
	CSHandle *currhandle;
	off_t startoffs;
	int state;
	BOOL checksumscorrect;
	int checksumflags;
	uint64_t crc;
}

-(instancetype)initWithHandle:(CSHandle *)handle;
-(instancetype)initWithHandle:(CSHandle *)handle length:(off_t)length;

-(void)resetStream;
-(int)streamAtMost:(int)num toBuffer:(void *)buffer;

-(BOOL)hasChecksum;
-(BOOL)isChecksumCorrect;
-(double)estimatedProgress;

@end
