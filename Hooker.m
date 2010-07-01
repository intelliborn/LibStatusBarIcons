//
//  MethodSwizzle.m
//
//  Copyright (c) 2006 Tildesoft. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a
//  copy of this software and associated documentation files (the "Software"),
//  to deal in the Software without restriction, including without limitation
//  the rights to use, copy, modify, merge, publish, distribute, sublicense,
//  and/or sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
//  DEALINGS IN THE SOFTWARE.

// Implementation of Method Swizzling, inspired by
// http://www.cocoadev.com/index.pl?MethodSwizzling

// solves the inherited method problem

#import "Hooker.h"
#import <objc/objc-class.h>

#define SetNSError(ERROR_VAR, FORMAT,...)	\
	if (ERROR_VAR) {	\
		NSString *errStr = [@"error:]: " stringByAppendingFormat:FORMAT,##__VA_ARGS__];	\
		*ERROR_VAR = [NSError errorWithDomain:@"NSCocoaErrorDomain" \
										 code:-1	\
									 userInfo:[NSDictionary dictionaryWithObject:errStr forKey:NSLocalizedDescriptionKey]]; \
	}

@implementation NSObject (doWork)

+ (BOOL)insertHook:(SEL)origSel_ withMethod:(SEL)altSel_ error:(NSError**)error_ {

#if OBJC_API_VERSION >= 2
	Method origMethod = class_getInstanceMethod(self, origSel_);
	if (!origMethod) {
		NSLog(@"Couldn't find orig method %@ %@", NSStringFromSelector(origSel_), [self class]);
		SetNSError(error_, @"method %@ not found for class %@", NSStringFromSelector(origSel_), [self className]);
		return NO;
	}

	Method altMethod = class_getInstanceMethod(self, altSel_);
	if (!altMethod) {
		NSLog(@"Couldn't find alt method %@ %@", NSStringFromSelector(altSel_), [self class]);
		SetNSError(error_, @"alt method %@ not found for class %@", NSStringFromSelector(altSel_), [self className]);
		return NO;
	}

	class_addMethod(self,
					origSel_,
					class_getMethodImplementation(self, origSel_),
					method_getTypeEncoding(origMethod));
	class_addMethod(self,
					altSel_,
					class_getMethodImplementation(self, altSel_),
					method_getTypeEncoding(altMethod));

	method_exchangeImplementations(class_getInstanceMethod(self, origSel_), class_getInstanceMethod(self, altSel_));
	return YES;
#else
	//	Scan for non-inherited methods.
	Method directOriginalMethod = NULL, directAlternateMethod = NULL;

	void *iterator = NULL;
	struct objc_method_list *mlist = class_copyMethodList(self, &iterator);
	while (mlist) {
		int method_index = 0;
		for (; method_index < mlist->method_count; method_index++) {
			if (mlist->method_list[method_index].method_name == origSel_) {
				assert(!directOriginalMethod);
				directOriginalMethod = &mlist->method_list[method_index];
			}
			if (mlist->method_list[method_index].method_name == altSel_) {
				assert(!directAlternateMethod);
				directAlternateMethod = &mlist->method_list[method_index];
			}
		}
		free(mlist);
		mlist = class_copyMethodList(self, &iterator);
	}

	//	If either method is inherited, copy it up to the target class to make it non-inherited.
	if (!directOriginalMethod || !directAlternateMethod) {
		Method inheritedOriginalMethod = NULL, inheritedAlternateMethod = NULL;
		if (!directOriginalMethod) {
			inheritedOriginalMethod = class_getInstanceMethod(self, origSel_);
			if (!inheritedOriginalMethod) {
				SetNSError(error_, @"method %@ not found for class %@", NSStringFromSelector(origSel_), [self className]);
				return NO;
			}
		}
		if (!directAlternateMethod) {
			inheritedAlternateMethod = class_getInstanceMethod(self, altSel_);
			if (!inheritedAlternateMethod) {
				SetNSError(error_, @"alt method %@ not found for class %@", NSStringFromSelector(altSel_), [self className]);
				return NO;
			}
		}

		int hoisted_method_count = !directOriginalMethod && !directAlternateMethod ? 2 : 1;
		struct objc_method_list *hoisted_method_list = malloc(sizeof(struct objc_method_list) + (sizeof(struct objc_method)*(hoisted_method_count-1)));
		hoisted_method_list->method_count = hoisted_method_count;
		Method hoisted_method = hoisted_method_list->method_list;

		if (!directOriginalMethod) {
			bcopy(inheritedOriginalMethod, hoisted_method, sizeof(struct objc_method));
			directOriginalMethod = hoisted_method++;
		}
		if (!directAlternateMethod) {
			bcopy(inheritedAlternateMethod, hoisted_method, sizeof(struct objc_method));
			directAlternateMethod = hoisted_method;
		}
		class_addMethod(self, hoisted_method_list);
	}

	//	zle.
	IMP temp = directOriginalMethod->method_imp;
	directOriginalMethod->method_imp = directAlternateMethod->method_imp;
	directAlternateMethod->method_imp = temp;

	return YES;
#endif
}



+ (BOOL)insertHookStatic:(SEL)origSel_ withMethod:(SEL)altSel_ error:(NSError**)error_ {


	Method origMethod = class_getClassMethod(self, origSel_);
	if (!origMethod) {
	//NSLog(@"Couldn't find orig method");
		SetNSError(error_, @"method %@ not found for class %@", NSStringFromSelector(origSel_), [self className]);
		return NO;
	}

	Method altMethod = class_getClassMethod(self, altSel_);
	if (!altMethod) {
	//NSLog(@"Couldn't find alt method");
		SetNSError(error_, @"alt method %@ not found for class %@", NSStringFromSelector(altSel_), [self className]);
		return NO;
	}

	class_addMethod(self,
					origSel_,
					class_getMethodImplementation(self, origSel_),
					method_getTypeEncoding(origMethod));
	class_addMethod(self,
					altSel_,
					class_getMethodImplementation(self, altSel_),
					method_getTypeEncoding(altMethod));

	method_exchangeImplementations(class_getClassMethod(self, origSel_), class_getClassMethod(self, altSel_));
	return YES;

}
@end

