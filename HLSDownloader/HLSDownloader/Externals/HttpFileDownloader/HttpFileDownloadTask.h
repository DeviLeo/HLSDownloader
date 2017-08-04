//
//  HttpFileDownloadTask.h
//  PinkArt
//
//  Created by Liu Junqi on 01/11/2016.
//  Copyright © 2016 Liu Junqi. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum : NSUInteger {
    kHttpFileDownloadTaskStatusDownloading = -2,
    kHttpFileDownloadTaskStatusError = -1,
    kHttpFileDownloadTaskStatusNone = 0,
    kHttpFileDownloadTaskStatusSuccess = 1,
} HttpFileDownloadTaskStatus;

typedef void (^HttpFileDownloadTaskDownloadBlock)(HttpFileDownloadTaskStatus status);
typedef void (^HttpFileDownloadTaskCompleteBlock)(HttpFileDownloadTaskStatus status, NSString *file);
typedef void (^HttpFileDownloadTaskProgressBlock)(int64_t bytesWritten, int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite);

@interface HttpFileDownloadTask : NSObject

@property (nonatomic) NSString *tid;
@property (nonatomic) NSString *url;
@property (nonatomic) NSString *file;
@property (nonatomic) BOOL downloading;
@property (nonatomic, strong) HttpFileDownloadTaskDownloadBlock downloadBlock;
@property (nonatomic, strong) HttpFileDownloadTaskCompleteBlock completeBlock;
@property (nonatomic, strong) HttpFileDownloadTaskProgressBlock progressBlock;

- (void)start;

@end
