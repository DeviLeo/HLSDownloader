//
//  HLSTypeDef.h
//  HLSDownloader
//
//  Created by Liu Junqi on 25/08/2017.
//  Copyright © 2017 DeviLeo. All rights reserved.
//

#ifndef HLSTypeDef_h
#define HLSTypeDef_h

typedef enum : NSUInteger {
    HLSPlaylistTypeUndefined,
    HLSPlaylistTypeUnknown,
    HLSPlaylistTypeMaster,
    HLSPlaylistTypeMedia,
} HLSPlaylistType;

typedef enum : NSUInteger {
    HLSMediaPlaylistTypeUndefined,
    HLSMediaPlaylistTypeUnknown,
    HLSMediaPlaylistTypeEvent,
    HLSMediaPlaylistTypeVOD,
} HLSMediaPlaylistType;

typedef enum : NSUInteger {
    HLSMediaTypeUndefined,
    HLSMediaTypeUnknown,
    HLSMediaTypeAudio,
    HLSMediaTypeVideo,
} HLSMediaType;

#endif /* HLSTypeDef_h */
