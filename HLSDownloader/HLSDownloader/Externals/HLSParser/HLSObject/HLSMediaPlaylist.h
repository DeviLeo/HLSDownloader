//
//  HLSMediaPlaylist.h
//  HLSDownloader
//
//  Created by DeviLeo on 2017/8/26.
//  Copyright © 2017年 DeviLeo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HLSTypeDef.h"

@class HLSMediaSegment;

@interface HLSMediaPlaylist : NSObject

@property (nonatomic) NSInteger version;
@property (nonatomic) NSInteger targetDuration;
@property (nonatomic) NSInteger mediaSequence;
@property (nonatomic) BOOL discontinuity;
@property (nonatomic) NSInteger discontinuitySequence;
@property (nonatomic) BOOL endList;
@property (nonatomic) HLSMediaPlaylistType type;
@property (nonatomic) NSMutableArray<HLSMediaSegment *> *segments;

@property (nonatomic) NSInteger currentMediaSequence;
@property (nonatomic) CGFloat lastMediaSegmentDuration;

@end
