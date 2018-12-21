//
//  ViewController.m
//  HLSDownloader
//
//  Created by Liu Junqi on 01/08/2017.
//  Copyright © 2017 DeviLeo. All rights reserved.
//

#import "ViewController.h"
#import "HLSParser.h"
#import "HLSObject.h"
#import "HLSMediaPlaylist.h"
#import "HLSMediaSegment.h"
#import "HLSMediaSegmentsManager.h"
#import "HLSUtils.h"

#define UserDefaultsSecurityScopeBookmarkKey  @"securityscopebookmark"
#define UserDefaultsHLSURLKey           @"hlsurl"
#define UserDefaultsDownloadFolderKey   @"downloadfolder"

@interface ViewController () <HLSParserDelegate, NSTextFieldDelegate, HLSMediaSegmentsManagerDelegate>

@property (nonatomic, weak) IBOutlet NSTextField *tfUrl;
@property (nonatomic, weak) IBOutlet NSTextField *tfFolderPath;
@property (nonatomic, weak) IBOutlet NSTextField *tfHLSFilePath;
@property (nonatomic, weak) IBOutlet NSTextView *tvContent;
@property (nonatomic, weak) IBOutlet NSButton *btnChooseFolder;
@property (nonatomic, weak) IBOutlet NSButton *btnChooseHLSFile;
@property (nonatomic, weak) IBOutlet NSButton *btnShowFolderInFinder;
@property (nonatomic, weak) IBOutlet NSButton *btnShowHLSFileInFinder;
@property (nonatomic, weak) IBOutlet NSButton *btnDownload;
@property (nonatomic, weak) IBOutlet NSButton *btnClear;
@property (nonatomic, weak) IBOutlet NSButton *btnStopDownloading;
@property (nonatomic, weak) IBOutlet NSProgressIndicator *piDownloadProgress;
@property (nonatomic, weak) IBOutlet NSTextField *tfDownloadProgress;

@property (nonatomic) NSTimeInterval startDownloadTime;
@property (nonatomic) HLSParser *hlsParser;
@property (nonatomic) BOOL downloading;
@property (nonatomic) NSString *folderPath;
@property (nonatomic) NSString *hlsFile;
@property (nonatomic) NSString *mediaFile;

@property (nonatomic) HLSObject *hlsObject;
@property (nonatomic) HLSMediaSegmentsManager *hlsSegsManager;
@property (nonatomic) BOOL reloadHLSPeriodically;

@property (nonatomic) NSTimer *timerForReloadHLS;
@property (nonatomic) NSTimeInterval startReloadHLSTime;
@property (nonatomic) NSTimeInterval reloadHLSTimeInterval;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view.
    [self initVars];
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

- (void)viewDidAppear {
    [super viewDidAppear];
    [self checkPermission];
}

#pragma mark - Init
- (void)initVars {
    self.tfUrl.delegate = self;
    self.tfFolderPath.delegate = self;
    self.tvContent.editable = NO;
    self.hlsSegsManager = [[HLSMediaSegmentsManager alloc] init];
    self.hlsSegsManager.delegate = self;
    self.reloadHLSPeriodically = YES;
    self.reloadHLSTimeInterval = 5;
    self.mediaFile = nil;
    self.tfDownloadProgress.stringValue = @"Download Progress";
    self.piDownloadProgress.minValue = 0;
    self.piDownloadProgress.maxValue = 100;
    self.piDownloadProgress.doubleValue = 0;
    [self loadHLSUrl];
    [self loadDownloadFolder];
}

- (void)initHLSParser {
    if (self.hlsParser) {
        [self.hlsParser cancelDownloadFile];
        self.hlsParser = nil;
    }
    
    NSString *hlsfileurl = self.tfUrl.stringValue;
    if (hlsfileurl.length == 0) return;
    HLSParser *parser = [[HLSParser alloc] initWithURL:hlsfileurl];
    parser.delegate = self;
    self.hlsParser = parser;
}

- (void)initMediaFile {
    NSURL *url = [NSURL URLWithString:self.hlsParser.urlString];
    NSString *filename = [[url.lastPathComponent stringByDeletingPathExtension] stringByAppendingPathExtension:@"ts"];
    NSString *filepath = [_folderPath stringByAppendingPathComponent:filename];
    self.mediaFile = filepath;
}

