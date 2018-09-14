#import "XADString.h"

#if !__has_feature(objc_arc)
#error this file needs to be compiled with Automatic Reference Counting (ARC)
#endif

@implementation XADString (PlatformSpecific)

+(NSString *)encodingNameForEncoding:(NSStringEncoding)encoding
{
	// Internal kludge: Don't actually return an NSString. Instead,
	// return an NSNumber containing the encoding number, that can
	// be quickly unpacked later. This should be safe, as the object
	// will not actually be touched by any other function than the
	// ones in XADStringCFString.
	return (NSString *)@(encoding);
}

+(NSStringEncoding)encodingForEncodingName:(NSString *)encoding
{
	if([encoding isKindOfClass:[NSNumber class]])
	{
		// If the encodingname is actually an NSNumber, just unpack it and convert.
		return ((NSNumber *)encoding).unsignedIntegerValue;
	}
	else
	{
		// Look up the encoding number for the name.
		return CFStringConvertEncodingToNSStringEncoding(
		CFStringConvertIANACharSetNameToEncoding((CFStringRef)encoding));
	}
}

+(CFStringEncoding)CFStringEncodingForEncodingName:(NSString *)encodingname
{
	if([encodingname isKindOfClass:[NSNumber class]])
	{
		// If the encodingname is actually an NSNumber, just unpack it and convert.
		return CFStringConvertNSStringEncodingToEncoding(((NSNumber *)encodingname).unsignedIntegerValue);
	}
	else
	{
		// Look up the encoding number for the name.
		return CFStringConvertIANACharSetNameToEncoding((CFStringRef)encodingname);
	}
}

+(BOOL)canDecodeData:(NSData *)data encodingName:(NSString *)encoding
{
	return [self canDecodeBytes:data.bytes length:data.length encodingName:encoding];
}

+(BOOL)canDecodeBytes:(const void *)bytes length:(size_t)length encodingName:(NSString *)encoding
{
	CFStringEncoding cfenc=[XADString CFStringEncodingForEncodingName:encoding];
	if(cfenc==kCFStringEncodingInvalidId) return NO;
	CFStringRef str=CFStringCreateWithBytes(kCFAllocatorDefault,bytes,length,cfenc,false);
	if(str) { CFRelease(str); return YES; }
	else return NO;
}

+(NSString *)stringForData:(NSData *)data encodingName:(NSString *)encoding
{
	NSStringEncoding enc = [self encodingForEncodingName:encoding];
	return [[NSString alloc] initWithData:data encoding:enc];
}

+(NSString *)stringForBytes:(const void *)bytes length:(size_t)length encodingName:(NSString *)encoding
{
	CFStringEncoding cfenc=[XADString CFStringEncodingForEncodingName:encoding];
	if(cfenc==kCFStringEncodingInvalidId) return nil;
	CFStringRef str=CFStringCreateWithBytes(kCFAllocatorDefault,bytes,length,cfenc,false);
	return CFBridgingRelease(str);
}

+(NSData *)dataForString:(NSString *)string encodingName:(NSString *)encoding
{
	NSInteger numchars=string.length;
	NSStringEncoding nsEnc = [self encodingForEncodingName:encoding];
	NSInteger numBytes = [string lengthOfBytesUsingEncoding:nsEnc];
	if (numBytes == 0 && numchars != 0) {
		return nil;
	}

	return [string dataUsingEncoding:nsEnc];
}

+(NSArray *)availableEncodingNames
{
	NSMutableArray *array=[NSMutableArray array];

	const CFStringEncoding *encodings=CFStringGetListOfAvailableEncodings();

	while(*encodings!=kCFStringEncodingInvalidId)
	{
		NSString *name=(NSString *)CFStringConvertEncodingToIANACharSetName(*encodings);
		NSString *description=[NSString localizedNameOfStringEncoding:CFStringConvertEncodingToNSStringEncoding(*encodings)];
		if(name)
		{
			[array addObject:@[description,name]];
		}
		encodings++;
	}

	return array;
}

@end
