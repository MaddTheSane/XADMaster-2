#import "XADFastLZSSHandle.h"
#import "XADPrefixCode.h"

@interface XADARCDistillHandle:XADFastLZSSHandle
{
	XADPrefixCode *maincode,*offsetcode;
}

-(instancetype)initWithHandle:(CSHandle *)handle;
-(instancetype)initWithHandle:(CSHandle *)handle length:(off_t)length;

-(void)resetLZSSHandle;
-(void)expandFromPosition:(off_t)pos;

@end
