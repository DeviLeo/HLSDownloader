//
//  HLSObject.m
//  HLSDownloader
//
//  Created by Liu Junqi on 02/08/2017.
//  Copyright © 2017 DeviLeo. All rights reserved.
//

#import "HLSObject.h"
#import "HLSConstants.h"
#import "HLSMasterPlaylist.h"
#import "HLSMediaPlaylist.h"
#import "HLSErrorDef.h"

@implementation HLSObject

- (instancetype)initWithFile:(NSString *)file {
    self = [super init];
    if (self) {
        self.file = file;
        [self initVars];
    }
    return self;
}

#pragma mark - Init
- (void)initVars {
    self.url = nil;
    self.mediaPlaylist = [[HLSMediaPlaylist alloc] init];
    self.masterPlaylist = [[HLSMasterPlaylist alloc] init];
}

#pragma mark - Parse
- (BOOL)parse {
    return [self parseWithError:nil];
}

- (BOOL)parseWithError:(NSError **)parseError {
    NSError *error = nil;
    NSString *content = [NSString stringWithContentsOfFile:self.file encoding:NSUTF8StringEncoding error:&error];
    if (error) {
        NSLog(@"*** stringWithContentsOfFile: %@ error: %@", self.file, error);
        if (parseError != nil) *parseError = error;
        return NO;
    }
    
    HLSPlaylistType type = [self determinePlaylistType:content];
    if (type == HLSPlaylistTypeUnknown || type == HLSPlaylistTypeUndefined) {
        NSString *errorMessage = @"The playlist is invalid.";
        NSLog(@"%@", errorMessage);
        if (parseError != nil) *parseError = [NSError errorWithDomain:HLSErrorDomain
                                                                 code:HLSErrorCodeInvalidPlaylist
                                                             userInfo:@{NSLocalizedDescriptionKey:errorMessage}];
        return NO;
    }
    self.playlistType = type;
    
    if (type == HLSPlaylistTypeMaster) {
        [self.masterPlaylist parse:content withHLSURL:self.url];
    } else if (type == HLSPlaylistTypeMedia) {
        [self.mediaPlaylist parse:content withHLSURL:self.url];
    }
    
    return YES;
}

- (HLSPlaylistType)determinePlaylistType:(NSString *)content {
    HLSPlaylistType type = HLSPlaylistTypeUndefined;
    
    // Check "EXT-X-TARGETDURATION" tag to detemine whether the playlist is a media playlist or not.
    BOOL isMediaPlaylist = [content rangeOfString:HLSTagTargetDuration].location != NSNotFound;
    // Check "EXT-X-STREAM-INF" tag to detemine whether the playlist is a master playlist or not.
    BOOL isMasterPlaylist = [content rangeOfString:HLSTagStreamINF].location != NSNotFound;
    
    if (isMediaPlaylist && !isMasterPlaylist) type = HLSPlaylistTypeMedia;
    else if (!isMediaPlaylist && isMasterPlaylist) type = HLSPlaylistTypeMaster;
    else type = HLSPlaylistTypeUnknown;
    
    return type;
}

@end
