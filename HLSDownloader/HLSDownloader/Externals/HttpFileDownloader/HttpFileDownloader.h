//
//  HttpFileDownloader.h
//  PinkArt
//
//  Created by Liu Junqi on 01/11/2016.
//  Copyright © 2016 Liu Junqi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HttpFileDownloadTask.h"

@interface HttpFileDownloader : NSObject

@property (nonatomic) NSString *cacheFolder;

- (id)initWithId:(NSString *)id;
- (id)initWithId:(NSString *)id andCacheFolder:(NSString *)cacheFolder;

- (void)clearDownloadTasks;
- (void)cancelDownload;
- (void)startDownloadInSequence;
- (void)startDownloadSimultaneously;
- (NSString *)addDownload:(NSString *)url completeBlock:(HttpFileDownloadTaskCompleteBlock)completeBlock;
- (NSString *)addDownload:(NSString *)url progressBlock:(HttpFileDownloadTaskProgressBlock)progressBlock completeBlock:(HttpFileDownloadTaskCompleteBlock)completeBlock;
- (void)clearDownloads;
+ (void)clearAllDownloads;
+ (void)clearAllDownloads:(NSString *)cacheFolder;
+ (NSString *)generateFile:(NSString *)url inFolder:(NSString *)folder;
+ (NSString *)generateFile:(NSString *)url inFolder:(NSString *)folder andCacheFolder:(NSString *)cacheFolder;

@end
