#import "CSHandle.h"
#import "CSStreamHandle.h"
#import "CSZlibHandle.h"
#import "CSBzip2Handle.h"

@interface CSHandle (Progress)

@property (readonly) double estimatedProgress;

@end

@interface CSZlibHandle (Progress)

@property (readonly) double estimatedProgress;

@end

@interface CSStreamHandle (progress)

@property (readonly) double estimatedProgress;

@end

@interface CSBzip2Handle (progress)

@property (readonly) double estimatedProgress;

@end
