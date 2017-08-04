//
//  HLSParser.m
//  HLSDownloader
//
//  Created by Liu Junqi on 01/08/2017.
//  Copyright © 2017 DeviLeo. All rights reserved.
//

#import "HLSParser.h"
#import "HLSDownloader.h"
#import "HLSConstants.h"
#import "HLSErrorDef.h"
#import "HLSUtils.h"

@interface HLSParser ()

@property (nonatomic) HLSDownloader *downloader;

@end

@implementation HLSParser

- (instancetype)initWithURL:(NSString *)urlString {
    self = [super init];
    if (self) {
        self.urlString = urlString;
        [self initVars];
    }
    return self;
}

- (void)initVars {
    self.isHLSFile = NO;
}

- (void)initDownloader {
    __weak typeof(self) weakSelf = self;
    
    HLSDownloader *downloader = [[HLSDownloader alloc] initWithURL:_urlString];
    self.downloader = downloader;
    downloader.downloadBlock = ^(HLSDownloaderStatus status) {
        NSLog(@"downloader status: %zd", status);
    };
    downloader.progressBlock = ^(int64_t bytesWritten, int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite) {
        if ([_delegate respondsToSelector:@selector(HLSParser:dowloaded:totalDownloaded:total:)]) {
            [_delegate HLSParser:weakSelf dowloaded:bytesWritten totalDownloaded:totalBytesWritten total:totalBytesExpectedToWrite];
        }
    };
    downloader.recvDataBlock = ^(NSData *data) {
        if (weakSelf.isHLSFile) return YES;
        BOOL isHLSFile = [HLSUtils determineHLSM3UFromData:data];
        weakSelf.isHLSFile = isHLSFile;
        BOOL continueDownload = NO;
        if ([_delegate respondsToSelector:@selector(HLSParser:detectedFile:)]) {
            continueDownload = [_delegate HLSParser:weakSelf detectedFile:isHLSFile];
        }
        if (!continueDownload) [weakSelf.downloader cancel];
        return continueDownload;
    };
    downloader.completeBlock = ^(HLSDownloaderStatus status, NSString *file, NSError *error) {
        if (![_delegate respondsToSelector:@selector(HLSParser:dowloadedFile:error:)]) return;
        if (status == kHLSDownloaderStatusSuccess) {
            [_delegate HLSParser:weakSelf dowloadedFile:weakSelf.downloader.file error:nil];
            return;
        }
        
        // Handle error
        NSError *hlserror = nil;
        if (status == kHLSDownloaderStatusCancelled) {
            hlserror = [NSError errorWithDomain:HLSErrorDomain code:HLSErrorCodeCancelled userInfo:@{NSLocalizedDescriptionKey:@"Cancelled"}];
        } else {
            hlserror = error;
        }
        [_delegate HLSParser:weakSelf dowloadedFile:nil error:hlserror];
    };
}

#pragma mark - Actions
- (void)startDownloadFile {
    [self.downloader start];
}

- (void)cancelDownloadFile {
    [self.downloader cancel];
}

#pragma mark - Setter / Getter
- (void)setUrlString:(NSString *)urlString {
    _urlString = urlString;
    [self initDownloader];
}

@end
