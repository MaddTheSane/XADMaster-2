#import <Foundation/NSObject.h>
#import "CSHandle.h"
#import "XADException.h"

NS_ASSUME_NONNULL_BEGIN

@interface XADResourceFork:NSObject
{
	NSDictionary *resources;
}

+(nullable instancetype)resourceForkWithHandle:(CSHandle *)handle NS_SWIFT_UNAVAILABLE("Call may throw, use `init(handle:) throws` instead");
+(nullable instancetype)resourceForkWithHandle:(CSHandle *)handle error:(nullable XADError *)errorptr;
+(nullable instancetype)resourceForkWithHandle:(CSHandle *)handle nserror:(NSError*__autoreleasing __nullable* __nullable)errorptr;

-(instancetype)init NS_DESIGNATED_INITIALIZER;

-(void)parseFromHandle:(CSHandle *)handle;
-(nullable NSData *)resourceDataForType:(uint32_t)type identifier:(int)identifier;

-(nullable NSMutableDictionary<NSNumber*,NSData*> *)_parseResourceDataFromHandle:(CSHandle *)handle;
-(nullable NSDictionary<NSNumber*,NSDictionary<NSNumber*,id>*> *)_parseMapFromHandle:(CSHandle *)handle withDataObjects:(NSMutableDictionary<NSNumber*,NSData*> *)dataobjects;
-(nullable NSDictionary<NSNumber*, NSMutableDictionary<NSString*, id>*> *)_parseReferencesFromHandle:(CSHandle *)handle count:(int)count;

@end

NS_ASSUME_NONNULL_END
