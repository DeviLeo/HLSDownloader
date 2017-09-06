//
//  HLSMasterPlaylist.h
//  HLSDownloader
//
//  Created by Liu Junqi on 25/08/2017.
//  Copyright © 2017 DeviLeo. All rights reserved.
//

#import <Foundation/Foundation.h>

@class HLSStreamInfo;
@class HLSMedia;

@interface HLSMasterPlaylist : NSObject

@property (nonatomic) NSString *hlsURL;
@property (nonatomic) NSString *content;

@property (nonatomic) NSMutableArray<HLSStreamInfo *> *iframes;
@property (nonatomic) NSMutableArray<HLSStreamInfo *> *streams;
@property (nonatomic) NSMutableArray<HLSMedia *> *media;

- (void)parse:(NSString *)content withHLSURL:(NSString *)hlsURL;

@end
