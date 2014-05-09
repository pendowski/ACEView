
//  ACEBrowserView.h ACEView
//  Created by Alex Gray on 10/22/13.
//  Copyright (c) 2013 Code of Interest. All rights reserved.


#import <ACEView/KFURLBar.h>
#import <ACEView/KFWebKitProgressController.h>

@class ACEView; @interface ACEBrowserView : NSView

@property NSString* mainFrameURL;
//- (void) setMainFrameURL:(NSString*)s;

@property (nonatomic,copy)    NSString * HTMLString,
                                       * URLString;
@property      (nonatomic)   NSPopover * modePop,
                                       * themePop;
@property      (nonatomic)     CGFloat   progress,
                                         urlBarHeight;

@property       (readonly)    KFURLBar * urlBar;
@property       (readonly)    NSButton * reloadB, *alertB, *modeB, *themeB;
@property       (readonly) NSSplitView * split;
@property       (readonly)     WebView * webView;
@property 	    (readonly)     ACEView * aceView;

+ (BOOL) stringIsValidURL:(NSString*)s;

@end
//@property (readonly) NSViewController *vc;
//@property        (nonatomic)       ACEMode   mode;
//@property        (nonatomic)      ACETheme   theme;
