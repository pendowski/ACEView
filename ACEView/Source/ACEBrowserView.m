
@import WebKit;
@import ObjectiveC;
#import "ACEView.h"
#import "ACEBrowserView.h"

typedef void(^ControlBlock)(NSControl*x);

@implementation NSControl (Block)
- (ControlBlock) actionBlock              { return  objc_getAssociatedObject(self, _cmd); }
- (void) setActionBlock:(ControlBlock)ab  {

	objc_setAssociatedObject(self,    @selector(actionBlock),ab,OBJC_ASSOCIATION_COPY);
	self.target = self;	self.action = @selector(trampoline);
}
- (void) trampoline                       {

  self.actionBlock && self.target == self ? self.actionBlock(self) :
  self.action      && self.target ? objc_msgSend (self.target,self.action,self) : nil;
}
@end

@interface ACEBrowserView() <KFWebKitProgressDelegate, NSWindowDelegate, NSPopoverDelegate>
@property KFWebKitProgressController * controller;
@property (readonly) 		   NSPopover * myPopover;
@end

@implementation ACEBrowserView

//-   (id) valueForUndefinedKey:(NSString*)key 	{ return  [_webView valueForKey:key];	}
- (void)   setHTMLString:(NSString*)HTMLString 	{ [self.aceView setStringValue:HTMLString]; }
- (void) setUrlBarHeight:(CGFloat)urlBarHeight 	{ _urlBarHeight = urlBarHeight;

	NSRect urlBox = (NSRect){ 0, self.bounds.size.height - _urlBarHeight, self.bounds.size.width, _urlBarHeight};
	if (_urlBar) _urlBar.frame = urlBox;
  else {
		[self addSubview:_urlBar = [KFURLBar instanceWithRequestBlock:^(NSString *req) {
        self.mainFrameURL  = req;
        //	[_webView.mainFrame loadRequest:[NSURLRequest.alloc initWithURL:url]];
        _urlBar.progressPhase = KFProgPending;
    }]];
    _urlBar.frame = urlBox;
		[_controller = KFWebKitProgressController.new setDelegate:(id)self];
		for (id x in @[@"policyDelegate", @"frameLoadDelegate", @"downloadDelegate",@"resourceLoadDelegate",@"UIDelegate"])
			[_webView setValue:_controller forKey:x];
		_urlBar.autoresizingMask = NSViewWidthSizable|NSViewMinYMargin;
//		[_urlBar setBarColorPendingTop:NSColor.redColor];
//		[_urlBar setBarColorPendingBottom:NSColor.orangeColor];
	}
}

- (void) awakeFromNib { self.window.delegate = self.window.delegate ?: self; }

//- (id) initWithCoder:(NSCoder*)d { return [self initWithFrame:NSZeroRect]; }

//  if (!(self = [super initWithFrame:r])) return nil;
- (id) initWithFrame:(NSRect)r   {

  if (!(self = [super initWithFrame:r])) return nil;

  self.urlBarHeight 	= 40;
	
	for (id b in @[@"reloadB", @"alertB",@"modeB", @"themeB"]) { NSButton*butt; 
		
    [butt = NSButton.new setValuesForKeysWithDictionary:@{ @"bezelStyle": @(NSInlineBezelStyle),
                            @"translatesAutoresizingMaskIntoConstraints":@NO}];
    [self setValue:butt  forKey:b];
//		butt.title = b; [[butt cell] setBackgroundStyle: NSBackgroundStyleRaised];
	}
	
	 __block id me        = self;
	 _alertB.actionBlock  = ^(id x){ [me showAlert:x]; };
	  _modeB.actionBlock 	= ^(id x){ [me     modePop]; };
	_reloadB.actionBlock 	= ^(id x){ [me reloadURL:x]; };
	
	_reloadB.image			= [NSImage imageNamed:@"NSRefreshTemplate"];
	_urlBar.leftItems 	= @[_reloadB, _modeB];
	_urlBar.rightItems 	= @[_alertB, _themeB];

	NSRect splitFrame 			    = self.bounds;
	splitFrame.size.height     -= _urlBarHeight;
	[_split                     = [NSSplitView.alloc initWithFrame:splitFrame] setVertical:NO];
	_split.subviews             = @[ _aceView = [ACEView.alloc init], _webView = [WebView.alloc init]];
	_split.dividerStyle         = NSSplitViewDividerStyleThick;
	_split.autoresizingMask     =
	_webView.autoresizingMask 	= 
	_aceView.autoresizingMask 	= NSViewWidthSizable|NSViewHeightSizable;
//	[_urlBar bind:@"addressString" toObject:_webView withKeyPath:@"mainFrameURL" options:nil];
	[_webView bind:@"mainFrameURL" toObject:_aceView withKeyPath:@"mainFrameURL" options:nil];
//	_aceView.delegate 			= self;

	[self addSubview:_split];
//	_aceView.mode					= ACEModeHTML;
//	_aceView.theme 				= ACEThemeMonokai;
	_aceView. showPrintMargin 	= NO; 
	_aceView.showInvisibles		= YES;
	

	_aceView.stringValue 	= [NSString stringWithContentsOfFile:@"/Volumes/2T/ServiceData/git/ACEView/ACEView/Source/Headers/ACEView.h" 
																 encoding:NSUTF8StringEncoding error:nil];

	//ACEModeNames.humanModeNames ACEThemeNames.humanThemeNames
  return self;
}

