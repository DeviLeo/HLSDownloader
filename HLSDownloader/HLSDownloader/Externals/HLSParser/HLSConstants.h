//
//  HLSConstants.h
//  HLSDownloader
//
//  Created by Liu Junqi on 01/08/2017.
//  Copyright © 2017 DeviLeo. All rights reserved.
//

#ifndef HLSConstants_h
#define HLSConstants_h

#pragma mark - Tag
#define HLSTagHeader                    @"#EXTM3U"
#define HLSTagVersion                   @"#EXT-X-VERSION"
#define HLSTagDiscontinuity             @"#EXT-X-DISCONTINUITY"
#define HLSTagTargetDuration            @"#EXT-X-TARGETDURATION"
#define HLSTagMediaSequence             @"#EXT-X-MEDIA-SEQUENCE"
#define HLSTagDiscontinuitySequence     @"#EXT-X-DISCONTINUITY-SEQUENCE"
#define HLSTagINF                       @"#EXTINF"
#define HLSTagEndList                   @"#EXT-X-ENDLIST"
#define HLSTagPlaylistType              @"#EXT-X-PLAYLIST-TYPE"

#pragma mark - Tag Value
#define HLSTagValuePlaylistTypeEvent    @"EVENT"
#define HLSTagValuePlaylistTypeVOD      @"VOD"

#endif /* HLSConstants_h */
