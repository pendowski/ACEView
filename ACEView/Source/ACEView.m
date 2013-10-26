
#import "ACEView.h"
#import "ACERange.h"
//#import "ACEStringFromBool.h"
#import "NSString+EscapeForJavaScript.h"
#import "NSInvocation+MainThread.h"

@implementation  ACEMode																												@end
@implementation  ACETheme																											@end
@implementation  ACESetting
+ (instancetype) settingNamed:(NSString*)n jsFormat:(NSString*)fmt, ... {
	id x = self.new; [(ACESetting*)x setName:n]; va_list args;	va_start(args, fmt);
	[x setJs:[NSString.alloc initWithFormat:fmt arguments:args]];
	va_end(args);
	return x;
} @end

static			     NSArray * allowedSelectorNamesForJavaScript;

@interface ACEView()
@property NSTextFinder *textFinder;
- (NSString *) stringByEvaluatingJavaScriptOnMainThreadFromString:(NSString *)script;
- (void) executeScriptsWhenLoaded:(NSArray *)scripts;
- (void) executeScriptWhenLoaded:(NSString *)script;
- (void) resizeWebView;
+ (NSArray*) allowedSelectorNamesForJavaScript;
- (void) aceTextDidChange;
@end

@implementation ACEView

- (NSString*)aceDirectory { return  [[NSBundle bundleForClass:self.class].resourcePath stringByAppendingPathComponent:@"src"]; }

- (void) loadAce { 	[self addSubview:_webView = WebView.new]; _webView.frameLoadDelegate = self;

	NSString *htmlPath = [[NSBundle bundleForClass:self.class] pathForResource:@"index" ofType:@"html"];
	[_webView.mainFrame loadHTMLString: [[NSString stringWithContentsOfFile:htmlPath encoding:NSUTF8StringEncoding error:nil]
									stringByReplacingOccurrencesOfString:ACE_JAVASCRIPT_DIRECTORY withString:self.aceDirectory] baseURL:[NSBundle bundleForClass:self.class].bundleURL];
	[self setFont:nil];
	[self resizeWebView];
}

- (id) superViewOfView:(id)v ofClass:(Class)k { id x; if (!(x = [v superview])) return nil; else if ([x isKindOfClass:k]) return x; else return  [self superViewOfView:x ofClass:k]; }

- (void) viewDidMoveToWindow {

	self.borderType								= NSNoBorder;
	self.hasHorizontalScroller		= NO;
	_textFinder										= NSTextFinder.new;
	_textFinder.client						=	self;
	_textFinder.findBarContainer	= self;
	[self loadAce];
	ACEBrowserView *x = [self superViewOfView:self ofClass:ACEBrowserView.class];
	if (x) {	NSLog(@"found %@", x);
		[x.webView.mainFrame loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://google.com" ]]];
		x.split.vertical = YES;
	}
}
+ (BOOL) isSelectorExcludedFromWebScript:(SEL)aSelector {
	return ![ACEView.allowedSelectorNamesForJavaScript containsObject:NSStringFromSelector(aSelector)];
}

#pragma mark - NSView overrides
- (void) drawRect:						(NSRect)dirtyRect { [self resizeWebView]; [super drawRect:dirtyRect]; }
- (void) resizeSubviewsWithOldSize:	(NSSize)oldSize 	{ [self resizeWebView]; 									 }

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

	if (_webView.isLoading) return [self performSelector:@selector(executeScriptsWhenLoaded:) withObject:scripts afterDelay:.2];
	[scripts enumerateObjectsUsingBlock:^(id script, NSUInteger index, BOOL *stop) { [_webView stringByEvaluatingJavaScriptFromString:script]; }];
}
- (void) executeScriptWhenLoaded:(NSString *)script { 	[self executeScriptsWhenLoaded:@[script]]; }

- (void) resizeWebView { 	NSRect bounds = self.bounds;

	id<NSTextFinderBarContainer> findBarContainer = _textFinder.findBarContainer;
	if (findBarContainer.isFindBarVisible) {
		CGFloat findBarHeight = findBarContainer.findBarView.frame.size.height;
		bounds.origin.y      += findBarHeight;
		bounds.size.height   -= findBarHeight;
	}
	[_webView.animator setFrame:NSMakeRect(bounds.origin.x + 1, bounds.origin.y + 1, bounds.size.width - 2, bounds.size.height - 2)];
}

- (void) showFindInterface 	{ [_textFinder performAction:NSTextFinderActionShowFindInterface]; 		[self resizeWebView]; }
- (void) showReplaceInterface { [_textFinder performAction:NSTextFinderActionShowReplaceInterface];	[self resizeWebView]; }

+ (NSArray *) allowedSelectorNamesForJavaScript {
	
	allowedSelectorNamesForJavaScript  = allowedSelectorNamesForJavaScript  ?: @[ @"showFindInterface", @"showReplaceInterface", @"aceTextDidChange" ];
	return allowedSelectorNamesForJavaScript;// retain];
}

