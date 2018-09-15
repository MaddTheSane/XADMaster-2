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

#endif /* XADTypes_h */
