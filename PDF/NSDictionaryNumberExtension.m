#import "NSDictionaryNumberExtension.h"


@implementation NSDictionary (NumberExtension)

-(int)intValueForKey:(NSString *)key default:(int)def
{
	id obj=self[key];
	if(!obj||![obj isKindOfClass:[NSNumber class]]) return def;
	return [obj intValue];
}

-(unsigned int)unsignedIntValueForKey:(NSString *)key default:(unsigned int)def
{
	id obj=self[key];
	if(!obj||![obj isKindOfClass:[NSNumber class]]) return def;
	return [obj unsignedIntValue];
}

-(NSInteger)integerValueForKey:(NSString *)key default:(NSInteger)def
{
	id obj=self[key];
	if(!obj||![obj isKindOfClass:[NSNumber class]]) return def;
	return [obj integerValue];
}

-(NSUInteger)unsignedIntegerValueForKey:(NSString *)key default:(NSUInteger)def
{
	id obj=self[key];
	if(!obj||![obj isKindOfClass:[NSNumber class]]) return def;
	return [obj unsignedIntegerValue];
}

-(BOOL)boolValueForKey:(NSString *)key default:(BOOL)def
{
	id obj=self[key];
	if(!obj||![obj isKindOfClass:[NSNumber class]]) return def;
	return [obj boolValue];
}

-(float)floatValueForKey:(NSString *)key default:(float)def
{
	id obj=self[key];
	if(!obj||![obj isKindOfClass:[NSNumber class]]) return def;
	return [obj floatValue];
}

-(double)doubleValueForKey:(NSString *)key default:(double)def
{
	id obj=self[key];
	if(!obj||![obj isKindOfClass:[NSNumber class]]) return def;
	return [obj doubleValue];
}

-(NSString *)stringForKey:(NSString *)key default:(NSString *)def
{
	id obj=self[key];
	if(!obj||![obj isKindOfClass:[NSString class]]) return def;
	return obj;
}

-(NSArray *)arrayForKey:(NSString *)key
{
	id obj=self[key];
	if(!obj) return nil;
	else if([obj isKindOfClass:[NSArray class]]) return obj;
	else return @[obj];
}

@end
