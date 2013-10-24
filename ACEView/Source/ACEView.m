//
//  ACEView.m
//  ACEView
//
//  Created by Michael Robinson on 26/08/12.
//  Copyright (c) 2012 Code of Interest. All rights reserved.
//

#import "ACEView.h"
#import "ACEModeNames.h"
#import "ACEThemeNames.h"
#import "ACERange.h"
#import "ACEStringFromBool.h"
#import "NSString+EscapeForJavaScript.h"
#import "NSInvocation+MainThread.h"

#define ACE_JAVASCRIPT_DIRECTORY @"___ACE_VIEW_JAVASCRIPT_DIRECTORY___"

#pragma mark - ACEViewDelegate
NSString *const ACETextDidEndEditingNotification = @"ACETextDidEndEditingNotification";
#pragma mark - ACEView private
static NSArray *allowedSelectorNamesForJavaScript;

@interface ACEView()
- (NSString *) stringByEvaluatingJavaScriptOnMainThreadFromString:(NSString *)script;
- (void) executeScriptsWhenLoaded:(NSArray *)scripts;
- (void) executeScriptWhenLoaded:(NSString *)script;
- (void) resizeWebView;
- (void) showFindInterface;
- (void) showReplaceInterface;
+ (NSArray*) allowedSelectorNamesForJavaScript;
- (void) aceTextDidChange;
@end

#pragma mark - ACEView implementation
@implementation ACEView

#pragma mark - Internal
- (id) initWithFrame:(NSRect)frame {
	
	if (self != [super initWithFrame:frame]) return nil;
	_webView = WebView.new;
	_webView.frameLoadDelegate = self;
	return self;
}

- (void) viewDidMoveToWindow {
	[self addSubview:_webView];
	self.borderType 					= NSNoBorder;
	[self resizeWebView];
	_textFinder			 			= NSTextFinder.new;
	_textFinder.client				=	self;
	_textFinder.findBarContainer = self;
	
	NSBundle *bundle = [NSBundle bundleForClass:self.class];
	
	// Unable to use pretty resource paths with CocoaPods
	//	NSString *javascriptDirectory = [[bundle pathForResource:@"ace" ofType:@"js" inDirectory:@"ace/javascript"] stringByDeletingLastPathComponent];
	NSString *javascriptDirectory = [[bundle resourcePath]stringByAppendingPathComponent:@"src"];
	//:@"ace" ofType:@"js"] stringByDeletingLastPathComponent];
	
	
	// Unable to use pretty resource paths with CocoaPods
	//	NSString *htmlPath = [bundle pathForResource:@"index" ofType:@"html" inDirectory:@"ace"];
	NSString *htmlPath = [bundle pathForResource:@"index" ofType:@"html"];
	NSString *html = [NSString stringWithContentsOfFile:htmlPath encoding:NSUTF8StringEncoding error:nil];
	html = [html stringByReplacingOccurrencesOfString:ACE_JAVASCRIPT_DIRECTORY withString:javascriptDirectory];
	[_webView.mainFrame loadHTMLString:html baseURL:[bundle bundleURL]];
	
}
+ (BOOL) isSelectorExcludedFromWebScript:(SEL)aSelector {
	return ![[ACEView allowedSelectorNamesForJavaScript] containsObject:NSStringFromSelector(aSelector)];
}

#pragma mark - NSView overrides
- (void) drawRect:(NSRect)dirtyRect {
	[self resizeWebView];
	[super drawRect:dirtyRect];
}
- (void) resizeSubviewsWithOldSize:(NSSize)oldSize {
	[self resizeWebView];
}

#pragma mark - WebView delegate methods
- (void) webView:(WebView*)w didFinishLoadForFrame:(WebFrame *)f{ [_webView.windowScriptObject setValue:self forKey:@"ACEView"]; }

#pragma mark - NSTextFinderClient methods
- (void) performTextFinderAction:(id)x { [_textFinder performAction:[x tag]]; }

