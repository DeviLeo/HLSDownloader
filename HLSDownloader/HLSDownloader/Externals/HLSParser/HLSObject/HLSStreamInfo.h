//
//  HLSStreamInfo.h
//  HLSDownloader
//
//  Created by Liu Junqi on 25/08/2017.
//  Copyright © 2017 DeviLeo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HLSStreamInfo : NSObject

@property (nonatomic) BOOL isIFrame;
@property (nonatomic) NSString *uri;
@property (nonatomic) NSString *codecs;
@property (nonatomic) NSInteger bandwidth;
@property (nonatomic) NSInteger averageBandwidth;
@property (nonatomic) NSString *videoGroupID;
@property (nonatomic) NSString *audioGroupID;
@property (nonatomic) NSString *subtitlesGroupID;
@property (nonatomic) CGSize resolution;
@property (nonatomic) NSString *resolutionString;
@property (nonatomic) NSString *programID;

- (instancetype)initWithAttributes:(NSDictionary *)attributes;

@end
