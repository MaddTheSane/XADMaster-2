#import "CSStreamHandle.h"

@interface XADStuffItXBlendHandle:CSStreamHandle
{
	CSHandle *currhandle;
	CSInputBuffer *currinput;
}

-(instancetype)initWithHandle:(CSHandle *)handle length:(off_t)length;

-(void)resetStream;
-(int)streamAtMost:(int)num toBuffer:(void *)buffer;

@end