- (void) scrollRangeToVisible:(NSRange)range { _firstSelectedRange = range;
	
	[self executeScriptWhenLoaded:
	 [NSString stringWithFormat:	@"editor.session.selection.clearSelection();"
	  @"editor.session.selection.setRange(new Range(%@));"
	  @"editor.centerSelection()", ACEStringFromRangeAndString(range, self.stringValue)]];
}
- (void) replaceCharactersInRange:(NSRange)range withString:(NSString *)string {
	
	[self executeScriptWhenLoaded:[NSString stringWithFormat:@"editor.session.replace(new Range(%@), \"%@\");",
											 ACEStringFromRangeAndString(range, self.stringValue), string.stringByEscapingForJavaScript]];
}
- (BOOL) isEditable { return YES; }

#pragma mark - Private
- (NSString *) stringByEvaluatingJavaScriptOnMainThreadFromString:(NSString *)script {	NSString *contentString;
	
	SEL strByEvalJSFromStr 		= @selector(stringByEvaluatingJavaScriptFromString:);
	NSInvocation *invocation 	= [NSInvocation invocationWithMethodSignature: [_webView.class instanceMethodSignatureForSelector:strByEvalJSFromStr]];
	invocation.selector 			= strByEvalJSFromStr;
	invocation.target 			= _webView;
	[invocation setArgument:&script atIndex:2];
	[invocation invokeOnMainThread];
	[invocation getReturnValue:&contentString];
	return contentString;
}
- (void) executeScriptsWhenLoaded:(NSArray *)scripts {

	if (_webView.isLoading) return [self performSelector:@selector(executeScriptsWhenLoaded:) withObject:scripts afterDelay:1];
	[scripts enumerateObjectsUsingBlock:^(id script, NSUInteger index, BOOL *stop) { [_webView stringByEvaluatingJavaScriptFromString:script]; }];
}
- (void) executeScriptWhenLoaded:(NSString *)script { 	[self executeScriptsWhenLoaded:@[script]]; }

- (void) resizeWebView { 	NSRect bounds = self.bounds;

	id<NSTextFinderBarContainer> findBarContainer = _textFinder.findBarContainer;
	if (findBarContainer.isFindBarVisible) {
		CGFloat findBarHeight = findBarContainer.findBarView.frame.size.height;
		bounds.origin.y += findBarHeight;
		bounds.size.height -= findBarHeight;
	}
	[_webView.animator setFrame:NSMakeRect(bounds.origin.x + 1, bounds.origin.y + 1, bounds.size.width - 2, bounds.size.height - 2)];
}

- (void) showFindInterface 	{ [_textFinder performAction:NSTextFinderActionShowFindInterface]; 		[self resizeWebView]; }
- (void) showReplaceInterface { [_textFinder performAction:NSTextFinderActionShowReplaceInterface];	[self resizeWebView]; }

+ (NSArray *) allowedSelectorNamesForJavaScript {
	
	allowedSelectorNamesForJavaScript  = allowedSelectorNamesForJavaScript  ?: @[ @"showFindInterface", @"showReplaceInterface", @"aceTextDidChange" ];
	return [allowedSelectorNamesForJavaScript retain];
}

- (void) aceTextDidChange { NSNotification *note;
	[[NSNotificationCenter defaultCenter] postNotification:note = [NSNotification notificationWithName:ACETextDidEndEditingNotification object:self]];	
	if (self.delegate && [self.delegate respondsToSelector:@selector(textDidChange:)])  [self.delegate performSelector:@selector(textDidChange:) withObject:note];
}

#pragma mark - Public
- (NSString *) stringValue { return [self stringByEvaluatingJavaScriptOnMainThreadFromString:@"editor.getValue();"]; }
- (void) setStringValue:(NSString*)stringValue { 

	[self executeScriptsWhenLoaded:@[@"reportChanges = false;",
												[NSString stringWithFormat:@"editor.setValue(\"%@\");", [stringValue stringByEscapingForJavaScript]],
												@"editor.clearSelection();",
												@"editor.moveCursorTo(0, 0);",
												@"reportChanges = true;",
												@"ACEView.aceTextDidChange();"]];
}