- (void) aceTextDidChange { NSNotification *note;
	[NSNotificationCenter.defaultCenter postNotification:note = [NSNotification notificationWithName:ACETextDidEndEditingNotification object:self]];
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
@synthesize themes = _themes, modes = _modes, webView = _webView;

- (NSArrayController*) modes	{ return _modes  ?: ^{ _modes = NSArrayController.new;

	NSString *cmd, *file, *parse;
 	cmd = @"Object.keys(supportedModes);",
	file = [self.aceDirectory stringByAppendingPathComponent:@"ext-modelist.js"],
	parse =  [[NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil]
							 stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
									  
	NSRange firstInstance = [parse rangeOfString:@"var supportedModes"];
	parse = [parse substringFromIndex:firstInstance.location];
	NSRange closingBrace = [parse rangeOfString:@"};"];
	parse = [parse substringWithRange:NSMakeRange(0,closingBrace.location + 2)];
	NSArray *humanReadables = [[cmd evaluateStringWithStringOrFile:parse] componentsSeparatedByString:@","];
	NSString*(^getShorty)(NSString *) = ^NSString*(NSString *key) {

		NSString *res = [[NSString stringWithFormat:@"supportedModes.%@;", key] evaluateStringWithStringOrFile:parse];
		NSRange r = [res rangeOfString:@"|"];
		return [res substringToIndex:r.location == NSNotFound ? res.length : r.location];
	};

	[humanReadables enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		ACEMode *m = ACEMode.new;
		m.name = obj;
		m.js = [NSString stringWithFormat:@"editor.getSession().setMode('ace/mode/%@');", getShorty(obj)];
		[_modes addObject:m];
	}];
	[_modes addObserver:self forKeyPath:@"selectionIndex" options:nil context:NULL];
	return _modes;
}();	}
- (NSArrayController*) themes { return _themes ?: ^{ _themes = NSArrayController.new;

		NSString *cmd 	= @"themes;", 
					*file = [self.aceDirectory stringByAppendingPathComponent:@"ext-themelist.js"],
			  *parsable =  [[NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil]
									  stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
									  
		NSRange firstInstance = [parsable rangeOfString:@"themes = ["];
		parsable = [parsable substringFromIndex:firstInstance.location];
		NSRange closingBrace = [parsable rangeOfString:@"];"];
		parsable = [parsable substringWithRange:NSMakeRange(0,closingBrace.location + 2)];
		NSLog(@"pparsabe:%@", parsable);
		NSArray *humanReadables = [[cmd evaluateStringWithStringOrFile:parsable]componentsSeparatedByString:@","];
		[humanReadables enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
			ACETheme *m = ACETheme.new;
			m.name = obj;
			m.js = [NSString stringWithFormat:@"editor.setTheme('ace/theme/%@')", obj];
			[_themes addObject:m];
		}];
		[_themes addObserver:self forKeyPath:@"selectionIndex" options:nil context:NULL];
		return _themes;
	}();	}


- (void) observeValueForKeyPath:(NSString*)kp ofObject:(id)x change:(NSDictionary*)c context:(void *)ctx {
	NSLog(@"obj:%@, kp:%@, ch:%@", x, kp, c);
	NSString *theJS = 
	x == _modes 	? [_modes.selectedObjects[0]  js] :
	x == _themes 	? [_themes.selectedObjects[0] js] : nil;
	if (theJS) {  NSLog(@"theJS: %@", theJS); [self executeScriptWhenLoaded:theJS]; }
	else  [super observeValueForKeyPath:kp ofObject:x change:c context:ctx];
}
#define SETIT(x) _##x = x
- (void) setFont:(NSString*)name {
	[self executeScriptWhenLoaded:[NSString stringWithFormat:@"document.getElementById('editor').style.fontFamily = 'UbuntuMono-Bold';"]];
}
//- (void) setMode:(ACEMode)mode {  SETIT(mode);
//	[self executeScriptWhenLoaded:[NSString stringWithFormat:@"editor.getSession().setMode(\"ace/mode/%@\");", [ACEModeNames nameForMode:mode]]];
//}
//- (void) setTheme:(ACETheme)theme { SETIT(theme);
//	[self executeScriptWhenLoaded:[NSString stringWithFormat:@"editor.setTheme(\"ace/theme/%@\");", [ACEThemeNames nameForTheme:theme]]];
//}

- (void) setWrappingBehavioursEnabled:(BOOL)wrap { _wrappingBehavioursEnabled = wrap;
	[self executeScriptWhenLoaded:[NSString stringWithFormat:@"editor.setWrapBehavioursEnabled(%@);", ACEStringFromBool(wrap)]];
}
- (void) setUseSoftWrap:(BOOL)wrap { _useSoftWrap = wrap;
	[self executeScriptWhenLoaded:[NSString stringWithFormat:@"editor.getSession().setUseWrapMode(%@);", ACEStringFromBool(wrap)]];
}
- (void) setWrapLimitRange:(NSRange)range { _wrapLimitRange = range;
	[self setUseSoftWrap:YES];
	[self executeScriptWhenLoaded:[NSString stringWithFormat:@"editor.getSession().setWrapLimitRange(%ld, %ld);", range.location, range.length]];
}
- (void) setShowInvisibles:(BOOL)show { _showInvisibles = show;
	[self executeScriptWhenLoaded:[NSString stringWithFormat:@"editor.setShowInvisibles(%@);", ACEStringFromBool(show)]];
}
- (void) setShowFoldWidgets:(BOOL)show { _showFoldWidgets = show;
	[self executeScriptWhenLoaded:[NSString stringWithFormat:@"editor.setShowFoldWidgets(%@);", ACEStringFromBool(show)]];
}
- (void) setFadeFoldWidgets:(BOOL)fade { _fadeFoldWidgets = fade;
	[self executeScriptWhenLoaded:[NSString stringWithFormat:@"editor.setFadeFoldWidgets(%@);", ACEStringFromBool(fade)]];
}
- (void) setHighlightActiveLine:(BOOL)highlight { _highlightActiveLine = highlight;
	[self executeScriptWhenLoaded:[NSString stringWithFormat:@"editor.setHighlightActiveLine(%@);", ACEStringFromBool(highlight)]];
}
- (void) setHighlightGutterLine:(BOOL)highlight { _highlightGutterLine = highlight;
	[self executeScriptWhenLoaded:[NSString stringWithFormat:@"editor.setHighlightGutterLine(%@);", ACEStringFromBool(highlight)]];
}
- (void) setHighlightSelectedWord:(BOOL)highlight { _highlightSelectedWord = highlight;
	[self executeScriptWhenLoaded:[NSString stringWithFormat:@"editor.setHighlightSelectedWord(%@);", ACEStringFromBool(highlight)]];
}
- (void) setDisplayIndentGuides:(BOOL)display { _displayIndentGuides = display;
	[self executeScriptWhenLoaded:[NSString stringWithFormat:@"editor.setDisplayIndentGuides(%@);", ACEStringFromBool(display)]];
}
- (void) setAnimatedScroll:(BOOL)animate { _animatedScroll = animate;
	[self executeScriptWhenLoaded:[NSString stringWithFormat:@"editor.setAnimatedScroll(%@);", ACEStringFromBool(animate)]];
}
- (void) setScrollSpeed:(NSUInteger)speed { _scrollSpeed = speed;
	[self executeScriptWhenLoaded:[NSString stringWithFormat:@"editor.setScrollSpeed(%ld);", speed]];
}
- (void) setPrintMarginColumn:(NSUInteger)column { _printMarginColumn = column;
	[self executeScriptWhenLoaded:[NSString stringWithFormat:@"editor.setPrintMarginColumn(%ld);", column]];
}
- (void) setShowPrintMargin:(BOOL)show { _showPrintMargin = show;
	[self executeScriptWhenLoaded:[NSString stringWithFormat:@"editor.setShowPrintMargin(%@);", ACEStringFromBool(show)]];
}
- (void) setFontSize:(NSUInteger)size { _fontSize = size;
	[self executeScriptWhenLoaded:[NSString stringWithFormat:@"editor.setFontSize('%ldpx');", size]];
}

- (void) gotoLine:(NSInteger)lineNumber column:(NSInteger)columnNumber animated:(BOOL)animate {
	[self executeScriptWhenLoaded:[NSString stringWithFormat:@"editor.gotoLine(%ld, %ld, %@);", lineNumber, columnNumber, ACEStringFromBool(animate)]];
}

@end

//- (NSArrayController*) modes { return _modes ?:
//	[_modes = NSArrayController.new setContent:ACEModeNames.humanModeNames],
//	[_modes addObserver:self forKeyPath:@"selectionIndex" options:nil context:NULL], _modes;
//}

//  ACEView.m
//  ACEView
//  Created by Michael Robinson on 26/08/12.
//  Copyright (c) 2012 Code of Interest. All rights reserved.
//#import "ACEModeNames.h"
//#import "ACEThemeNames.h"

//#pragma mark - Internal
//- (id) initWithFrame:(NSRect)frame {
//
//	if (self != [super initWithFrame:frame]) return nil;
//	return self;
//}
#pragma mark - ACEViewDelegate
//NSString *const ACETextDidEndEditingNotification = @"ACETextDidEndEditingNotification";
#pragma mark - ACEView private
//	if (self.delegate && [self.delegate respondsToSelector:@selector(textDidChange:)])
//		[self.delegate performSelector:@selector(textDidChange:) withObject:note];
// Unable to use pretty resource paths with CocoaPods
//	NSString *javascriptDirectory = [[bundle pathForResource:@"ace" ofType:@"js" inDirectory:@"ace/javascript"] stringByDeletingLastPathComponent];
//:@"ace" ofType:@"js"] stringByDeletingLastPathComponent];


// Unable to use pretty resource paths with CocoaPods
//	NSString *htmlPath = [bundle pathForResource:@"index" ofType:@"html" inDirectory:@"ace"];
//_webView.postsBoundsChangedNotifications	= YES;
//[NSNotificationCenter.defaultCenter addObserverForName:NSViewBoundsDidChangeNotification
//																								object:_webView queue:NSOperationQueue.mainQueue
//																						usingBlock:^(NSNotification *note) {
//																							[_webView setNeedsDisplay:YES];
//																						}];
