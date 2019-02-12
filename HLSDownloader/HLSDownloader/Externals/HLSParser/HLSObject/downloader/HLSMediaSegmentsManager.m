//
//  HLSMediaSegmentsManager.m
//  HLSDownloader
//
//  Created by Liu Junqi on 02/08/2017.
//  Copyright © 2017 DeviLeo. All rights reserved.
//

#import "HLSMediaSegmentsManager.h"
#import "HLSDownloader.h"
#import "HLSMediaSegment.h"
#import "HLSErrorDef.h"

@interface HLSMediaSegmentsManager ()

@property (nonatomic) NSMutableArray<HLSMediaSegment *> *segments;
@property (nonatomic) NSMutableArray<HLSDownloader *> *downloader;
@property (nonatomic) BOOL downloading;
@property (nonatomic) BOOL cancelled;
@property (nonatomic) NSInteger downloadedCount;
@property (nonatomic) NSInteger downloadIndex;

@end

@implementation HLSMediaSegmentsManager

- (instancetype)init {
    self = [super init];
    if (self) {
        [self initVars];
    }
    return self;
}

- (void)initVars {
    self.segments = [NSMutableArray arrayWithCapacity:8];
    self.downloader = [NSMutableArray arrayWithCapacity:8];
    self.downloading = NO;
    self.cancelled = YES;
    self.downloadedCount = 0;
    self.multithread = NO;
    self.maxThreads = 5;
    self.downloadIndex = 0;
}

- (void)startDownloading {
    if (self.downloading) return;
    self.downloadedCount = 0;
    self.downloadIndex = 0;
    self.cancelled = NO;
    
    if (self.multithread) {
        [self downloadSimultaneously];
    } else {
        [self downloadNext];
    }
}

- (void)cancelAllDownloads {
    self.cancelled = YES;
    for (NSInteger i = 0; i < self.downloader.count; ++i) {
        HLSDownloader *downloader = self.downloader[i];
        [downloader cancel];
    }
    self.downloading = NO;
    [self clearAllDownloads];
}

- (void)clearAllDownloads {
    [self.downloader removeAllObjects];
    [self.segments removeAllObjects];
}

- (void)allDownloaded {
    if ([_delegate respondsToSelector:@selector(HLSMediaSegmentsManagerAllDownloaded:)]) {
        [_delegate HLSMediaSegmentsManagerAllDownloaded:self];
    }
}

- (void)willDownload:(HLSMediaSegment *)segment {
    if ([_delegate respondsToSelector:@selector(HLSMediaSegmentsManager:willDownloadSegment:)]) {
        [_delegate HLSMediaSegmentsManager:self willDownloadSegment:segment];
    }
}

- (void)downloadNext {
    if (self.cancelled || self.segments.count == 0) {
        [self allDownloaded];
        return;
    }
    
    self.downloading = YES;
    HLSMediaSegment *segment = [self.segments firstObject];
    HLSDownloader *downloader = [self createDownloader:segment];
    [self.downloader addObject:downloader];
    [self willDownload:segment];
    [downloader start];
}

- (void)downloadSegment:(HLSMediaSegment *)segment {
    HLSDownloader *downloader = [self createDownloader:segment];
    [self.downloader addObject:downloader];
    [self willDownload:segment];
    [downloader start];
}

- (void)downloadSimultaneously {
    if (!self.multithread) return;
    NSArray *segments = self.segments;
    NSInteger segmentsCount = segments.count;
    if (self.downloadIndex >= self.segments.count) return;
    NSInteger current = self.downloader.count;
    if (current >= self.maxThreads) return;
    while (self.downloadIndex < segmentsCount &&
           current < self.maxThreads) {
        HLSMediaSegment *segment = segments[self.downloadIndex];
        [self downloadSegment:segment];
        ++self.downloadIndex;
        ++current;
    }
}

- (void)addSegment:(HLSMediaSegment *)segment {
    [self.segments addObject:segment];
    if (self.multithread) { return; }
    if (!_cancelled && !_downloading) [self downloadNext];
}

- (HLSDownloader *)createDownloader:(HLSMediaSegment *)segment {
    __weak typeof(self) weakSelf = self;
    
    HLSDownloader *downloader = [[HLSDownloader alloc] initWithURL:segment.url];
    __weak typeof(downloader) weakDownloader = downloader;
    downloader.downloadBlock = ^(HLSDownloaderStatus status) {
        NSLog(@"downloader status: %zd", status);
    };
    downloader.progressBlock = ^(int64_t bytesWritten, int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite) {
        if ([weakSelf.delegate respondsToSelector:@selector(HLSMediaSegment:dowloaded:totalDownloaded:total:)]) {
            [weakSelf.delegate HLSMediaSegment:segment dowloaded:bytesWritten totalDownloaded:totalBytesWritten total:totalBytesExpectedToWrite];
        }
    };
    downloader.completeBlock = ^(HLSDownloaderStatus status, NSString *file, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            // After [weakSelf deleteDownloader:weakDownloader]; is called,
            // weakDownloader will be nil.
            // If downloader.completeBlock is called again because of some unknown bugs,
            // the block should return immediately to avoid more bugs occure.
            if (weakDownloader == nil) return;
            
            if (status == kHLSDownloaderStatusSuccess) {
                if ([weakSelf.delegate respondsToSelector:@selector(HLSMediaSegment:dowloadedFile:error:)]) {
                    [weakSelf.delegate HLSMediaSegment:segment dowloadedFile:file error:nil];
                }
            } else {
                // Handle error
                NSError *hlserror = nil;
                if (status == kHLSDownloaderStatusCancelled) {
                    hlserror = [NSError errorWithDomain:HLSErrorDomain code:HLSErrorCodeCancelled userInfo:@{NSLocalizedDescriptionKey:@"Cancelled"}];
                } else {
                    hlserror = error;
                }
                if ([weakSelf.delegate respondsToSelector:@selector(HLSMediaSegment:dowloadedFile:error:)]) {
                    [weakSelf.delegate HLSMediaSegment:segment dowloadedFile:nil error:hlserror];
                }
            }
            [weakSelf deleteDownloader:weakDownloader];
            if (weakSelf.multithread) {
                ++weakSelf.downloadedCount;
                [weakSelf downloadSimultaneously];
                if (weakSelf.cancelled || weakSelf.segments.count == weakSelf.downloadedCount) {
                    weakSelf.downloading = NO;
                    [self clearAllDownloads];
                    [self allDownloaded];
                    return;
                }
            } else {
                [weakSelf deleteSegment:segment];
                weakSelf.downloading = NO;
                [weakSelf downloadNext];
            }
        });
    };
    return downloader;
}

- (void)deleteDownloader:(HLSDownloader *)downloader {
    [self.downloader removeObject:downloader];
}

- (void)deleteSegment:(HLSMediaSegment *)segment {
    [self.segments removeObject:segment];
}

@end
