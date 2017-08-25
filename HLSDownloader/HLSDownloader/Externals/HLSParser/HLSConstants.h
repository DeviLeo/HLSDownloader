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
#define HLSTagGap                       @"#EXT-X-GAP"
#define HLSTagKey                       @"#EXT-X-KEY"
#define HLSTagStreamINF                 @"#EXT-X-STREAM-INF"
#define HLSTagIFrameStreamINF           @"#EXT-X-I-FRAME-STREAM-INF"
#define HLSTagMedia                     @"#EXT-X-MEDIA"
#define HLSTagSessionData               @"#EXT-X-SESSION-DATA"
#define HLSTagDateRange                 @"#EXT-X-DATERANGE"

#pragma mark - Tag Key
#define HLSTagKeyMethod                 @"METHOD"
#define HLSTagKeyURI                    @"URI"
#define HLSTagKeyBandwidth              @"BANDWIDTH"
#define HLSTagKeyAverageBandwidth       @"AVERAGE-BANDWIDTH"
#define HLSTagKeyCodecs                 @"CODECS"
#define HLSTagKeyType                   @"TYPE"
#define HLSTagKeyGroupID                @"GROUP-ID"
#define HLSTagKeyName                   @"NAME"
#define HLSTagKeyDefault                @"DEFAULT"
#define HLSTagKeyAutoSelect             @"AUTOSELECT"
#define HLSTagKeyLanguage               @"LANGUAGE"
#define HLSTagKeyDataID                 @"DATA-ID"
#define HLSTagKeyValue                  @"VALUE"
#define HLSTagKeyCharacteristics        @"CHARACTERISTICS"
#define HLSTagKeyID                     @"ID"
#define HLSTagKeyStartDate              @"START-DATE"
#define HLSTagKeyPlannedDuration        @"PLANNED-DURATION"
#define HLSTagKeySCTE35Out              @"SCTE35-OUT"
#define HLSTagKeySCTE35In               @"SCTE35-IN"
#define HLSTagKeyVideo                  @"VIDEO"
#define HLSTagKeyAudio                  @"AUDIO"

#pragma mark - Tag Value
#define HLSTagValuePlaylistTypeEvent    @"EVENT"
#define HLSTagValuePlaylistTypeVOD      @"VOD"
#define HLSTagValueMediaTypeVideo       @"VIDEO"
#define HLSTagValueMediaTypeAudio       @"AUDIO"
#define HLSTagValueBooleanYES           @"YES"
#define HLSTagValueBooleanNO            @"NO"

#endif /* HLSConstants_h */
