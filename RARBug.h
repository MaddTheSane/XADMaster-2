/*
 * RARBug.h
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
#ifndef __RARBUG_H__
#define __RARBUG_H__

#include <stdbool.h>
#include "Crypto/sha.h"
#if defined(USE_COMMON_CRYPTO) && USE_COMMON_CRYPTO
#include <CommonCrypto/CommonDigest.h>
#endif

void SHA1_Update_WithRARBug(SHA_CTX *ctx,void *bytes,unsigned long length,int bug);

#if defined(USE_COMMON_CRYPTO) && USE_COMMON_CRYPTO
void CC_SHA1_Update_WithRARBug(CC_SHA1_CTX *ctx, const void *bytes, size_t length, bool bug);
#endif

#endif
