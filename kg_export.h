#ifndef __KG_EXPORT_DEFINE_H__
#define __KG_EXPORT_DEFINE_H__
#ifndef KG_EXPORT_API
#if defined(_WIN32) || defined(WIN32) || defined(__CYGWIN__) || defined(_WIN64) || defined(__WINDOWS__)
	#include <Windows.h>

	#pragma warning(disable:4290)
	#pragma warning(disable:4244)

	#ifdef KG_OS_WINDOWS
		#ifdef KG_DLL_EXPORT
			#define KG_EXPORT_API __declspec(dllexport)
		#else
//			#define KG_EXPORT_API __declspec(dllimport)
			#define KG_EXPORT_API
		#endif
	#else
		#define KG_EXPORT_API
	#endif

#else
	#if defined (__GNUC__)
		#define KG_EXPORT_API __attribute__((visibility("default")))
		#define KRC_DFAPI
	#else
		#define KG_EXPORT_API
		#define KRC_DFAPI
	#endif
#endif //_WINDOWS
#endif

#endif