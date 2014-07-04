//
//  RKSAppDelegate.m
//  WWDCDownloadableLinkExtractor
//
//  Created by Rahul on 6/4/14.
//  Copyright (c) 2014 RKS. All rights reserved.
//

#import "RKSAppDelegate.h"

@interface NSString (Contains_Category)
- (BOOL) containsString: (NSString*) substring;
@end

@implementation NSString (Contains_Category)
- (BOOL) containsString: (NSString*) substring {
	return ( [self rangeOfString:substring options:NSCaseInsensitiveSearch].location != NSNotFound );
}

@end

@interface RKSAppDelegate ()
@property (weak) IBOutlet NSTextField *urlTextField;
@property (weak) IBOutlet NSButton *getLinksButton;
@property (unsafe_unretained) IBOutlet NSTextView *linksListTextView;

@end

@implementation RKSAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	// Insert code here to initialize your application
}

- (IBAction)getLinks:(id)sender {
	
	if (self.urlTextField.stringValue.length == 0) {
		[[NSAlert alertWithMessageText:@"Invalid URL" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"Please enter a valid URL"] runModal];
	} else {
		// Clear the text view
		[self.linksListTextView setString:@""];
		BOOL foundURL = NO;
		
		NSURL *url = [NSURL URLWithString:self.urlTextField.stringValue];
		NSString *webDataString = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:nil];
		NSString *pattern = @"href=\"(.*?)/?dl=1";
		
		NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern
																			   options:NSRegularExpressionCaseInsensitive
																				 error:nil];
		
		NSArray *matches = [regex matchesInString:webDataString
										  options:0
											range:NSMakeRange(0, [webDataString length])];
		
		NSMutableArray *aHDList = [NSMutableArray array];
		NSMutableArray *aSDList = [NSMutableArray array];
		NSMutableArray *aPDFList = [NSMutableArray array];
		
		for (NSTextCheckingResult *match in matches) {
			foundURL = YES;
			NSRange range = [match rangeAtIndex:1];
			NSString *aURLString = [webDataString substringWithRange:range];
			aURLString = [aURLString substringToIndex:(aURLString.length - 1)];
			
			if ([aURLString containsString:@"_hd"] || [aURLString containsString:@"-hd"]) {
				[aHDList addObject:aURLString];
			} else if ([aURLString containsString:@"_sd"] || [aURLString containsString:@"-sd"]) {
				[aSDList addObject:aURLString];
			} else if ([aURLString containsString:@"pdf"]) {
				[aPDFList addObject:aURLString];
			}
		}
		
		if (foundURL) {
			// Now Loop through all the list and print them in the text view
			[self.linksListTextView insertText:@"\n\nHD List"];
			for (NSString* aLink in aHDList) {
				[self.linksListTextView insertText:[@"\n" stringByAppendingString:aLink]];
			}
			[self.linksListTextView insertText:@"\n\nSD List"];
			for (NSString* aLink in aSDList) {
				[self.linksListTextView insertText:[@"\n" stringByAppendingString:aLink]];
			}
			[self.linksListTextView insertText:@"\n\nPDF List"];
			for (NSString* aLink in aPDFList) {
				[self.linksListTextView insertText:[@"\n" stringByAppendingString:aLink]];
			}
		} else {
			pattern = @"href=\"(.*?)/?mov";
			regex = [NSRegularExpression regularExpressionWithPattern:pattern
															  options:NSRegularExpressionCaseInsensitive
																error:nil];
			matches = [regex matchesInString:webDataString
									 options:0
									   range:NSMakeRange(0, [webDataString length])];
			[self.linksListTextView insertText:@"\n\nVideo List"];
			for (NSTextCheckingResult *match in matches) {
				foundURL = YES;
				NSRange range = [match rangeAtIndex:1];
				NSString *aURLString = [webDataString substringWithRange:range];
				[self.linksListTextView insertText:[@"\n" stringByAppendingString:[aURLString stringByAppendingString:@"mov"]]];
			}
			
			pattern = @"href=\"(.*?)/?pdf";
			regex = [NSRegularExpression regularExpressionWithPattern:pattern
															  options:NSRegularExpressionCaseInsensitive
																error:nil];
			matches = [regex matchesInString:webDataString
									 options:0
									   range:NSMakeRange(0, [webDataString length])];
			[self.linksListTextView insertText:@"\n\nPDF List"];
			for (NSTextCheckingResult *match in matches) {
				foundURL = YES;
				NSRange range = [match rangeAtIndex:1];
				NSString *aURLString = [webDataString substringWithRange:range];
				[self.linksListTextView insertText:[@"\n" stringByAppendingString:[aURLString stringByAppendingString:@"pdf"]]];
			}
		}
	}
}

@end