#pragma mark - Setter / Getter
- (void)setDownloading:(BOOL)downloading {
    _downloading = downloading;
    [self updateDownloadButton];
}

- (void)updateDownloadButton {
    NSString *title = self.downloading ? @"Cancel" : @"Download";
    self.btnDownload.title = title;
}

#pragma mark - NSTextFieldDelegate
- (void)controlTextDidChange:(NSNotification *)obj {
    NSTextField *textField = obj.object;
    if (textField == self.tfFolderPath) {
        self.folderPath = textField.stringValue;
    } else if (textField == self.tfUrl) {
        self.hlsParser.urlString = textField.stringValue;
    } else if (textField == self.tfHLSFilePath) {
        self.hlsFile = textField.stringValue;
    }
}

#pragma mark - TextView
- (void)appendContentToTextView:(NSString *)content {
    self.tvContent.string = [NSString stringWithFormat:@"%@%@\n", self.tvContent.string, content];
}

#pragma mark - Events
- (IBAction)onChooseFolderTapped:(id)sender {
    NSOpenPanel *op = [NSOpenPanel openPanel];
    op.prompt = @"Choose";
    op.canChooseFiles = NO;
    op.canChooseDirectories = YES;
    op.allowsMultipleSelection = NO;
    [op beginWithCompletionHandler:^(NSModalResponse result) {
        NSArray *urls = [op URLs];
        if (urls.count == 0) return;
        NSURL *url = [urls firstObject];
        NSString *folderPath = [[url.absoluteString stringByReplacingOccurrencesOfString:@"file://" withString:@""] stringByRemovingPercentEncoding];
        self.tfFolderPath.stringValue = folderPath;
        self.folderPath = folderPath;
        [self saveDownloadFolder];
    }];
}

- (IBAction)onChooseHLSFileTapped:(id)sender {
    NSOpenPanel *op = [NSOpenPanel openPanel];
    op.prompt = @"Choose";
    op.canChooseFiles = YES;
    op.canChooseDirectories = NO;
    op.allowsMultipleSelection = NO;
    [op beginWithCompletionHandler:^(NSModalResponse result) {
        NSArray *urls = [op URLs];
        if (urls.count == 0) return;
        NSURL *url = [urls firstObject];
        NSString *file = [[url.absoluteString stringByReplacingOccurrencesOfString:@"file://" withString:@""] stringByRemovingPercentEncoding];
        self.tfHLSFilePath.stringValue = file;
        self.hlsFile = file;
        [self saveDownloadFolder];
        if ([self parseHLSFile:file withURL:nil]) [self startDownloadTSStream];
    }];
}

- (IBAction)onShowFolderInFinderTapped:(id)sender {
    BOOL opened = NO;
    if (_folderPath.length > 0) {
        NSURL *url = [NSURL fileURLWithPath:_folderPath];
        opened = [[NSWorkspace sharedWorkspace] openURL:url];
    }
}

- (IBAction)onShowHLSFileInFinderTapped:(id)sender {
    if (_hlsFile.length > 0) {
        NSURL *url = [NSURL fileURLWithPath:_hlsFile];
        [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:@[url]];
    }
}

- (IBAction)onDownloadTapped:(id)sender {
    BOOL hasPermission = [self checkPermission];
    if (!hasPermission) return;
    
    [self initHLSParser];
    [self initMediaFile];
    [self saveHLSUrl];
    [self saveDownloadFolder];
    if (self.downloading) [self stopDownloadHLSFile];
    else [self startDownloadHLSFile];
}

- (IBAction)onClearTapped:(id)sender {
    self.tvContent.string = @"";
}

- (IBAction)onStopDownloadingTapped:(id)sender {
    [self stopDownloadHLSFile];
    [self stopAllDownloading];
}

#pragma mark - Download
- (void)startDownloadHLSFile {
    self.startDownloadTime = [NSDate date].timeIntervalSinceReferenceDate;
    [self.hlsParser startDownloadFile];
    self.downloading = YES;
    
    NSString *content = [NSString stringWithFormat:@"Start downloading %@", self.hlsParser.urlString];
    [self appendContentToTextView:content];
    self.piDownloadProgress.indeterminate = YES;
    [self.piDownloadProgress startAnimation:nil];
    self.tfDownloadProgress.stringValue = @"Downloading m3u8...";
}

