//
//  NSString+EscapeForJavaScript.m
//  ACEView
//
//  Created by Michael Robinson on 5/12/12.
//  Copyright (c) 2012 Code of Interest. All rights reserved.
//

#import "NSString+EscapeForJavaScript.h"

@implementation NSString (EscapeForJavaScript)

- (NSString *) stringByEscapingForJavaScript { NSError *e = nil;	NSString *jsonString;

	jsonString = [NSString.alloc initWithData: [NSJSONSerialization dataWithJSONObject:@[self] options:0 error:&e] encoding:NSUTF8StringEncoding];
	if (!jsonString && e) NSLog(@"Error JSONizing... %@", e);
    return [jsonString substringWithRange:NSMakeRange(2, jsonString.length - 4)];
}

- (NSString*)stringByPaddingTheLeftToLength:(NSUInteger)newLength  { NSString *ret = self.copy;

	for (int i = 0; i < self.length - newLength; i++) ret = [NSString stringWithFormat:@" %@", ret]; return ret;
}

- (NSString*) evaluateStringWithStringOrFile:(id)script { NSString *command = self.copy;

	BOOL isFile = NO;

	JSStringRef resultStringJS;
	CFStringRef resultString;
	NSError *e = nil;
	NSString *theScript = nil, *maybePath = nil;

	if ([script isKindOfClass:NSString.class] || [script isKindOfClass:NSURL.class]) {

		maybePath = [script isKindOfClass:NSURL.class] ? [script path] : script;
		isFile = [NSFileManager.defaultManager fileExistsAtPath:maybePath isDirectory:NULL];
		if (isFile)
		 theScript =[NSString stringWithContentsOfFile:maybePath encoding:NSUTF8StringEncoding error:&e];
	}
	theScript = theScript ?: [script isKindOfClass:NSString.class] ? script : nil;
	if (!theScript || e) return NSLog(@"error: %@", e), nil;

	theScript										= [theScript stringByAppendingString:command];
	JSGlobalContextRef ctx			= JSGlobalContextCreate(NULL);																	// Create JavaScript execution context.
	JSStringRef scriptJS				= JSStringCreateWithCFString((__bridge CFStringRef)theScript); 	// Evaluate script.
	JSValueRef result						= JSEvaluateScript(ctx, scriptJS, NULL, NULL, 0, NULL);
	JSStringRelease(scriptJS);

	if (result) resultStringJS	= JSValueToStringCopy(ctx, result, NULL);		// Convert result to string, unless result is NULL.

	resultString	= result ? JSStringCopyCFString(kCFAllocatorDefault, resultStringJS) : CFSTR("[Exception]");
	if (result)		 					 JSStringRelease(resultStringJS);
													 JSGlobalContextRelease(ctx);										// Release JavaScript execution context.
	return (__bridge NSString*)resultString;																// Return result.
}


@end
