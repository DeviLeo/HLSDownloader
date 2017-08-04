//
//  HLSDownloader.h
//  HLSDownloader
//
//  Created by Liu Junqi on 01/08/2017.
//  Copyright © 2017 DeviLeo. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum : NSUInteger {
    kHLSDownloaderStatusDownloading = -2,
    kHLSDownloaderStatusError = -1,
    kHLSDownloaderStatusNone = 0,
    kHLSDownloaderStatusSuccess = 1,
    kHLSDownloaderStatusCancelled = -2,
} HLSDownloaderStatus;

typedef void (^HLSDownloaderDownloadBlock)(HLSDownloaderStatus status);
typedef void (^HLSDownloaderCompleteBlock)(HLSDownloaderStatus status, NSString *file, NSError *error);
typedef void (^HLSDownloaderProgressBlock)(int64_t bytesWritten, int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite);
typedef BOOL (^HLSDownloaderRecvDataBlock)(NSData *data);

@interface HLSDownloader : NSObject

@property (nonatomic) NSString *uid;
@property (nonatomic) NSString *url;
@property (nonatomic) NSString *file;
@property (nonatomic) BOOL downloading;
@property (nonatomic, strong) HLSDownloaderDownloadBlock downloadBlock;
@property (nonatomic, strong) HLSDownloaderCompleteBlock completeBlock;
@property (nonatomic, strong) HLSDownloaderProgressBlock progressBlock;
@property (nonatomic, strong) HLSDownloaderRecvDataBlock recvDataBlock;

- (instancetype)initWithURL:(NSString *)urlString;

- (void)start;
- (void)cancel;

@end