- (void)stopDownloadHLSFile {
    if (self.hlsParser == nil) return;
    [self.hlsParser cancelDownloadFile];
    self.downloading = NO;
    
    [self appendContentToTextView:@"Stopped downloading."];
    
    self.tfDownloadProgress.stringValue = @"Stopped";
    self.piDownloadProgress.doubleValue = 0;
    [self.piDownloadProgress stopAnimation:nil];
}

- (void)startDownloadTSStream {
    HLSMediaPlaylist *mediaPlaylist = self.hlsObject.mediaPlaylist;
    NSArray *segs = mediaPlaylist.segments;
    for (HLSMediaSegment *seg in segs) {
        if (!seg.downloadable) continue;
        [self.hlsSegsManager addSegment:seg];
    }
    self.reloadHLSPeriodically = !mediaPlaylist.endList &&
    mediaPlaylist.type != HLSMediaPlaylistTypeVOD &&
    mediaPlaylist.targetDuration > 0;
    [self.hlsSegsManager startDownloading];
}

- (void)stopAllDownloading {
    self.reloadHLSPeriodically = NO;
    [self.hlsSegsManager cancelAllDownloads];
    
    self.tfDownloadProgress.stringValue = @"Stopped";
    self.piDownloadProgress.doubleValue = 0;
    [self.piDownloadProgress stopAnimation:nil];
}

#pragma mark - Timer
- (void)createTimerForHLSReloading {
    if (self.timerForReloadHLS != nil) return;
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(timerForHLSReloading:) userInfo:nil repeats:YES];
    self.timerForReloadHLS = timer;
}

- (void)cancelTimerForHLSReloading {
    if (self.timerForReloadHLS == nil) return;
    [self.timerForReloadHLS invalidate];
    self.timerForReloadHLS = nil;
}

- (void)timerForHLSReloading:(NSTimer *)timer {
    NSTimeInterval now = [NSDate date].timeIntervalSinceReferenceDate;
    NSTimeInterval dt = now - self.startReloadHLSTime;
    if (dt > self.reloadHLSTimeInterval) {
        [self startDownloadHLSFile];
        [self cancelTimerForHLSReloading];
    }
}

#pragma mark - HLSMediaSegmentsManagerDelegate
- (void)HLSMediaSegmentsManager:(HLSMediaSegmentsManager *)manager willDownloadSegment:(HLSMediaSegment *)segment {
    NSString *content = [NSString stringWithFormat:@"Start downloading media segment: %@", segment.url];
    [self appendContentToTextView:content];
    self.startDownloadTime = [NSDate date].timeIntervalSinceReferenceDate;
}

- (void)HLSMediaSegment:(HLSMediaSegment *)segment dowloaded:(int64_t)bytesWritten totalDownloaded:(int64_t)totalBytesWritten total:(int64_t)totalBytesExpectedToWrite {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSTimeInterval now = [NSDate date].timeIntervalSinceReferenceDate;
        NSTimeInterval dt = now - self.startDownloadTime;
        CGFloat speed = totalBytesWritten;
        if (dt > 0) speed /= dt;
        NSString *unit = nil;
        NSString *totalBytesExpectedToWriteString = totalBytesExpectedToWrite < 0 ? @"?" : [HLSUtils computerSizeString:totalBytesExpectedToWrite specifiedUnit:&unit];
        NSString *totalBytesWrittenString = [HLSUtils computerSizeString:totalBytesWritten specifiedUnit:&unit];
        NSString *bytesWrittenString = [HLSUtils computerSizeString:bytesWritten specifiedUnit:&unit allowUnitLowerThanSpecifiedUnit:YES];
        NSString *speedString = [HLSUtils computerSizeString:speed];
        NSString *content = [NSString stringWithFormat:@"%@/%@ (%@) - %@/s",
                             totalBytesWrittenString, totalBytesExpectedToWriteString,
                             bytesWrittenString, speedString];
        if (self.piDownloadProgress.indeterminate) self.piDownloadProgress.indeterminate = NO;
        self.tfDownloadProgress.stringValue = content;
        self.piDownloadProgress.doubleValue = totalBytesExpectedToWrite < 0 ? 0 : (double)totalBytesWritten / totalBytesExpectedToWrite * 100;
    });
}

