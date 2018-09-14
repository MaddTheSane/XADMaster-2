#import "CSHandle.h"

@interface XADAppleDouble:NSObject
{
}

+(BOOL)parseAppleDoubleWithHandle:(CSHandle *)fh resourceForkOffset:(off_t *)resourceoffsetptr
resourceForkLength:(off_t *)resourcelengthptr extendedAttributes:(NSDictionary<NSString*,NSData*> **)extattrsptr;
+(void)parseAppleDoubleExtendedAttributesWithHandle:(CSHandle *)fh intoDictionary:(NSMutableDictionary<NSString*,NSData*> *)extattrs;

+(void)writeAppleDoubleHeaderToHandle:(CSHandle *)fh resourceForkSize:(int)ressize
extendedAttributes:(NSDictionary<NSString*,NSData*> *)extattrs;

@end