- (void) textDidChange:(NSNotification *)notification {
	// Handle text changes
	NSLog(@"%s", __PRETTY_FUNCTION__);
}

- (void) reloadURL:(id)x  { [_webView.mainFrame reload]; }
- (void) showAlert:(id)x  {

	NSBeginAlertSheet (@"WebKit Objective-C Programming Guide",
							 @"OK",
							 nil,
							 @"Cancel",
							 [self window],
							 self,
							 nil,
							 nil,
							 nil,
							 @"As the user navigates from page to page in your embedded browser, you may want to display the current URL, load status, and error messages. For example, in a web browser application, you might want to display the current URL in a text field that the user can edit.", nil);
}
- (void) updateProgress   {
	self.urlBar.progressPhase = KFProgDownloading;
	self.progress += .005;
	self.urlBar.progress = self.progress;
	if (self.progress < 1.0)
	{
		[self performSelector:@selector(updateProgress) withObject:nil afterDelay:.02f];
	}
	else
	{
		self.urlBar.progressPhase = KFProgNone;
	}
}

//@dynamic mainFrameURL;

//+ (BOOL) resolveInstanceMethod:(SEL)s {
//
//  return s == @selector(mainFrameURL) ?: [super resolveInstanceMethod:s];
//}
//- (id) forwardingTargetForSelector:(SEL)s { NSLog(@"should i forward... %@", NSStringFromSelector(s));
//
//  return // [_webView respondsToSelector:s] ?
//    self.webView;// : [super forwardingTargetForSelector:s];
//}
- (NSString*)mainFrameURL { return _webView.mainFrameURL; }
- (void) setMainFrameURL:(NSString*)s { _webView.mainFrameURL = s; }

#pragma mark - KFURLBarDelegate Methods

+ (BOOL) stringIsValidURL:(NSString*)s { static NSPredicate * p;

	return [p = p ?: [NSPredicate predicateWithFormat:@"SELF MATCHES %@", // urlRegEx
  @"(ftp|http|https)://((\\w)*|([0-9]*)|([-|_])*)+([\\.|/]((\\w)*|([0-9]*)|([-|_])*))+"]
                                 evaluateWithObject:s];
}

- (BOOL)urlBar:(KFURLBar*)bar isValidRequestStringValue:(NSString*)reqStr {

  return [self.class stringIsValidURL:reqStr];
}

#pragma mark - NSWindowDelegate Methods

- (NSRect)window:(NSWindow*)w willPositionSheet:(NSWindow*)s usingRect:(NSRect)r {

	r.origin.y -= NSHeight(_urlBar.frame);	return r;
}

#pragma mark WebKitProgressDelegate Methods

