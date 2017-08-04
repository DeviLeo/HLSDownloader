//
//  HLSDownloader.m
//  HLSDownloader
//
//  Created by Liu Junqi on 01/08/2017.
//  Copyright © 2017 DeviLeo. All rights reserved.
//

#import "HLSDownloader.h"

@interface HLSDownloader () <NSURLSessionDataDelegate>

@property (nonatomic) NSURLSession *session;
@property (nonatomic) int64_t contentLength;
@property (nonatomic) int64_t downloadedBytes;
@property (nonatomic) NSFileHandle *fileHandle;

@end

@implementation HLSDownloader

- (instancetype)initWithURL:(NSString *)urlString {
    self = [super init];
    if (self) {
        self.url = urlString;
        self.uid = [[NSUUID UUID] UUIDString];
        self.file = [NSString stringWithFormat:@"%@-%@", self.uid, [self dateString]];
    }
    return self;
}

- (void)reset {
    self.contentLength = -1;
    self.downloadedBytes = -1;
    [self createFileHandle];
}

- (void)start {
    HLSDownloaderStatus status = kHLSDownloaderStatusNone;
    [self reset];
    if (self.downloading) {
        status = kHLSDownloaderStatusDownloading;
        [self invokeDownloadBlock:status];
    }
    self.downloading = YES;
    [self download];
}

- (void)cancel {
    if (self.session == nil) return;
    if (self.downloading) [self.session invalidateAndCancel];
    self.session = nil;
    self.downloading = NO;
}

- (void)releaseSession {
    self.session = nil;
}

- (void)createFileHandle {
    if (self.fileHandle != nil) return;
    [self createFileToDownload];
    self.fileHandle = [NSFileHandle fileHandleForWritingAtPath:self.file];
}

- (void)releaseFileHandle {
    if (self.fileHandle == nil) return;
    [self.fileHandle closeFile];
    self.fileHandle = nil;
}

- (void)createFileToDownload {
    NSError *error = nil;
    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:self.file]) {
        if (![fm removeItemAtPath:self.file error:&error]) {
            NSLog(@"*** [Create]removeItemAtPath: %@ error: %@", self.file, error);
        }
    }
    if (![fm createFileAtPath:self.file contents:nil attributes:nil]) {
        NSLog(@"*** [Create]createFileAtPath: %@", self.file);
    }
}

- (void)deleteDownloadedFile {
    NSError *error = nil;
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm removeItemAtPath:self.file error:&error]) {
        NSLog(@"*** [Delete]removeItemAtPath: %@ error: %@", self.file, error);
    }
}

- (void)finishSession:(NSURLSession *)session {
    [session finishTasksAndInvalidate];
    [self releaseSession];
    self.downloading = NO;
}

- (void)download {
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    configuration.allowsCellularAccess = YES;
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:nil];
    NSString *encodedURL = [self.url stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    NSURL *url = [NSURL URLWithString:encodedURL];
    NSURLSessionDataTask *dataTask = [session dataTaskWithURL:url];
    [dataTask resume];
    self.session = session;
}

- (void)invokeDownloadBlock:(HLSDownloaderStatus)status {
    if (self.downloadBlock != nil) self.downloadBlock(status);
}

- (void)invokeCompleteBlock:(HLSDownloaderStatus)status file:(NSString *)file error:(NSError *)error {
    if (self.completeBlock != nil) self.completeBlock(status, file, error);
}

#pragma mark - NSURLSessionDelegate
- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler {
    NSURLCredential *credential = nil;
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
    }
    completionHandler(NSURLSessionAuthChallengeUseCredential, credential);
}

#pragma mark - NSURLSessionTaskDelegate
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(nullable NSError *)error {
    NSLog(@"didCompleteWithError: %@", error);
    [self releaseFileHandle];
    [self finishSession:session];
    HLSDownloaderStatus status = kHLSDownloaderStatusError;
    NSString *file = nil;
    if (error == nil) { // Complete Successfully
        status = kHLSDownloaderStatusSuccess;
        file = self.file;
    } else {
        [self deleteDownloadedFile];
    }
    [self invokeCompleteBlock:status file:file error:error];
}

#pragma mark - NSURLSessionDataDelegate
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    NSURLSessionResponseDisposition disposition = NSURLSessionResponseCancel;
    
    NSInteger statusCode = ((NSHTTPURLResponse *)response).statusCode;
    NSInteger contentLength = (NSInteger)response.expectedContentLength;
    if (statusCode == 200) {
        self.contentLength = contentLength;
        self.downloadedBytes = 0;
        disposition = NSURLSessionResponseAllow;
    }
    completionHandler(disposition);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    NSLog(@"didReceiveData: %zd of %zd", data.length, dataTask.response.expectedContentLength);
    BOOL writeToFile = YES;
    if (self.recvDataBlock != nil) writeToFile = self.recvDataBlock(data);
    if (writeToFile) [self.fileHandle writeData:data];
    if (self.progressBlock != nil) {
        self.downloadedBytes += data.length;
        self.progressBlock(data.length, self.downloadedBytes, self.contentLength);
    }
}

#pragma mark - mark
- (NSString *)dateString {
    NSDate *date = [NSDate date];
    NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
    fmt.dateFormat = @"yyyyMMddHHmmssSSS";
    NSString *dateString = [fmt stringForObjectValue:date];
    return dateString;
}

@end
