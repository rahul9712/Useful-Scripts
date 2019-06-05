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
		
        NSURL *url = [NSURL URLWithString:aWeakSelf.urlTextField.stringValue];
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
			NSString *webDataString = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:nil];
			
            
            [aWeakSelf
             wwdcDownloadURLsFromString:webDataString
             fromURL:url.absoluteString
             withCompletionBlock:^(NSArray *hdVideoList, NSArray *sdVideoList, NSArray *pdfList) {
                 if (hdVideoList.count > 0 || sdVideoList.count > 0 || pdfList.count > 0) {
                     dispatch_async(dispatch_get_main_queue(), ^{
                         // Now Loop through all the list and print them in the text view
                         if (hdVideoList.count > 0) {
                             [aWeakSelf.linksListTextView insertText:@"\n\nHD List"];
                             for (NSString* aLink in hdVideoList) { [aWeakSelf.linksListTextView insertText:[@"\n" stringByAppendingString:aLink]]; }
                         }
                         if (sdVideoList.count > 0) {
                             [aWeakSelf.linksListTextView insertText:@"\n\nSD List"];
                             for (NSString* aLink in sdVideoList) { [aWeakSelf.linksListTextView insertText:[@"\n" stringByAppendingString:aLink]]; }
                         }
                         if (pdfList.count > 0) {
                             [aWeakSelf.linksListTextView insertText:@"\n\nPDF List"];
                             for (NSString* aLink in pdfList) { [aWeakSelf.linksListTextView insertText:[@"\n" stringByAppendingString:aLink]]; }
                         }
                         
                         self.loadingIndicator.hidden = YES;
                         [self.loadingIndicator stopAnimation:nil];
                     });
                 } else {
                     [aWeakSelf wwdc2014DeveloperURLsFromWebsiteString:webDataString withCompletionBlock:^(NSArray *hdVideoList, NSArray *sdVideoList, NSArray *pdfList) {
                         if (hdVideoList.count > 0 || sdVideoList.count > 0 || pdfList.count > 0) {
                             dispatch_async(dispatch_get_main_queue(), ^{
                                 // Now Loop through all the list and print them in the text view
                                 [aWeakSelf.linksListTextView insertText:@"\n\nHD List"];
                                 for (NSString* aLink in hdVideoList) { [aWeakSelf.linksListTextView insertText:[@"\n" stringByAppendingString:aLink]]; }
                                 [aWeakSelf.linksListTextView insertText:@"\n\nSD List"];
                                 for (NSString* aLink in sdVideoList) { [aWeakSelf.linksListTextView insertText:[@"\n" stringByAppendingString:aLink]]; }
                                 [aWeakSelf.linksListTextView insertText:@"\n\nPDF List"];
                                 for (NSString* aLink in pdfList) { [aWeakSelf.linksListTextView insertText:[@"\n" stringByAppendingString:aLink]]; }
                                 
                                 self.loadingIndicator.hidden = YES;
                                 [self.loadingIndicator stopAnimation:nil];
                             });
                         } else {
                             [aWeakSelf wwdc2013DeveloperURLsFromWebsiteString:webDataString withCompletionBlock:^(NSArray *videoList, NSArray *pdfList) {
                                 if (videoList.count > 0 || pdfList.count > 0) {
                                     dispatch_async(dispatch_get_main_queue(), ^{
                                         if (videoList.count > 0) {
                                             [aWeakSelf.linksListTextView insertText:@"\n\nVideo List\n"];
                                             [aWeakSelf.linksListTextView insertText:[videoList componentsJoinedByString:@"\n"]];
                                         }
                                         if (pdfList.count > 0) {
                                             [aWeakSelf.linksListTextView insertText:@"\n\nPDF List\n"];
                                             [aWeakSelf.linksListTextView insertText:[pdfList componentsJoinedByString:@"\n"]];
                                         }
                                         self.loadingIndicator.hidden = YES;
                                         [self.loadingIndicator stopAnimation:nil];
                                     });
                                 }
                             }];
                         }
                     }];
                 }
             }];
		});
	}
}