- (void)HLSMediaSegment:(HLSMediaSegment *)segment dowloadedFile:(NSString *)file error:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (file == nil) {
            if (error != nil) {
                NSString *content = [NSString stringWithFormat:@"Error: %@", error];
                [self appendContentToTextView:content];
            }
            return;
        }
        
        NSString *content = [NSString stringWithFormat:@"Downloaded file: %@", file];
        [self appendContentToTextView:content];
        
        NSURL *url = [NSURL URLWithString:segment.url];
        NSString *filename = url.lastPathComponent;
        NSString *filepath = [HLSUtils moveDownloadedFile:file toFolder:self.folderPath renameTo:filename];
        if (![HLSUtils appendFile:filepath toFile:self.mediaFile]) {
            NSString *content = [NSString stringWithFormat:@"Failed to append file: %@ to %@", filepath, self.mediaFile];
            [self appendContentToTextView:content];
        } else {
            [HLSUtils deleteFile:filepath];
        }
        
        return;
    });
}

- (void)HLSMediaSegmentsManagerAllDownloaded:(HLSMediaSegmentsManager *)manager {
    if (!_reloadHLSPeriodically) return;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self startDownloadHLSFile];
    });
}

#pragma mark - HLSParserDelegate
- (BOOL)HLSParser:(HLSParser *)parser detectedFile:(BOOL)valid {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *content = [NSString stringWithFormat:@"Detected the file is %@", valid ? @"HLS" : @"NOT HLS"];
        [self appendContentToTextView:content];
    });
    return valid;
}

- (void)HLSParser:(HLSParser *)parser dowloadedFile:(NSString *)file error:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self stopDownloadHLSFile];
        
        if (error) {
            NSString *content = [NSString stringWithFormat:@"[%zd]%@", error.code, error.localizedDescription];
            [self appendContentToTextView:content];
            return;
        }
        
        NSString *content = [NSString stringWithFormat:@"Downloaded file: %@", file];
        [self appendContentToTextView:content];
        
        NSURL *url = [NSURL URLWithString:parser.urlString];
        NSString *filename = url.lastPathComponent;
        NSString *theNewFile = [HLSUtils moveDownloadedFile:file toFolder:self.folderPath renameTo:filename];
        if ([self parseHLSFile:theNewFile withURL:parser.urlString]) [self startDownloadTSStream];
    });
}

- (void)HLSParser:(HLSParser *)parser dowloaded:(int64_t)bytesWritten totalDownloaded:(int64_t)totalBytesWritten total:(int64_t)totalBytesExpectedToWrite {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSTimeInterval now = [NSDate date].timeIntervalSinceReferenceDate;
        NSTimeInterval dt = now - self.startDownloadTime;
        CGFloat speed = totalBytesWritten;
        if (dt > 0) speed /= dt;
        NSString *unit = nil;
        NSString *totalBytesExpectedToWriteString = totalBytesExpectedToWrite < 0 ? @"?" : [HLSUtils computerSizeString:totalBytesExpectedToWrite specifiedUnit:&unit];
        NSString *totalBytesWrittenString = [HLSUtils computerSizeString:totalBytesWritten specifiedUnit:&unit];
        NSString *bytesWrittenString = [HLSUtils computerSizeString:bytesWritten specifiedUnit:&unit allowUnitLowerThanSpecifiedUnit:YES];
        NSString *speedString = [HLSUtils computerSizeString:speed];
        NSString *content = [NSString stringWithFormat:@"%@/%@ (%@) - %@/s",
                             totalBytesWrittenString, totalBytesExpectedToWriteString,
                             bytesWrittenString, speedString];
        self.tfDownloadProgress.stringValue = content;
        self.piDownloadProgress.doubleValue = totalBytesExpectedToWrite < 0 ? 0 : (double)totalBytesWritten / totalBytesExpectedToWrite * 100;
    });
}

