#import "XADFastLZSSHandle.h"
#import "XADPrefixCode.h"

@interface XADStacLZSHandle:XADFastLZSSHandle
{
	XADPrefixCode *lengthcode;
	int extralength,extraoffset;
}

-(instancetype)initWithHandle:(CSHandle *)handle;
-(instancetype)initWithHandle:(CSHandle *)handle length:(off_t)length;

-(void)resetLZSSHandle;
-(void)expandFromPosition:(off_t)pos;

@end
