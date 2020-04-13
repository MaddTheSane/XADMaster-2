//
//  XADTypes.h
//  XADMaster
//
//  Created by C.W. Betts on 9/15/18.
//

#ifndef XADTypes_h
#define XADTypes_h

#ifndef XADEXPORT
# if defined(__WIN32__) || defined(__WINRT__)
#  ifdef __BORLANDC__
#   ifdef BUILD_XADMASTER
#    define XADEXPORT
#   else
#    define XADEXPORT	__declspec(dllimport)
#   endif
#  else
#   define XADEXPORT __declspec(dllexport)
#  endif
# else
#  if defined(__GNUC__) && __GNUC__ >= 4
#   define XADEXPORT __attribute__ ((visibility("default")))
#  else
#   define XADEXPORT
#  endif
# endif
#endif

#define XADEXTERN extern XADEXPORT

#ifndef NS_TYPED_ENUM
#define NS_TYPED_ENUM
#endif

#ifndef NS_SWIFT_NAME
#define NS_SWIFT_NAME(...)
#endif

#ifndef NS_REFINED_FOR_SWIFT
#define NS_REFINED_FOR_SWIFT
#endif

#ifndef NS_NONATOMIC_IOSONLY
#define NS_NONATOMIC_IOSONLY atomic
#endif

#ifndef NS_DESIGNATED_INITIALIZER
#define NS_DESIGNATED_INITIALIZER
#endif

#ifndef DEPRECATED_ATTRIBUTE
#if defined(__has_feature) && defined(__has_attribute)
    #if __has_attribute(deprecated)
        #define DEPRECATED_ATTRIBUTE        __attribute__((deprecated))
        #if __has_feature(attribute_deprecated_with_message)
            #define DEPRECATED_MSG_ATTRIBUTE(s) __attribute__((deprecated(s)))
        #else
            #define DEPRECATED_MSG_ATTRIBUTE(s) __attribute__((deprecated))
        #endif
    #else
        #define DEPRECATED_ATTRIBUTE
        #define DEPRECATED_MSG_ATTRIBUTE(s)
    #endif
#elif defined(__GNUC__) && ((__GNUC__ >= 4) || ((__GNUC__ == 3) && (__GNUC_MINOR__ >= 1)))
    #define DEPRECATED_ATTRIBUTE        __attribute__((deprecated))
    #if (__GNUC__ >= 5) || ((__GNUC__ == 4) && (__GNUC_MINOR__ >= 5))
        #define DEPRECATED_MSG_ATTRIBUTE(s) __attribute__((deprecated(s)))
    #else
        #define DEPRECATED_MSG_ATTRIBUTE(s) __attribute__((deprecated))
    #endif
#else
    #define DEPRECATED_ATTRIBUTE
    #define DEPRECATED_MSG_ATTRIBUTE(s)
#endif
#endif

#ifndef API_DEPRECATED_WITH_REPLACEMENT
#define API_DEPRECATED_WITH_REPLACEMENT(...) DEPRECATED_ATTRIBUTE
#endif

#endif /* XADTypes_h */
