/*
 * NSDictionaryNumberExtension.h
 *
 * Copyright (c) 2017-present, MacPaw Inc. All rights reserved.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
 * MA 02110-1301  USA
 */
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSDictionary<KeyType, ObjectType> (NumberExtension)

-(int)intValueForKey:(KeyType)key default:(int)def;
-(unsigned int)unsignedIntValueForKey:(KeyType)key default:(unsigned int)def;
-(NSInteger)integerValueForKey:(KeyType)key default:(NSInteger)def;
-(NSUInteger)unsignedIntegerValueForKey:(KeyType)key default:(NSUInteger)def;
-(BOOL)boolValueForKey:(KeyType)key default:(BOOL)def;
-(float)floatValueForKey:(KeyType)key default:(float)def;
-(double)doubleValueForKey:(KeyType)key default:(double)def;

-(NSString *)stringForKey:(KeyType)key default:(NSString *)def;
-(nullable NSArray *)arrayForKey:(KeyType)key;

@end

NS_ASSUME_NONNULL_END
