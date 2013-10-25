

#import <Cocoa/Cocoa.h>
#import <ACEView/ACEView.h>

@interface              ACEViewAppDelegate : NSObject <NSApplicationDelegate>//, ACEViewDelegate>

@property (assign) IBOutlet       NSWindow * window;
@property   (weak) IBOutlet        ACEView * aceView;
@property   (weak) IBOutlet ACEBrowserView * browserView;
@property   (weak) IBOutlet  NSPopUpButton * syntax, 
													    * themes;
@end