#pragma mark - Handle File
- (BOOL)parseHLSFile:(NSString *)file withURL:(NSString *)urlString {
    BOOL isHLSM3U = [HLSUtils determineHLSM3UFromFile:file];
    if (!isHLSM3U) {
        NSString *content = [NSString stringWithFormat:@"Error: %@ is NOT a valid HLS m3u file.", file];
        [self appendContentToTextView:content];
        return NO;
    }
    NSString *content = [NSString stringWithFormat:@"Start parsing HLS file: %@", file];
    [self appendContentToTextView:content];
    
    HLSObject *theNewHLS = [[HLSObject alloc] initWithFile:file];
    theNewHLS.url = urlString;
    NSError *error = nil;
    if (![theNewHLS parseWithError:&error]) {
        content = [NSString stringWithFormat:@"Error: %@", error.localizedDescription];
        [self appendContentToTextView:content];
        return NO;
    }
    
    BOOL isNewHLS = (theNewHLS.playlistType != self.hlsObject.playlistType);
    if (!isNewHLS && theNewHLS.playlistType == HLSPlaylistTypeMedia) {
        isNewHLS = [HLSUtils determineTheNewMediaSegment:theNewHLS.mediaPlaylist old:self.hlsObject.mediaPlaylist];
        HLSMediaPlaylist *mediaPlaylist = self.hlsObject.mediaPlaylist;
        if (self.hlsObject == nil || isNewHLS) {
            self.hlsObject = theNewHLS;
            self.reloadHLSTimeInterval = mediaPlaylist.lastMediaSegmentDuration;
        } else { // HLS m3u8 not changed
            self.reloadHLSPeriodically = !mediaPlaylist.endList &&
            mediaPlaylist.type != HLSMediaPlaylistTypeVOD &&
            mediaPlaylist.targetDuration > 0;
            if (self.reloadHLSPeriodically) {
                self.reloadHLSTimeInterval = mediaPlaylist.targetDuration / 2;
                [self createTimerForHLSReloading];
            }
        }
    } else {
        NSString *theOldType = @"unknown", *theNewType = @"unknown";
        if (self.hlsObject != nil) {
            if (self.hlsObject.playlistType == HLSPlaylistTypeMaster) theOldType = @"master";
            else if (self.hlsObject.playlistType == HLSPlaylistTypeMedia) theOldType = @"media";
        }
        if (theNewHLS.playlistType == HLSPlaylistTypeMaster) theNewType = @"master";
        else if (theNewHLS.playlistType == HLSPlaylistTypeMedia) theNewType = @"media";
        if (self.hlsObject == nil) {
            content = [NSString stringWithFormat:@"The HLS is %@ playlist.", theNewType];
        } else {
            content = [NSString stringWithFormat:@"The new HLS is %@ playlist, the old HLS is %@ playlist.", theNewType, theOldType];
        }
        [self appendContentToTextView:content];
        
        if (self.hlsObject == nil || isNewHLS) {
            self.hlsObject = theNewHLS;
        }
    }
    content = [NSString stringWithFormat:@"The HLS file is %@.\nDone!", isNewHLS ? @"changed" : @"not changed"];
    [self appendContentToTextView:content];
    return isNewHLS;
}

#pragma mark - Save / Load
- (void)saveHLSUrl {
    NSString *hslurl = self.tfUrl.stringValue;
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    if (hslurl.length == 0) [ud removeObjectForKey:UserDefaultsHLSURLKey];
    else [ud setObject:hslurl forKey:UserDefaultsHLSURLKey];
    [ud synchronize];
}

- (NSString *)loadHLSUrl {
    NSString *hslurl = [[NSUserDefaults standardUserDefaults] objectForKey:UserDefaultsHLSURLKey];
    if (hslurl == nil) hslurl = @"";
    self.tfUrl.stringValue = hslurl;
    return hslurl;
}

- (void)saveDownloadFolder {
    NSString *downloadfolder = _folderPath;
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    if (downloadfolder.length == 0) [ud removeObjectForKey:UserDefaultsDownloadFolderKey];
    else [ud setObject:downloadfolder forKey:UserDefaultsDownloadFolderKey];
    [ud synchronize];
}

- (NSString *)loadDownloadFolder {
    NSString *downloadFolder = [[NSUserDefaults standardUserDefaults] objectForKey:UserDefaultsDownloadFolderKey];
    if (downloadFolder == nil) downloadFolder = [NSSearchPathForDirectoriesInDomains(NSDownloadsDirectory, NSUserDomainMask, YES) firstObject];
    self.tfFolderPath.stringValue = downloadFolder;
    self.folderPath = downloadFolder;
    return downloadFolder;
}

