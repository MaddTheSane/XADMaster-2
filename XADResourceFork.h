/*
 * XADResourceFork.h
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
#import <Foundation/NSObject.h>
#import "XADTypes.h"
#import "CSHandle.h"
#import "XADException.h"

NS_ASSUME_NONNULL_BEGIN

XADEXPORT
@interface XADResourceFork:NSObject
{
	NSDictionary<NSNumber*,NSDictionary<NSNumber*,NSDictionary<NSString*,id>*>*> *resources;
}

+(nullable instancetype)resourceForkWithHandle:(CSHandle *)handle NS_SWIFT_UNAVAILABLE("Call may throw, use `init(handle:) throws` instead");
+(nullable instancetype)resourceForkWithHandle:(CSHandle *)handle error:(nullable XADError *)errorptr;
+(nullable instancetype)resourceForkWithHandle:(CSHandle *)handle nserror:(NSError*__autoreleasing __nullable* __nullable)errorptr;

-(instancetype)init NS_DESIGNATED_INITIALIZER;

-(void)parseFromHandle:(CSHandle *)handle;
-(nullable NSData *)resourceDataForType:(uint32_t)type identifier:(int16_t)identifier;

-(nullable NSMutableDictionary<NSNumber*,NSData*> *)_parseResourceDataFromHandle:(CSHandle *)handle;
-(nullable NSDictionary<NSNumber*,NSDictionary<NSNumber*,NSDictionary<NSString*,id>*>*> *)_parseMapFromHandle:(CSHandle *)handle withDataObjects:(NSMutableDictionary<NSNumber*,NSData*> *)dataobjects;
-(nullable NSDictionary<NSNumber*, NSMutableDictionary<NSString*, id>*> *)_parseReferencesFromHandle:(CSHandle *)handle count:(int)count;

@end

NS_ASSUME_NONNULL_END