- (void) setMode:(ACEMode)mode {
	[self executeScriptWhenLoaded:[NSString stringWithFormat:@"editor.getSession().setMode(\"ace/mode/%@\");", [ACEModeNames nameForMode:mode]]];
}
- (void) setTheme:(ACETheme)theme {
	[self executeScriptWhenLoaded:[NSString stringWithFormat:@"editor.setTheme(\"ace/theme/%@\");", [ACEThemeNames nameForTheme:theme]]];
}

- (void) setWrappingBehavioursEnabled:(BOOL)wrap {
	[self executeScriptWhenLoaded:[NSString stringWithFormat:@"editor.setWrapBehavioursEnabled(%@);", ACEStringFromBool(wrap)]];
}
- (void) setUseSoftWrap:(BOOL)wrap {
	[self executeScriptWhenLoaded:[NSString stringWithFormat:@"editor.getSession().setUseWrapMode(%@);", ACEStringFromBool(wrap)]];
}
- (void) setWrapLimitRange:(NSRange)range {
	[self setUseSoftWrap:YES];
	[self executeScriptWhenLoaded:[NSString stringWithFormat:@"editor.getSession().setWrapLimitRange(%ld, %ld);", range.location, range.length]];
}
- (void) setShowInvisibles:(BOOL)show {
	[self executeScriptWhenLoaded:[NSString stringWithFormat:@"editor.setShowInvisibles(%@);", ACEStringFromBool(show)]];
}
- (void) setShowFoldWidgets:(BOOL)show {
	[self executeScriptWhenLoaded:[NSString stringWithFormat:@"editor.setShowFoldWidgets(%@);", ACEStringFromBool(show)]];
}
- (void) setFadeFoldWidgets:(BOOL)fade {
	[self executeScriptWhenLoaded:[NSString stringWithFormat:@"editor.setFadeFoldWidgets(%@);", ACEStringFromBool(fade)]];
}
- (void) setHighlightActiveLine:(BOOL)highlight {
	[self executeScriptWhenLoaded:[NSString stringWithFormat:@"editor.setHighlightActiveLine(%@);", ACEStringFromBool(highlight)]];
}
- (void) setHighlightGutterLine:(BOOL)highlight {
	[self executeScriptWhenLoaded:[NSString stringWithFormat:@"editor.setHighlightGutterLine(%@);", ACEStringFromBool(highlight)]];
}
- (void) setHighlightSelectedWord:(BOOL)highlight {
	[self executeScriptWhenLoaded:[NSString stringWithFormat:@"editor.setHighlightSelectedWord(%@);", ACEStringFromBool(highlight)]];
}
- (void) setDisplayIndentGuides:(BOOL)display {
	[self executeScriptWhenLoaded:[NSString stringWithFormat:@"editor.setDisplayIndentGuides(%@);", ACEStringFromBool(display)]];
}
- (void) setAnimatedScroll:(BOOL)animate {
	[self executeScriptWhenLoaded:[NSString stringWithFormat:@"editor.setAnimatedScroll(%@);", ACEStringFromBool(animate)]];
}
- (void) setScrollSpeed:(NSUInteger)speed {
	[self executeScriptWhenLoaded:[NSString stringWithFormat:@"editor.setScrollSpeed(%ld);", speed]];
}
- (void) setPrintMarginColumn:(NSUInteger)column {
	[self executeScriptWhenLoaded:[NSString stringWithFormat:@"editor.setPrintMarginColumn(%ld);", column]];
}
- (void) setShowPrintMargin:(BOOL)show {
	[self executeScriptWhenLoaded:[NSString stringWithFormat:@"editor.setShowPrintMargin(%@);", ACEStringFromBool(show)]];
}
- (void) setFontSize:(NSUInteger)size {
	[self executeScriptWhenLoaded:[NSString stringWithFormat:@"editor.setFontSize('%ldpx');", size]];
}

- (void) gotoLine:(NSInteger)lineNumber column:(NSInteger)columnNumber animated:(BOOL)animate {
	[self executeScriptWhenLoaded:[NSString stringWithFormat:@"editor.gotoLine(%ld, %ld, %@);", lineNumber, columnNumber, ACEStringFromBool(animate)]];
}

@end