#pragma mark - Sandbox
- (BOOL)checkPermission {
    NSData *data = [self loadSecurityScopeBookmark];
    if (!data) {
        NSString *content = @"FAILED to load security scope bookmark.";
        [self appendContentToTextView:content];
        [self requestPermission];
        return NO;
    }
    
    NSURL *url = [self resolveURLFromSecurityScopeBookmark:data];
    if (url == nil) {
        NSString *content = @"FAILED to parse security scope bookmark.";
        [self appendContentToTextView:content];
        [self requestPermission];
        return NO;
    }
    BOOL granted = [url startAccessingSecurityScopedResource];
    NSString *folderPath = [[url.absoluteString stringByReplacingOccurrencesOfString:@"file://" withString:@""] stringByRemovingPercentEncoding];
    NSString *content = [NSString stringWithFormat:@"%@ to access %@", granted ? @"Granted" : @"Denied", folderPath];
    [self appendContentToTextView:content];
    
    NSString *downloadFolder = [self loadDownloadFolder];
    if (downloadFolder && ![downloadFolder containsString:folderPath]) {
        NSString *content = [NSString stringWithFormat:@"No access to download folder %@, because it is not the sub folder in %@.", downloadFolder, folderPath];
        [self appendContentToTextView:content];
    }
    
    return granted;
}

- (void)requestPermission {
    NSOpenPanel *op = [NSOpenPanel openPanel];
    op.title = @"Request Access to Folder";
    op.prompt = @"Grant";
    op.canChooseFiles = NO;
    op.canChooseDirectories = YES;
    op.allowsMultipleSelection = NO;
    [op beginWithCompletionHandler:^(NSModalResponse result) {
        NSArray *urls = [op URLs];
        if (urls.count == 0) {
            NSString *downloadFolder = [self loadDownloadFolder];
            if (downloadFolder) {
                NSString *content = [NSString stringWithFormat:@"No access to %@", downloadFolder];
                [self appendContentToTextView:content];
            }
            return;
        }
        NSURL *url = [urls firstObject];
        NSString *folderPath = [[url.absoluteString stringByReplacingOccurrencesOfString:@"file://" withString:@""] stringByRemovingPercentEncoding];
        self.tfFolderPath.stringValue = folderPath;
        self.folderPath = folderPath;
        [self saveDownloadFolder];
        [self saveSecurityScopeBookmark:url];
        BOOL granted = [url startAccessingSecurityScopedResource];
        NSString *content = [NSString stringWithFormat:@"%@ to access %@", granted ? @"Granted" : @"Denied", folderPath];
        [self appendContentToTextView:content];
    }];
}

- (NSURL *)resolveURLFromSecurityScopeBookmark:(NSData *)data {
    BOOL isStale = NO;
    NSError *error = nil;
    NSURL *url = [NSURL URLByResolvingBookmarkData:data options:NSURLBookmarkResolutionWithSecurityScope relativeToURL:nil bookmarkDataIsStale:&isStale error:&error];
    if (error) {
        NSString *content = [NSString stringWithFormat:@"[%zd]%@", error.code, error.localizedDescription];
        [self appendContentToTextView:content];
        return nil;
    }
    
    if (isStale) {
        [self saveSecurityScopeBookmark:url];
    }
    return url;
}

- (NSData *)loadSecurityScopeBookmark {
    NSData *data = [[NSUserDefaults standardUserDefaults] objectForKey:UserDefaultsSecurityScopeBookmarkKey];
    return data;
}

- (void)saveSecurityScopeBookmark:(NSURL *)url {
    NSError *error = nil;
    NSData *data = [url bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope
                 includingResourceValuesForKeys:nil
                                  relativeToURL:nil
                                          error:&error];
    if (error) {
        NSString *content = [NSString stringWithFormat:@"[%zd]%@", error.code, error.localizedDescription];
        [self appendContentToTextView:content];
        return;
    }
    
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    if (data == nil) [ud removeObjectForKey:UserDefaultsSecurityScopeBookmarkKey];
    else [ud setObject:data forKey:UserDefaultsSecurityScopeBookmarkKey];
    BOOL success = [ud synchronize];
    
    if (!success) {
        NSString *content = @"FAILE to save security scope bookmark.";
        [self appendContentToTextView:content];
        return;
    }
}

@end
