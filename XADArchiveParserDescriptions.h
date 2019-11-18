/*
 * XADArchiveParserDescriptions.h
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
#import "XADArchiveParser.h"
#import "XADTypes.h"

NS_ASSUME_NONNULL_BEGIN

@interface XADArchiveParser (Descriptions)

+ (nullable NSString *)descriptionOfValueInDictionary:(NSDictionary<XADArchiveKeys,id> *)dict key:(XADArchiveKeys)key;
+ (NSString *)descriptionOfKey:(XADArchiveKeys)key;
+ (NSArray<XADArchiveKeys> *)descriptiveOrderingOfKeysInDictionary:(NSDictionary<XADArchiveKeys,id> *)dict;

-(nullable NSString *)descriptionOfValueInDictionary:(NSDictionary<XADArchiveKeys,id> *)dict key:(XADArchiveKeys)key;
-(NSString *)descriptionOfKey:(XADArchiveKeys)key;
-(NSArray<XADArchiveKeys> *)descriptiveOrderingOfKeysInDictionary:(NSDictionary<XADArchiveKeys,id> *)dict;

@end

XADEXTERN NSString *XADHumanReadableFileSize(uint64_t size);
XADEXTERN NSString *XADShortHumanReadableFileSize(uint64_t size);
XADEXTERN NSString *XADHumanReadableBoolean(uint64_t boolean);
XADEXTERN NSString *XADHumanReadablePOSIXPermissions(uint64_t permissions);
XADEXTERN NSString *XADHumanReadableAmigaProtectionBits(uint64_t protection);
XADEXTERN NSString *XADHumanReadableDOSFileAttributes(uint64_t attributes);
XADEXTERN NSString *XADHumanReadableWindowsFileAttributes(uint64_t attributes);
XADEXTERN NSString *XADHumanReadableOSType(uint32_t ostype);
XADEXTERN NSString *XADHumanReadableEntryWithDictionary(NSDictionary<XADArchiveKeys,id> *dict,XADArchiveParser *parser);

XADEXTERN NSString *XADHumanReadableObject(id object);
XADEXTERN NSString *XADHumanReadableDate(NSDate *date);
XADEXTERN NSString *XADHumanReadableData(NSData *data);
XADEXTERN NSString *XADHumanReadableArray(NSArray *array);
XADEXTERN NSString *XADHumanReadableDictionary(NSDictionary<NSString*,id> *dict);
XADEXTERN NSString *XADHumanReadableList(NSArray<NSString*> *labels,NSArray<NSString*> *values);
XADEXTERN NSString *XADIndentTextWithSpaces(NSString *text,NSInteger spaces);

NS_ASSUME_NONNULL_END
