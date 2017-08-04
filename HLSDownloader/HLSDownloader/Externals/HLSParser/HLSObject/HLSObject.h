//
//  HLSObject.h
//  HLSDownloader
//
//  Created by Liu Junqi on 02/08/2017.
//  Copyright © 2017 DeviLeo. All rights reserved.
//

#import <Foundation/Foundation.h>

@class HLSMediaSegment;

typedef enum : NSUInteger {
    HLSPlaylistTypeUndefined,
    HLSPlaylistTypeEvent,
    HLSPlaylistTypeVOD,
} HLSPlaylistType;

@interface HLSObject : NSObject

@property (nonatomic) NSString *url;
@property (nonatomic) NSString *file;
@property (nonatomic) NSInteger version;
@property (nonatomic) NSInteger targetDuration;
@property (nonatomic) CGFloat lastMediaSegmentDuration;
@property (nonatomic) NSInteger mediaSequence;
@property (nonatomic) BOOL discontinuity;
@property (nonatomic) NSInteger discontinuitySequence;
@property (nonatomic) BOOL endList;
@property (nonatomic) HLSPlaylistType playlistType;
@property (nonatomic) NSMutableArray<HLSMediaSegment *> *segments;

- (instancetype)initWithFile:(NSString *)file;
- (void)parse;

@end
