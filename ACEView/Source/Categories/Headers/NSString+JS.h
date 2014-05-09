//
//  NSString+EscapeForJavaScript.h
//  ACEView
//
//  Created by Michael Robinson on 5/12/12.
//  Copyright (c) 2012 Code of Interest. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (AtoZJSFierceness)

@property (readonly) NSString * stringByEscapingForJavaScript;

- (NSString*) evaluateStringWithStringOrFile:(id)script;
- (NSString*) stringByPaddingTheLeftToLength:(NSUInteger)newLength;
@end
