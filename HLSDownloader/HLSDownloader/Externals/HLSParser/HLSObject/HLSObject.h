//
//  HLSObject.h
//  HLSDownloader
//
//  Created by Liu Junqi on 02/08/2017.
//  Copyright © 2017 DeviLeo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HLSTypeDef.h"

@class HLSMasterPlaylist;
@class HLSMediaPlaylist;

@interface HLSObject : NSObject

@property (nonatomic) NSString *url;
@property (nonatomic) NSString *file;
@property (nonatomic) HLSPlaylistType playlistType;
@property (nonatomic) HLSMasterPlaylist *masterPlaylist;
@property (nonatomic) HLSMediaPlaylist *mediaPlaylist;

- (instancetype)initWithFile:(NSString *)file;
- (BOOL)parse;
- (BOOL)parseWithError:(NSError **)parseError;

@end
