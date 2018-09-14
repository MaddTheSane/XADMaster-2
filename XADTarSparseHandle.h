#import "CSHandle.h"

typedef struct XADTarSparseRegion
{
	int nextRegion;
	off_t offset;
	off_t size;
	BOOL hasData;
	off_t dataOffset;
} XADTarSparseRegion;

@interface XADTarSparseHandle:CSHandle
{
	XADTarSparseRegion *regions;
	int numRegions;
	int currentRegion;
	off_t currentOffset;
	off_t realFileSize;
}

-(instancetype)initWithHandle:(CSHandle *)handle size:(off_t)size;
-(instancetype)initAsCopyOf:(XADTarSparseHandle *)other;

-(void)addSparseRegionFrom:(off_t)start length:(off_t)length;
-(void)addFinalSparseRegionEndingAt:(off_t)regionEndsAt;
-(void)setSingleEmptySparseRegion;

@property (NS_NONATOMIC_IOSONLY, readonly) off_t fileSize;
@property (NS_NONATOMIC_IOSONLY, readonly) off_t offsetInFile;
@property (NS_NONATOMIC_IOSONLY, readonly) BOOL atEndOfFile;

-(void)seekToFileOffset:(off_t)offs;
-(void)seekToEndOfFile;
-(int)readAtMost:(int)num toBuffer:(void *)buffer;

@end
