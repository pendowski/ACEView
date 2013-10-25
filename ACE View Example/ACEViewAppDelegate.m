
#import "ACEViewAppDelegate.h"

@implementation ACEViewAppDelegate
- (void) awakeFromNib {
																		 
	[_syntax bind:@"content" 				 toObject:_aceView.modes  withKeyPath:@"arrangedObjects.name" options:nil];
	[_themes bind:@"content" 				 toObject:_aceView.themes withKeyPath:@"arrangedObjects.name" options:nil];
	[_syntax bind:NSSelectedIndexBinding toObject:_aceView.modes  withKeyPath:@"selectionIndex" 		  options:nil];
	[_themes bind:NSSelectedIndexBinding toObject:_aceView.themes withKeyPath:@"selectionIndex" 	     options:nil];
//   [_aceView setDelegate:																												self];
	[_aceView setStringValue: 				  [NSString stringWithContentsOfFile:[[NSBundle bundleForClass:self.class]
	 													    				   pathForResource:@"HTML5" ofType:@"html"] 
																                   encoding:NSUTF8StringEncoding 	    error:nil]];
}
- (void) textDidChange:(NSNotification*)n {  NSLog(@"%@, %s", n.object, __PRETTY_FUNCTION__); }   // Handle text changes



@end

//	[_syntaxMode selectItemAtIndex:ACEModeHTML];
    
//   [_theme bind:NSContentValuesBinding toObject:aceView.themes withKeyPath:@"arrangedObjects.name" options:nil];
//	[aceView.themes bind:@"selection" toObject:_theme withKeyPath:NSSelectedIndexBinding options:nil];
//	[_theme selectItemAtIndex:ACEThemeXcode];
	
//  [_theme addItemsWithTitles:[ACEThemeNames humanThemeNames]];
//  [syntaxMode addItemsWithTitles:[ACEModeNames humanModeNames]];
//- (IBAction) syntaxModeChanged:(id)sender {
//    [aceView setMode:[syntaxMode indexOfSelectedItem]];
//}
//
//- (IBAction) themeChanged:(id)sender {
//    [aceView setTheme:[theme indexOfSelectedItem]];
//}

//#import "ACEView/ACEModeNames.h"
//#import "ACEView/ACEThemeNames.h"
//
//  AppDelegate.m
//  ACE View Example
//
//  Created by Michael Robinson on 26/08/12.
//  Copyright (c) 2012 Code of Interest. All rights reserved.
//
