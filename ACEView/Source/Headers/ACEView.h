
#import <WebKit/WebKit.h>

@interface ACESetting : NSObject + (instancetype) settingNamed:(NSString*)n jsFormat:(NSString*)fmt, ...;
@property    NSString * name, *js;	@end
@interface    ACEMode : ACESetting 	@end
@interface   ACETheme : ACESetting 	@end


@interface ACEView : NSScrollView <NSTextFinderClient> 


- (void) showFindInterface;
- (void) showReplaceInterface;
- (void) gotoLine:(NSInteger)lineNumber column:(NSInteger)columnNumber animated:(BOOL)animate;

@property  (readonly) NSArrayController *modes;
@property  (readonly) NSArrayController *themes;

@property	(readonly)					  WebView * webView;
@property (nonatomic)					 NSString * stringValue,
																				* documentPath;
@property  (readonly)			     NSString * mode,
																				* aceDirectory;

@property (nonatomic)		 NSRange  wrapLimitRange;
@property  (readonly)		 NSRange   firstSelectedRange;
@property (nonatomic) NSUInteger  scrollSpeed,
																	printMarginColumn,
																	fontSize;
@property (nonatomic)				BOOL  wrappingBehavioursEnabled,
																	useSoftWrap,
																	showInvisibles,
																	showFoldWidgets,
																	fadeFoldWidgets,
																	highlightActiveLine,
																	highlightGutterLine,
																	highlightSelectedWord,
																	animatedScroll,
																	displayIndentGuides,
																	showPrintMargin;

typedef void(^TextChanged)(ACEView* ace,NSString *line);
@property (copy) TextChanged textChanged;

@end


#define SETONLYPROPERTY(_KIND_,_NAME_) @property (nonatomic) _KIND_ _NAME_; - (_KIND_)_NAME_ UNAVAILABLE_ATTRIBUTE
#define ACE_JAVASCRIPT_DIRECTORY @"___ACE_VIEW_JAVASCRIPT_DIRECTORY___"
#define ACETextDidEndEditingNotification @"ACETextDidEndEditingNotification"
#import <ACEView/ACEBrowserView.h>

/** Turn wrapping behaviour on or off.
 Specifies whether to use wrapping behaviors or not, i.e. automatically wrapping the selection with characters such as brackets when such a character is typed in.
 Uses [editor.setWrapBehavioursEnabled()](http://ace.ajax.org/#Editor.setWrapBehavioursEnabled).
 @param wrap YES if wrapping behaviours are to be enabled, NO otherwise.
 @see setUseSoftWrap:
 @see setWrapLimitRange:	*/
/** Sets whether or not line wrapping is enabled.
 Define the wrap limit with setWrapLimitRange.
 Uses [editor.getSession().setUseWrapMode()](http://ace.ajax.org/#EditSession.setUseWrapMode).
 @param wrap YES if line wrapping is to be enabled, NO otherwise.
 @see setWrappingBehavioursEnabled:
 @see setWrapLimitRange:	*/
/**  Sets the boundaries of wrap.
 Uses [editor.getSession().setWrapLimitRange()](http://ace.ajax.org/#EditSession.setWrapLimitRange).
 @param range Range within which lines should be constrained. Typically range.location will be 0.
 @see setWrappingBehavioursEnabled:
 @see setUseSoftWrap:
 */
/** Show or hide invisible characters.
 Uses [editor.setShowInvisibles()](http://ace.ajax.org/#Editor.setShowInvisibles).
 @param show YES if inivisible characters are to be shown, NO otherwise.
 */
/** Show or hide folding widgets.
	Uses [editor.setShowFoldWidgets()](http://ace.ajax.org/#Editor.setShowFoldWidgets).
	@param show YES if folding widgets are to be shown, NO otherwise.
 */
/** Enable fading of folding widgets.
	Uses [editor.setFadeFoldWidgets()](http://ace.ajax.org/#Editor.setFadeFoldWidgets).
	@param fade YES if folding widgets should be faded, NO otherwise.
 */
/** Highlight the active line.
	Uses [editor.setHighlightActiveLine()](http://ace.ajax.org/#Editor.setHighlightActiveLine).
	@param highlight YES if the active line should be highlighted, NO otherwise.	*/
/** Highlight the gutter line.
	Uses [editor.setHighlightGutterLine()](http://ace.ajax.org/#Editor.setHighlightGutterLine).
	@warning The ACE Editor documentation for this behaviour is incomplete.
 @param highlight YES if the gutter line should be highlighted, NO otherwise.	*/
/** Highlight the selected word.
	Uses [editor.setHighlightSelectedWord()](http://ace.ajax.org/#Editor.setHighlightSelectedWord).
	@param highlight YES if the selected word should be highlighted, NO otherwise.	*/
/** Display indent guides.
	Uses [editor.setDisplayIndentGuides()](http://ace.ajax.org/#Editor.setDisplayIndentGuides).
	@param display YES if indent guides should be displayed, NO otherwise.	*/

/** Enable animated scrolling.
	Uses [editor.setAnimatedScroll()](http://ace.ajax.org/#Editor.setAnimatedScroll).
	@warning The ACE Editor documentation for this behaviour is incomplete.
 @param animate YES if scrolling should be animated, NO otherwise.	*/
/** Change the mouse scroll speed.
	Uses [editor.setScrollSpeed()](http://ace.ajax.org/#Editor.setScrollSpeed).
	@param speed the new scroll speed (in milliseconds). */

/** Sets the column defining where the print margin should be.
	Uses [editor.setPrintMarginColumn()]( http://ace.ajax.org/#Editor.setPrintMarginColumn ).
	@param column The column on which the print margin should be drawn.	*/
/**
 Uses [editor.setShowPrintMargin()]( http://ace.ajax.org/#api=editor&nav=setShowPrintMargin ).
 */
/** Sets the font size.
	Uses [editor.setFontSize()](http://ace.ajax.org/#Editor.setFontSize).
	@param size The new font size.
 */
/** Moves the cursor to the specified line number, and also into the indiciated column.
 Uses [editor.goToLine()].
 @param lineNumber The line number to go to
 @param lineNumber  column number to go to
 @param animate If YES animates scolling
 */
//- (ACEMode)mode UNAVAILABLE_ATTRIBUTE;

//
//  ACEView.h
//  ACEView
//
//  Created by Michael Robinson on 26/08/12.
//  Copyright (c) 2012 Code of Interest. All rights reserved.
//
//#import <ACEView/ACEModes.h>
//#import <ACEView/ACEThemes.h>



/** The ACEViewDelegate protocol is implemented by objects that wish to monitor the ACEView for content changes. */
//#pragma mark - ACEViewDelegate
//@protocol ACEViewDelegate <NSObject>
/** Posts a notification that the text has changed and forwards this message to the delegate if it responds.
 @param notification The ACETextDidEndEditingNotification notification that is posted to the default notification center.
 */
//- (void) textDidChange:(NSNotification *)notification;
//@end
//{
//	NSTextFinder *_textFinder;
//	CGColorRef _borderColor;
//	WebView *_webView;
//	id _delegate;
//	NSRange _firstSelectedRange;
//}
/// @name Properties
/// @see NSTextFinderClient

/** Set/Retrieve the content of the underlying ACE Editor. No underlying ivar. */
/// Sets the syntax highlighting mode.  Uses [editor.getSession().setMode()] ( http://ace.ajax.org/#EditSession.setMode ).
/// Set the theme. Uses [editor.getSession().setTheme()](http://ace.ajax.org/#Editor.setTheme).
//@property			 (weak)								 id   delegate;
