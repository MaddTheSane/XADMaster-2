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
