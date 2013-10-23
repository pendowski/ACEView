//
//  ACEBrowserView.h
//  ACEView
//
//  Created by Alex Gray on 10/22/13.
//  Copyright (c) 2013 Code of Interest. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
#import <ACEView/KFURLBar.h>
#import <ACEView/KFWebKitProgressController.h>
#import <ACEView/ACEView.h>


@interface ACEBrowserView : NSView <KFURLBarDelegate, NSWindowDelegate, 
												KFWebKitProgressDelegate, 
												ACEViewDelegate, NSPopoverDelegate>

@property (nonatomic)			   CGFloat 	 urlBarHeight;
//@property (readonly) NSViewController *vc;


@property     WebView *webView;
@property    KFURLBar *urlBar;
@property NSSplitView *split;

@property 	 NSButton 	*reloadB, *alertB, *modeB, *themeB;
@property 	 NSPopover *modePop, *themePop;

@property 	  ACEView 		*aceView;
@property (nonatomic) float progress;
@property (nonatomic) ACEMode mode;
@property (nonatomic) ACETheme theme;

@property (nonatomic, weak) NSString *HTMLString, *URLString;

@end