// https://developer.apple.com/videos/wwdc2019/
// https://developer.apple.com/videos/wwdc2018/
// https://developer.apple.com/videos/wwdc2017/
// https://developer.apple.com/videos/wwdc2016/
// https://developer.apple.com/videos/wwdc2015/
- (void) wwdcDownloadURLsFromString:(NSString *) websiteString
                            fromURL:(NSString *) urlOfPage
                withCompletionBlock:(void (^)(NSArray *hdVideoList, NSArray *sdVideoList, NSArray *pdfList))block {
    NSMutableArray *allComponents = [[websiteString componentsSeparatedByString:@"<a href=\"/videos/play/wwdc"] mutableCopy];
    if (allComponents > 0) {
        [allComponents removeObjectAtIndex:0];
        [allComponents removeObjectAtIndex:0];
    }
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
            NSString *currentSessionURLString = [NSString stringWithFormat:@"%@?/videos/play/wwdc%@", urlOfPage, anID];
            NSString *webDataString = [NSString stringWithContentsOfURL:[NSURL URLWithString:currentSessionURLString]
                                                               encoding:NSUTF8StringEncoding error:nil];
            
            NSString *pattern = @"href=\"(.*?)/?dl=1";
            NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                                                   options:NSRegularExpressionCaseInsensitive
                                                                                     error:nil];
            NSArray *matches = [regex matchesInString:webDataString options:0 range:NSMakeRange(0, [webDataString length])];
            BOOL prefixDevStramURL = FALSE;
            BOOL prefixDevloperURL = FALSE;
            
            // 2014 / 2013
            if (matches.count == 0) {
                NSString *pattern = @"href=\"http://devstreaming.apple.com(.*)\">";
                
                NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                                                       options:NSRegularExpressionCaseInsensitive
                                                                                         error:nil];
                
                matches = [regex matchesInString:webDataString options:0 range:NSMakeRange(0, [webDataString length])];
                prefixDevStramURL = (matches.count > 0);
            }
            
            // 2012
            if (matches.count == 0) {
                NSString *pattern = @"href=\"https://developer.apple.com(.*)\">";
                
                NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                                                       options:NSRegularExpressionCaseInsensitive
                                                                                         error:nil];
                
                matches = [regex matchesInString:webDataString options:0 range:NSMakeRange(0, [webDataString length])];
                prefixDevloperURL = (matches.count > 0);
            }
            
            if (matches.count > 0) {
                NSMutableArray *aHDList = [NSMutableArray array];
                NSMutableArray *aSDList = [NSMutableArray array];
                NSMutableArray *aPDFList = [NSMutableArray array];
                
                for (NSTextCheckingResult *match in matches) {
                    NSRange range = [match rangeAtIndex:1];
                    if (range.length == 0) range = [match rangeAtIndex:0];
                    
                    NSString *aURLString = [webDataString substringWithRange:range];
                    if (prefixDevStramURL) { aURLString = [NSString stringWithFormat:@"http://devstreaming.apple.com/%@", aURLString]; }
                    if (prefixDevloperURL) { aURLString = [NSString stringWithFormat:@"https://developer.apple.com/%@", aURLString]; }
                    else { aURLString = [aURLString substringToIndex:(aURLString.length - 1)]; }
                    
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
        }
    }];
    
    if (block != nil) {
        block(aHDDownloadList, aSDDownloadList, aPDFDownloadList);
    }
}

// https://developer.apple.com/videos/wwdc2014/
- (void) wwdc2014DeveloperURLsFromWebsiteString:(NSString *) websiteString withCompletionBlock:(void (^)(NSArray *hdVideoList, NSArray *sdVideoList, NSArray *pdfList))block {
    __block NSString *pattern = @"href=\"(.*?)/?dl=1";
				
    __block NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                                                   options:NSRegularExpressionCaseInsensitive
                                                                                     error:nil];
				
    __block NSArray *matches = [regex matchesInString:websiteString
                                              options:0
                                                range:NSMakeRange(0, [websiteString length])];
				
    NSMutableArray *aHDList = [NSMutableArray array];
    NSMutableArray *aSDList = [NSMutableArray array];
    NSMutableArray *aPDFList = [NSMutableArray array];
				
    for (NSTextCheckingResult *match in matches) {
        NSRange range = [match rangeAtIndex:1];
        NSString *aURLString = [websiteString substringWithRange:range];
        aURLString = [aURLString substringToIndex:(aURLString.length - 1)];
        
        if ([aURLString containsString:@"_hd"] || [aURLString containsString:@"-hd"]) {
            [aHDList addObject:aURLString];
        } else if ([aURLString containsString:@"_sd"] || [aURLString containsString:@"-sd"]) {
            [aSDList addObject:aURLString];
        } else if ([aURLString containsString:@"pdf"]) {
            [aPDFList addObject:aURLString];
        }
    }
    
    if (block != nil) {
        block(aHDList, aSDList, aPDFList);
    }
}

- (void) wwdc2013DeveloperURLsFromWebsiteString:(NSString *) websiteString withCompletionBlock:(void (^)(NSArray *videoList, NSArray *pdfList))block {
    NSString *pattern = @"href=\"(.*?)/?mov";
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                      options:NSRegularExpressionCaseInsensitive
                                                        error:nil];
    NSArray *matches = [regex matchesInString:websiteString
                             options:0
                               range:NSMakeRange(0, [websiteString length])];
    NSMutableArray *videoList = [NSMutableArray array];
    NSMutableArray *pdfList = [NSMutableArray array];
    
    for (NSTextCheckingResult *match in matches) {
        NSRange range = [match rangeAtIndex:1];
        NSString *aURLString = [websiteString substringWithRange:range];
        [videoList addObject:[aURLString stringByAppendingString:@"mov"]];
    }
    
    pattern = @"href=\"(.*?)/?pdf";
    regex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                      options:NSRegularExpressionCaseInsensitive
                                                        error:nil];
    matches = [regex matchesInString:websiteString
                             options:0
                               range:NSMakeRange(0, [websiteString length])];
    
    for (NSTextCheckingResult *match in matches) {
        NSRange range = [match rangeAtIndex:1];
        NSString *aURLString = [websiteString substringWithRange:range];
        [pdfList addObject:[aURLString stringByAppendingString:@"pdf"]];
    }
    
    if (block != nil) {
        block(videoList, pdfList);
    }
}

@end
