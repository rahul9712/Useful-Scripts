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
@property (weak) IBOutlet NSProgressIndicator *loadingIndicator;

@end

@implementation RKSAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	// Insert code here to initialize your application
	self.loadingIndicator.hidden = YES;
}

- (IBAction)getLinks:(id)sender {
	
	if (self.urlTextField.stringValue.length == 0) {
		[[NSAlert alertWithMessageText:@"Invalid URL" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"Please enter a valid URL"] runModal];
	} else {
		// Clear the text view
		[self.linksListTextView setString:@""];
		__weak RKSAppDelegate *aWeakSelf = self;
		self.loadingIndicator.hidden = NO;
		[self.loadingIndicator startAnimation:nil];
		
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
			__block BOOL foundURL = NO;
			
			NSURL *url = [NSURL URLWithString:aWeakSelf.urlTextField.stringValue];
			NSString *webDataString = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:nil];
			
			NSMutableArray *allComponents = [[webDataString componentsSeparatedByString:@"<a href=\"?"] mutableCopy];
			if (allComponents > 0) [allComponents removeObjectAtIndex:0];
			__block NSMutableArray *aHDDownloadList = [@[] mutableCopy];
			__block NSMutableArray *aSDDownloadList = [@[] mutableCopy];
			__block NSMutableArray *aPDFDownloadList = [@[] mutableCopy];
			
			[allComponents enumerateObjectsUsingBlock:^(NSString *aComponent, NSUInteger idx, BOOL *stop) {
				NSString *match = @"\">";
				NSString *anID = @"";
				NSScanner *scanner = [NSScanner scannerWithString:aComponent];
				[scanner scanUpToString:match intoString:&anID];
				
				if (anID.length > 0) {
					// Now go this page to find the download link
					NSString *currentSessionURLString = [NSString stringWithFormat:@"%@/?%@", aWeakSelf.urlTextField.stringValue, anID];
					NSString *webDataString = [NSString stringWithContentsOfURL:[NSURL URLWithString:currentSessionURLString]
																	   encoding:NSUTF8StringEncoding error:nil];
					
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
					
					if (aHDList.count > 0) [aHDDownloadList addObjectsFromArray:aHDList];
					if (aSDList.count > 0) [aSDDownloadList addObjectsFromArray:aSDList];
					if (aPDFList.count > 0) [aPDFDownloadList addObjectsFromArray:aPDFList];
				}
			}];
			
			foundURL = (aHDDownloadList.count > 0 || aSDDownloadList.count > 0 || aPDFDownloadList.count > 0);
			
			// WWDC 2015
			if (foundURL) {
				dispatch_async(dispatch_get_main_queue(), ^{
					// Now Loop through all the list and print them in the text view
					[aWeakSelf.linksListTextView insertText:@"\n\nHD List"];
					for (NSString* aLink in aHDDownloadList) {
						[aWeakSelf.linksListTextView insertText:[@"\n" stringByAppendingString:aLink]];
					}
					[aWeakSelf.linksListTextView insertText:@"\n\nSD List"];
					for (NSString* aLink in aSDDownloadList) {
						[aWeakSelf.linksListTextView insertText:[@"\n" stringByAppendingString:aLink]];
					}
					[aWeakSelf.linksListTextView insertText:@"\n\nPDF List"];
					for (NSString* aLink in aPDFDownloadList) {
						[aWeakSelf.linksListTextView insertText:[@"\n" stringByAppendingString:aLink]];
					}
					
					self.loadingIndicator.hidden = YES;
					[self.loadingIndicator stopAnimation:nil];
				});
			} else {
				__block NSString *pattern = @"href=\"(.*?)/?dl=1";
				
				__block NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern
																					   options:NSRegularExpressionCaseInsensitive
																						 error:nil];
				
				__block NSArray *matches = [regex matchesInString:webDataString
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
				
				// WWDC 2014
				if (foundURL) {
					dispatch_async(dispatch_get_main_queue(), ^{
						// Now Loop through all the list and print them in the text view
						[aWeakSelf.linksListTextView insertText:@"\n\nHD List"];
						for (NSString* aLink in aHDList) {
							[aWeakSelf.linksListTextView insertText:[@"\n" stringByAppendingString:aLink]];
						}
						[aWeakSelf.linksListTextView insertText:@"\n\nSD List"];
						for (NSString* aLink in aSDList) {
							[aWeakSelf.linksListTextView insertText:[@"\n" stringByAppendingString:aLink]];
						}
						[aWeakSelf.linksListTextView insertText:@"\n\nPDF List"];
						for (NSString* aLink in aPDFList) {
							[aWeakSelf.linksListTextView insertText:[@"\n" stringByAppendingString:aLink]];
						}
						
						self.loadingIndicator.hidden = YES;
						[self.loadingIndicator stopAnimation:nil];
					});
				} else {
					// WWDC 2013 or older
					dispatch_async(dispatch_get_main_queue(), ^{
						pattern = @"href=\"(.*?)/?mov";
						regex = [NSRegularExpression regularExpressionWithPattern:pattern
																		  options:NSRegularExpressionCaseInsensitive
																			error:nil];
						matches = [regex matchesInString:webDataString
												 options:0
												   range:NSMakeRange(0, [webDataString length])];
						[aWeakSelf.linksListTextView insertText:@"\n\nVideo List"];
						for (NSTextCheckingResult *match in matches) {
							foundURL = YES;
							NSRange range = [match rangeAtIndex:1];
							NSString *aURLString = [webDataString substringWithRange:range];
							[aWeakSelf.linksListTextView insertText:[@"\n" stringByAppendingString:[aURLString stringByAppendingString:@"mov"]]];
						}
						
						pattern = @"href=\"(.*?)/?pdf";
						regex = [NSRegularExpression regularExpressionWithPattern:pattern
																		  options:NSRegularExpressionCaseInsensitive
																			error:nil];
						matches = [regex matchesInString:webDataString
												 options:0
												   range:NSMakeRange(0, [webDataString length])];
						[aWeakSelf.linksListTextView insertText:@"\n\nPDF List"];
						for (NSTextCheckingResult *match in matches) {
							foundURL = YES;
							NSRange range = [match rangeAtIndex:1];
							NSString *aURLString = [webDataString substringWithRange:range];
							[aWeakSelf.linksListTextView insertText:[@"\n" stringByAppendingString:[aURLString stringByAppendingString:@"pdf"]]];
						}
						
						self.loadingIndicator.hidden = YES;
						[self.loadingIndicator stopAnimation:nil];
					});
				}
			}
		});
	}
}

@end
