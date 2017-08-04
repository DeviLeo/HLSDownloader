//
//  HttpFileDownloader.m
//  PinkArt
//
//  Created by Liu Junqi on 01/11/2016.
//  Copyright © 2016 Liu Junqi. All rights reserved.
//

#import "HttpFileDownloader.h"

#define DEFAULT_CACHE_FOLDER @"cache"

@interface HttpFileDownloader ()

@property (nonatomic) NSString *id;
@property (nonatomic) BOOL downloadStarted;
@property (nonatomic) NSMutableArray *downloadTasks;

@end

@implementation HttpFileDownloader

- (id)initWithId:(NSString *)id {
    self = [super init];
    if (self) {
        self.cacheFolder = DEFAULT_CACHE_FOLDER;
        self.id = id;
        self.downloadStarted = NO;
        self.downloadTasks = nil;
    }
    return self;
}

- (id)initWithId:(NSString *)id andCacheFolder:(NSString *)cacheFolder {
    self = [super init];
    if (self) {
        self.cacheFolder = cacheFolder;
        self.id = id;
        self.downloadStarted = NO;
        self.downloadTasks = nil;
    }
    return self;
}

+ (void)clearAllDownloads {
    [HttpFileDownloader clearAllDownloads:nil];
}

+ (void)clearAllDownloads:(NSString *)cacheFolder {
    if (cacheFolder == nil) cacheFolder = DEFAULT_CACHE_FOLDER;
    NSArray *dirs = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docDir = [dirs objectAtIndex:0];
    NSString *cacheDir = [docDir stringByAppendingPathComponent:cacheFolder];
    
    NSError *error = nil;
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm removeItemAtPath:cacheDir error:&error]) {
        NSLog(@"removeItemAtPath: %@, error: %@", cacheDir, error);
    }
}

- (void)clearDownloads {
    [self clearDownloadsById:self.id];
}

- (void)clearDownloadsById:(NSString *)id {
    if (id == nil) return;
    NSArray *dirs = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docDir = [dirs objectAtIndex:0];
    NSString *cacheDir = [docDir stringByAppendingPathComponent:_cacheFolder];
    NSString *downloaderDir = [cacheDir stringByAppendingPathComponent:id];
    
    NSError *error = nil;
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm removeItemAtPath:downloaderDir error:&error]) {
        NSLog(@"removeItemAtPath: %@, error: %@", downloaderDir, error);
    }
}

- (NSString *)addDownload:(NSString *)url completeBlock:(HttpFileDownloadTaskCompleteBlock)completeBlock {
    return [self addDownload:url progressBlock:nil completeBlock:completeBlock];
}

- (NSString *)addDownload:(NSString *)url progressBlock:(HttpFileDownloadTaskProgressBlock)progressBlock completeBlock:(HttpFileDownloadTaskCompleteBlock)completeBlock {
    if (self.downloadTasks == nil) self.downloadTasks = [[NSMutableArray alloc] init];
    
    NSString *file = [HttpFileDownloader generateFile:url inFolder:self.id];
    if (file == nil) return nil;
    
    NSString *id = [[NSUUID UUID] UUIDString];
    HttpFileDownloadTask *task = [[HttpFileDownloadTask alloc] init];
    task.tid = id;
    task.url = url;
    task.file = file;
    task.completeBlock = completeBlock;
    task.progressBlock = progressBlock;
    
    @synchronized(_downloadTasks) {
        [_downloadTasks addObject:task];
    }
    
    return id;
}

- (void)startDownloadSimultaneously {
    if (self.downloadStarted || self.downloadTasks == nil || self.downloadTasks.count == 0) return;
    self.downloadStarted = YES;
    @synchronized(_downloadTasks) {
        do {
            HttpFileDownloadTask *task = [_downloadTasks objectAtIndex:0];
            [self download:task inSequence:NO];
            [_downloadTasks removeObjectAtIndex:0];
        } while (_downloadTasks.count > 0);
        self.downloadStarted = NO;
    }
}

- (void)startDownloadInSequence {
    if (self.downloadStarted || self.downloadTasks == nil || self.downloadTasks.count == 0) return;
    self.downloadStarted = YES;
    [self downloadNext];
}

- (void)cancelDownload {
    self.downloadStarted = NO;
}

- (void)clearDownloadTasks {
    @synchronized(_downloadTasks) {
        [_downloadTasks removeAllObjects];
    }
}

- (void)download:(HttpFileDownloadTask *)task inSequence:(BOOL)inSequence {
    @synchronized(task) {
        if (task.downloading) return;
        
        HttpFileDownloadTaskDownloadBlock downloadBlock = ^(HttpFileDownloadTaskStatus status) {
            HttpFileDownloadTaskCompleteBlock completeBlock = task.completeBlock;
            if (completeBlock != nil) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completeBlock(status, task.file);
                });
            }
            if (inSequence) [self downloadNext];
        };
        
        task.downloadBlock = downloadBlock;
        [task start];
    }
}

- (void)downloadNext {
    if (!self.downloadStarted) return;
    @synchronized(_downloadTasks) {
        NSInteger count = _downloadTasks.count;
        if (count <= 0) { self.downloadStarted = NO; return; }
        HttpFileDownloadTask *task = [_downloadTasks objectAtIndex:0];
        [self download:task inSequence:YES];
        [_downloadTasks removeObjectAtIndex:0];
    }
}

+ (NSString *)generateFile:(NSString *)url inFolder:(NSString *)folder {
    return [HttpFileDownloader generateFile:url inFolder:folder andCacheFolder:nil];
}

+ (NSString *)generateFile:(NSString *)url inFolder:(NSString *)folder andCacheFolder:(NSString *)cacheFolder {
    NSString *filename = [HttpFileDownloader getFileNameFromUrl:url];
    if (filename == nil) return nil;
    NSString *file = [HttpFileDownloader getFile:filename inFolder:folder andCacheFolder:cacheFolder];
    return file;
}

+ (NSString *)getFile:(NSString *)filename inFolder:(NSString *)folder andCacheFolder:(NSString *)cacheFolder {
    if (cacheFolder == nil) cacheFolder = DEFAULT_CACHE_FOLDER;
    NSArray *dirs = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docDir = [dirs objectAtIndex:0];
    NSString *cacheDir = [docDir stringByAppendingPathComponent:cacheFolder];
    NSString *downloaderDir = folder == nil ? cacheDir : [cacheDir stringByAppendingPathComponent:folder];
    
    NSString *file = nil;
    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:downloaderDir]) {
        file = [downloaderDir stringByAppendingPathComponent:filename];
    } else if ([fm createDirectoryAtPath:downloaderDir withIntermediateDirectories:YES attributes:nil error:nil]) {
        file = [downloaderDir stringByAppendingPathComponent:filename];
    } else {
        file = [cacheDir stringByAppendingPathComponent:filename];
    }
    
    return file;
}

+ (NSString *)getFileNameFromUrl:(NSString *)url {
    NSRange range = [url rangeOfString:@"/" options:NSBackwardsSearch];
    if (range.location == NSNotFound) return nil;
    NSString *filename = [url substringFromIndex:range.location + 1];
    return filename;
}

@end
