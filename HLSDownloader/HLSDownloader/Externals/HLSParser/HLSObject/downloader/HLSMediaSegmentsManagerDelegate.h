//
//  HLSMediaSegmentsManagerDelegate.h
//  HLSDownloader
//
//  Created by Liu Junqi on 03/08/2017.
//  Copyright © 2017 DeviLeo. All rights reserved.
//

#import <Foundation/Foundation.h>

@class HLSMediaSegment;
@class HLSMediaSegmentsManager;

@protocol HLSMediaSegmentsManagerDelegate <NSObject>

@optional
- (void)HLSMediaSegmentsManager:(HLSMediaSegmentsManager *)manager willDownloadSegment:(HLSMediaSegment *)segment;
- (void)HLSMediaSegment:(HLSMediaSegment *)segment dowloadedFile:(NSString *)file error:(NSError *)error;
- (void)HLSMediaSegment:(HLSMediaSegment *)segment dowloaded:(int64_t)bytesWritten totalDownloaded:(int64_t)totalBytesWritten total:(int64_t)totalBytesExpectedToWrite;
- (void)HLSMediaSegmentsManagerAllDownloaded:(HLSMediaSegmentsManager *)manager;

@end
