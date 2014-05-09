//
//  NSString+EscapeForJavaScript.m
//  ACEView
//
//  Created by Michael Robinson on 5/12/12.
//  Copyright (c) 2012 Code of Interest. All rights reserved.
//

#import "NSString+JS.h"

@implementation NSString (AtoZJSFierceness)

- (NSString*) stringByEscapingForJavaScript                     { NSError *e = nil;

	NSString *jsonString = [NSString.alloc initWithData:
              [NSJSONSerialization dataWithJSONObject:@[self] options:0
                                                error:&e]    encoding:NSUTF8StringEncoding];
	return !jsonString && e ? NSLog(@"Error JSONizing... %@", e), (id)nil :
         [jsonString substringWithRange:NSMakeRange(2, jsonString.length - 4)];
}
- (NSString*) stringByPaddingTheLeftToLength:(NSUInteger)newL   { NSString *ret = self.copy;

	for (int i = 0; i < self.length - newL; i++)
    ret = [NSString stringWithFormat:@" %@", ret]; return ret;
}
- (NSString*) evaluateStringWithStringOrFile:(id)script         {

	BOOL isFile = NO;	JSStringRef resultStringJS;	CFStringRef resultString;	NSError *e = nil;

	NSString *theScript, *maybePath, *command = self.copy;

	theScript = [script isKindOfClass:NSString.class] || [script isKindOfClass:NSURL.class] ? ({

		maybePath = [script isKindOfClass:NSURL.class] ? [script path] : script;
		(isFile   = [NSFileManager.defaultManager fileExistsAtPath:maybePath isDirectory:NULL]) ?
                [NSString stringWithContentsOfFile:maybePath encoding:NSUTF8StringEncoding error:&e] : nil;
	}) : nil;
	theScript = theScript ?: [script isKindOfClass:NSString.class] ? script : nil;
	if (!theScript || e) return NSLog(@"error: %@", e), nil;

	theScript										= [theScript stringByAppendingString:command];
	JSGlobalContextRef ctx			= JSGlobalContextCreate(NULL);                                  // Create JS execution ctx.
	JSStringRef scriptJS				= JSStringCreateWithCFString((__bridge CFStringRef)theScript);  // Evaluate script.
	JSValueRef result						= JSEvaluateScript(ctx, scriptJS, NULL, NULL, 0, NULL);
	JSStringRelease(scriptJS);

	if (result) resultStringJS	= JSValueToStringCopy(ctx, result, NULL);		// Convert result to string, unless result is NULL.

	resultString	= result ? JSStringCopyCFString(kCFAllocatorDefault, resultStringJS) : CFSTR("[Exception]");
	if (result)		 					 JSStringRelease(resultStringJS);
													 JSGlobalContextRelease(ctx);										// Release JavaScript execution context.
	return (__bridge NSString*)resultString;																// Return result.
}


@end
