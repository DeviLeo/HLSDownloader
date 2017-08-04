//
//  HLSParserDelegate.h
//  HLSDownloader
//
//  Created by Liu Junqi on 01/08/2017.
//  Copyright © 2017 DeviLeo. All rights reserved.
//

#import <Foundation/Foundation.h>

@class HLSParser;

@protocol HLSParserDelegate <NSObject>

// return YES, continue downloading the file.
// return NO, stop downloading the file.
- (BOOL)HLSParser:(HLSParser *)parser detectedFile:(BOOL)valid;
- (void)HLSParser:(HLSParser *)parser dowloadedFile:(NSString *)file error:(NSError *)error;
- (void)HLSParser:(HLSParser *)parser dowloaded:(int64_t)bytesWritten totalDownloaded:(int64_t)totalBytesWritten total:(int64_t)totalBytesExpectedToWrite;

@end
