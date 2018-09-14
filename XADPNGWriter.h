#import <Foundation/Foundation.h>

@interface XADPNGWriter:NSObject


+(instancetype)PNGWriter;

-(instancetype)init;

-(NSData *)data;

-(void)addIHDRWithWidth:(int)width height:(int)height bitDepth:(int)bitdepth
colourType:(int)colourtype;
-(void)addIEND;
-(void)addChunk:(uint32_t)chunktype bytes:(uint8_t *)bytes length:(int)length;

-(void)startIDAT;
-(void)addIDATRow:(uint8_t *)bytes;
-(void)endIDAT;

@end

