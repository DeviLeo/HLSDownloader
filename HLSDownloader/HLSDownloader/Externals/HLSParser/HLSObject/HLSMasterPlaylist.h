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

@property (nonatomic) NSMutableArray<HLSStreamInfo *> *iframes;
@property (nonatomic) NSMutableArray<HLSStreamInfo *> *streams;
@property (nonatomic) NSMutableArray<HLSMedia *> *media;

@end
