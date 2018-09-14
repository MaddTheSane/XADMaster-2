#import "CSSegmentedHandle.h"
#import "CSFileHandle.h"

NS_ASSUME_NONNULL_BEGIN

#define CSMultiFileHandle XADMultiFileHandle

@interface CSMultiFileHandle:CSSegmentedHandle
{
	NSArray<NSString*> *paths;
}

+(nullable CSHandle *)handleWithPathArray:(NSArray<NSString*> *)patharray;
+(nullable CSHandle *)handleWithPaths:(NSString *)firstpath,...;

// Initializers
-(nullable instancetype)initWithPaths:(NSArray<NSString*> *)patharray;
-(instancetype)initAsCopyOf:(CSMultiFileHandle *)other;

// Public methods
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSArray<NSString*> *paths;

// Implemented by this class
@property (NS_NONATOMIC_IOSONLY, readonly) NSInteger numberOfSegments;
-(off_t)segmentSizeAtIndex:(NSInteger)index;
-(CSHandle *)handleAtIndex:(NSInteger)index;

// Internal methods
-(void)_raiseError;

@end

NS_ASSUME_NONNULL_END
