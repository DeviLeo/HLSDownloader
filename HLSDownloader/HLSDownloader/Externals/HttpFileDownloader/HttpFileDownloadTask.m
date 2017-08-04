//
//  HttpFileDownloadTask.m
//  PinkArt
//
//  Created by Liu Junqi on 01/11/2016.
//  Copyright © 2016 Liu Junqi. All rights reserved.
//

#import "HttpFileDownloadTask.h"

@interface HttpFileDownloadTask () <NSURLSessionDataDelegate, NSURLSessionDownloadDelegate>

@end

@implementation HttpFileDownloadTask

- (void)start {
    HttpFileDownloadTaskStatus status = kHttpFileDownloadTaskStatusNone;
    
    if (self.downloading) {
        status = kHttpFileDownloadTaskStatusDownloading;
        [self invokeDownloadBlock:status];
    }
    self.downloading = YES;
    [self download];
}

/*
 * 本地文件不存在或大小不正确时，需重新下载
 * 服务器文件存在且类型正确且长度正确，但与本地文件大小不同时，需重新下载
 * 服务器文件不存在或类型不正确或长度不正确时，但本地文件存在且大小正确时，无需重新下载
 * 服务器文件存在且类型正确且长度正确，同时与本地文件大小相同，无需重新下载
 */
- (void)download {
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    configuration.allowsCellularAccess = YES;
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:nil];
    NSString *encodedURL = [self.url stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    NSURL *url = [NSURL URLWithString:encodedURL];
    NSURLSessionDataTask *dataTask = [session dataTaskWithURL:url];
    [dataTask resume];
}

- (void)invokeDownloadBlock:(HttpFileDownloadTaskStatus)status {
    if (self.downloadBlock != nil) self.downloadBlock(status);
}

#pragma mark - NSURLSessionDataDelegate
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    NSURLSessionResponseDisposition disposition = NSURLSessionResponseCancel;
    HttpFileDownloadTaskStatus status = kHttpFileDownloadTaskStatusError;
    
    NSInteger localSize = [HttpFileDownloadTask sizeOfFile:self.file];
    NSInteger statusCode = ((NSHTTPURLResponse *)response).statusCode;
    NSString *mimeType = response.MIMEType;
    NSInteger contentLength = (NSInteger)response.expectedContentLength;
    BOOL isImage = [mimeType hasPrefix:@"image"];
    if (statusCode == 200 && isImage && contentLength > 0) {
        if (contentLength == localSize) {
            status = kHttpFileDownloadTaskStatusSuccess;
        } else {
            disposition = NSURLSessionResponseBecomeDownload;
        }
    }
    completionHandler(disposition);
    if (disposition == NSURLSessionResponseCancel) {
        [self invokeDownloadBlock:status];
        self.downloading = NO;
        [session finishTasksAndInvalidate];
    }
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didBecomeDownloadTask:(NSURLSessionDownloadTask *)downloadTask {
    
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    if (self.progressBlock != nil) self.progressBlock(bytesWritten, totalBytesWritten, totalBytesExpectedToWrite);
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location {
    HttpFileDownloadTaskStatus status = kHttpFileDownloadTaskStatusError;
    NSURL *fileURL = [NSURL fileURLWithPath:self.file];
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *locationPath = [location path];
    BOOL locationExists = [fm fileExistsAtPath:locationPath];
    if (locationExists) {
        BOOL move = YES;
        BOOL exists = [fm fileExistsAtPath:self.file];
        NSError *error = nil;
        if (exists) {
            NSInteger fileSize = [HttpFileDownloadTask sizeOfFile:self.file];
            NSInteger locationSize = [HttpFileDownloadTask sizeOfFile:locationPath];
            if (fileSize == locationSize) {
                move = NO;
                status = kHttpFileDownloadTaskStatusSuccess;
                NSLog(@"File Size is same, do nothing. Filename: %@", self.file);
            } else if (![fm removeItemAtURL:fileURL error:&error]) {
                NSLog(@"removeItemAtURL: %@, Error: %@", fileURL, error);
            }
        }
        if (move) {
            if ([fm moveItemAtURL:location toURL:fileURL error:&error]) {
                status = kHttpFileDownloadTaskStatusSuccess;
            } else {
                NSLog(@"moveItemAtURL: %@, toURL: %@, Error: %@", location, fileURL, error);
            }
        }
    } else {
        NSLog(@"location file does not exist: %@", locationPath);
    }
    [self invokeDownloadBlock:status];
    self.downloading = NO;
    [session finishTasksAndInvalidate];
}

#pragma mark - Utils
+ (NSInteger)sizeOfFile:(NSString *)file {
    NSInteger fileSize = -1;
    
    NSFileManager *fm = [NSFileManager defaultManager];
    NSError *error = nil;
    BOOL isDirectory = NO;
    if ([fm fileExistsAtPath:file isDirectory:&isDirectory]) {
        if (!isDirectory) {
            NSDictionary *dict = [fm attributesOfItemAtPath:file error:&error];
            if (dict == nil) {
                NSLog(@"attributesOfItemAtPath: %@, Error: %@", file, error);
            } else {
                fileSize = [[dict objectForKey:NSFileSize] integerValue];
            }
        }
    }
    
    return fileSize;
}

@end