- (void) webKitProgressDidChangeFinishedCount:(NSInteger)finCt ofTotalCount:(NSInteger)totCt
{
	_urlBar.progressPhase = KFProgDownloading;
	_urlBar.progress      = (CGFloat)finCt / (CGFloat)totCt;	if (totCt != finCt) return;

  double delayInSeconds = 1.0;  __block KFURLBar *_bar = _urlBar;
  dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
  dispatch_after(popTime, dispatch_get_main_queue(), ^{ _bar.progressPhase = KFProgNone; });
}
- (NSPopover*) modePop {

	if (!_modePop) {		// the popover retains us and we retain the popover, we drop the popover whenever it is closed to avoid a cycle use a different view controller content if normal vs. HUD appearance

		NSTableView *tv;				NSTableColumn *c;		 	NSTextFieldCell *cell;		

		NSViewController *modeVC = NSViewController.new;
		NSRect base 				 = (NSRect){0,0,100,300};
		NSScrollView *sv			 = [NSScrollView.alloc initWithFrame:base];
		base.size.height 			 = 12 * [self.aceView.modes.arrangedObjects count];
		// ACEModeNames.humanModeNames.count;
		sv.documentView			 = tv = [NSTableView.alloc initWithFrame:base];
		sv.hasVerticalScroller	 = YES;
		sv.drawsBackground 		 = NO;
		tv.headerView				 = nil;
		tv.backgroundColor 		 = NSColor.clearColor;
		[tv addTableColumn:c 	 = NSTableColumn.new];
		c.dataCell 					 = cell = NSTextFieldCell.new;
		[cell setFont:[NSFont fontWithName:@"UbuntuMono-Bold" size:14.0]];
		[cell setTextColor:NSColor.whiteColor];
//		[c 	bind:@"value" toObject:	
//				[NSArrayController.alloc initWithContent: ACEModeNames.humanModeNames] 			
//				withKeyPath:@"arrangedObjects" options:nil];
		modeVC.view = sv;
//		[tv setTarget:_aceView];
//		[tv setAction:@selector(setMode:)];
		[tv setSelectionHighlightStyle:NSTableViewSelectionHighlightStyleSourceList];
		_modePop = NSPopover.new;
		_modePop.contentViewController = modeVC;
		_modePop.appearance = NSPopoverAppearanceHUD;
		_modePop.animates = YES;
	// AppKit will close the popover when the user interacts with a user interface element outside the popover. note that interacting with menus or panels that become key only when needed will not cause a transient popover to close.
		_modePop.behavior = NSPopoverBehaviorTransient;
		tv.actionBlock = ^(id sendo) { 		//	NSUInteger idx = [sendo selectedRow];
//			[self.aceView setMode:idx];
//												 NSLog(@"selected:%ld", idx);_aceView.mode = idx; 
			[_modePop close];
		};
		// so we can be notified when the popover appears or closes
//		_modePop.delegate = self;
	}	
	// configure the preferred position of the popove NSRectEdge prefEdge = popoverPosition.selectedRow;
	[_modePop showRelativeToRect:_modeB.bounds ofView:_urlBar preferredEdge:NSMinYEdge];
	return _modePop;
}

//  applicationShouldTerminateAfterLastWindowClosed:sender
//
//  NSApplication delegate method placed here so the sample conveniently quits
//  after we close the window.
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
	return YES;
}

#pragma mark NSPopoverDelegate

- (void)popoverWillShow:(NSNotification *)n
{
	NSPopover *popover = n.object;
	if (popover.appearance == NSPopoverAppearanceHUD)
	{
		// popoverViewControllerHUD is loaded by now, so set its UI to use white text and labels
		//        [popoverViewControllerHUD.checkButton setTextColor:[NSColor whiteColor]];
		//        [popoverViewControllerHUD.textLabel setTextColor:[NSColor whiteColor]];
	}
}
- (void)popoverDidShow:(NSNotification *)n {
	// Invoked on the delegate when the NSPopoverDidShowNotification notification is sent. This method will also be invoked on the popover. 
	// add new code here after the popover has been shown
}
- (void)popoverWillClose:(NSNotification *)n {
	// Invoked on the delegate when the NSPopoverWillCloseNotification notification is sent.
	NSString *closeReason = [n.userInfo valueForKey:NSPopoverCloseReasonKey];
	if (closeReason)
	{
		// closeReason can be:
		//      NSPopoverCloseReasonStandard
		//      NSPopoverCloseReasonDetachToWindow
		//
		// add new code here if you want to respond "before" the popover closes
		//
	}
}

@end

// NSString *htmlFilePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"HTML5" ofType:@"html"];   NSString *html = [NSString stringWithContentsOfFile:htmlFilePath encoding:NSUTF8StringEncoding error:nil];
//    [aceView setString:[NSString stringWithContentsOfURL:[NSURL URLWithString:@"https://github.com/faceleg/ACEView"] encoding:NSUTF8StringEncoding
//                                                   error:nil]];

//#import "ACEModeNames.h"
//#import "ACEThemeNames.h"
//#import <objc/message.h>
//#import <objc/runtime.h>
//@interface NSControl (Block)
//- (NSControlActionBlock) actionBlock;
//- (void)setActionBlock:(NSControlActionBlock)ab;
//
//@end
//- (void) showAlert:(id)x;
//- (void) reloadURL:(id)x;
//- (void) showPopoverAction:(id)sender;
