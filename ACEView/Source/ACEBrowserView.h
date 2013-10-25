//
//  ACEBrowserView.h
//  ACEView
//
//  Created by Alex Gray on 10/22/13.
//  Copyright (c) 2013 Code of Interest. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
#import <ACEView/ACEView.h>
#import <KFURLBar/KFURLBar.h>
#import "KFURLBar/KFWebKitProgressController.h"
//ACEViewDelegate

@interface ACEBrowserView : NSView <KFURLBarDelegate, NSWindowDelegate,
												KFWebKitProgressDelegate,  NSPopoverDelegate>

@property (nonatomic)			   CGFloat 	 urlBarHeight;
//@property (readonly) NSViewController *vc;


@property 	 		  (strong)    WebView *webView;
@property 	        (strong)   KFURLBar *urlBar;
@property 	 	     (strong) NSSplitView *split;

@property    		  (strong) NSButton 	*reloadB, *alertB, *modeB, *themeB;
@property (nonatomic,strong) NSPopover *modePop, *themePop;

@property 	        (strong)       ACEView * aceView;
@property        (nonatomic)         float   progress;
//@property        (nonatomic)       ACEMode   mode;
//@property        (nonatomic)      ACETheme   theme;

@property (nonatomic, weak) NSString *HTMLString, *URLString;

@end
