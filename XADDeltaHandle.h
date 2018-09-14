#import "CSByteStreamHandle.h"

@interface XADDeltaHandle:CSByteStreamHandle
{
	uint8_t deltabuffer[256];
	int distance;
}

-(instancetype)initWithHandle:(CSHandle *)handle;
-(instancetype)initWithHandle:(CSHandle *)handle length:(off_t)length;
-(instancetype)initWithHandle:(CSHandle *)handle deltaDistance:(int)deltadistance;
-(instancetype)initWithHandle:(CSHandle *)handle length:(off_t)length deltaDistance:(int)deltadistance;
-(instancetype)initWithHandle:(CSHandle *)handle propertyData:(NSData *)propertydata;
-(instancetype)initWithHandle:(CSHandle *)handle length:(off_t)length propertyData:(NSData *)propertydata;

-(void)resetByteStream;
-(uint8_t)produceByteAtOffset:(off_t)pos;

@end
