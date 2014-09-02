//
//  ViewController.m
//  SampleBCOVCatalogIMAVAST
//
//  Created by Jim Whisenant on 8/27/14.
//  Copyright (c) 2014 Brightcove. All rights reserved.
//


#import "ViewController.h"

// ** Customize Here **
static NSString * const kViewControllerIMAPublisherID = @"insertyourpidhere";
static NSString * const kViewControllerIMALanguage = @"en";
static NSString * const kViewControllerIMAVASTResponseAdTag1 = @"http://pubads.g.doubleclick.net/gampad/ads?slotname=/15018773/everything2&sz=640x480&ciu_szs=300x250,468x60,728x90&url=dummy&unviewed_position_start=1&output=xml_vast2&impl=s&env=vp&gdfp_req=1&ad_rule=0&vad_type=linear&vpos=preroll&pod=1&min_ad_duration=0&max_ad_duration=10000&ppos=1&video_doc_id=10XWSh7W4so&cmsid=133";
static NSString * const kViewControllerIMAVASTResponseAdTag2 = @"http://pubads.g.doubleclick.net/gampad/ads?slotname=/15018773/everything2&sz=640x480&ciu_szs=300x250,468x60,728x90&url=dummy&unviewed_position_start=1&output=xml_vast2&impl=s&env=vp&gdfp_req=1&ad_rule=0&vad_type=linear&vpos=preroll&pod=2&min_ad_duration=0&max_ad_duration=10000&ppos=2&lip=true&video_doc_id=10XWSh7W4so&cmsid=133";
static NSString * const kViewControllerIMAVASTResponseAdTag3 = @"http://pubads.g.doubleclick.net/gampad/ads?slotname=/15018773/everything2&sz=640x480&ciu_szs=300x250,468x60,728x90&url=dummy&unviewed_position_start=1&output=xml_vast2&impl=s&env=vp&gdfp_req=1&ad_rule=0&vad_type=linear&vpos=midroll&pod=3&mridx=1&bumper=before&min_ad_duration=0&max_ad_duration=10000&video_doc_id=10XWSh7W4so&cmsid=133";

static NSString * const kViewControllerCatalogToken = @"nFCuXstvl910WWpPnCeFlDTNrpXA5mXOO9GPkuTCoLKRyYpPF1ikig..";
static NSString * const kViewControllerPlaylistID = @"2149006311001";

// Extend the BCOVCuePointCollection to add a method called "adsCount."
// This method will iterate through the array of CuePoints returned as
// part of the Video metadata from the Brightcove Catalog service, and
// return the number of Ad type Cue Points.
@interface BCOVCuePointCollection(BCOVIMAVAST)

- (NSUInteger)adsCount;

@end

@implementation BCOVCuePointCollection(BCOVIMAVAST)

- (NSUInteger)adsCount
{
    NSUInteger count = 0;
    NSArray *cuePoints = [self array];
    for (BCOVCuePoint *cuePoint in cuePoints) {
        if ([kBCOVIMACuePointTypeAd isEqualToString:cuePoint.type]) {
            count++;
        }
    }
    return count;
}

@end


@interface ViewController ()

@property (nonatomic, assign) BOOL adIsPlaying;
@property (nonatomic, assign) BOOL isBrowserOpen;
@property (nonatomic, strong) BCOVCatalogService *catalogService;
@property (nonatomic, weak) id<BCOVPlaybackSession> currentPlaybackSession;
@property (nonatomic, strong) id<BCOVPlaybackController> playbackController;
@property (nonatomic, weak) IBOutlet UIView *videoContainerView;

// Define a property here to determine whether to configure the Ad Tag URL at
// the Playlist level, or at the Video Cue Point level.
@property BOOL adTagWillConfigureOnPlaylist;

@end


@implementation ViewController
            
- (id)init
{
    self = [super init];
    if (self)
    {
        [self setup];
    }
    return self;
}

-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        [self setup];
    }
    return self;
}

-(void)awakeFromNib
{
    [super awakeFromNib];
    [self setup];
}

-(void)setup
{
    self.adIsPlaying = NO;
    self.isBrowserOpen = NO;
    
    // Set this property to YES to configure the Ad Tag URL to be the same for all videos and cue points
    // self.adTagWillConfigureOnPlaylist = YES;
    
    BCOVPlayerSDKManager *sdkManager = [BCOVPlayerSDKManager sharedManager];
    
    IMASettings *imaSettings = [[IMASettings alloc] init];
    imaSettings.ppid = kViewControllerIMAPublisherID;
    imaSettings.language = kViewControllerIMALanguage;
    
    IMAAdsRenderingSettings *renderSettings = [[IMAAdsRenderingSettings alloc] init];
    renderSettings.webOpenerPresentingController = self;
    renderSettings.webOpenerDelegate = self;
    
    // Set up the BCOVIMASessionOption object with VASTOptions
    BCOVIMASessionProviderOptions *sessionProviderOption = [BCOVIMASessionProviderOptions VASTOptions];
    
    // The Ad Tag URL can be configured here for VAST responses at the Playlist level
    if (self.adTagWillConfigureOnPlaylist)
    {
        sessionProviderOption.adsRequestPolicy = [BCOVIMAAdsRequestPolicy adsRequestPolicyFromCuePointPropertiesWithAdTag:kViewControllerIMAVASTResponseAdTag1 adsCuePointProgressPolicy:nil];
    }
    id<BCOVPlaybackSessionProvider> playbackSessionProvider = [sdkManager createIMASessionProviderWithSettings:imaSettings adsRenderingSettings:renderSettings upstreamSessionProvider:nil options:sessionProviderOption];
    id<BCOVPlaybackController> playbackController = [sdkManager createPlaybackControllerWithSessionProvider:playbackSessionProvider viewStrategy:[self viewStrategyWithFrame:CGRectMake(0, 0, 400, 400)]];
    

    playbackController.delegate = self;
    self.playbackController = playbackController;
    
    // When the app goes to the background, the Google IMA library will pause
    // the ad. This code demonstrates how you would resume the ad when entering
    // the foreground.
    // We will use @weakify(self)/@strongify(self) a few times later in the code.
    // For more info on weakify/strongify, visit https://github.com/jspahrsummers/libextobjc.
    @weakify(self);
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillEnterForegroundNotification object:self queue:nil usingBlock:^(NSNotification *note) {
        
        @strongify(self);
        
        if (self.adIsPlaying && !self.isBrowserOpen)
        {
            [self.playbackController resumeAd];
        }
        
    }];
    
    self.catalogService = [[BCOVCatalogService alloc] initWithToken:kViewControllerCatalogToken];
    [self requestContentFromCatalog];
    
    [[self playbackController] setAutoPlay:YES];
    [[self playbackController] setAutoAdvance:YES];
    
}

- (void)requestContentFromCatalog
{
    // In order to play back content, we are going to request a playlist from the
    // catalog service.  The data in the catalog does not have the required
    // VMAP tag on the video, so this code demonstrates how to update a playlist
    // to set the ad tags on the video.
    // You are responsible for determining where the ad tag should originate from.
    // We advise that if you choose to hard code it into your app, that you provide
    // a mechanism to update it without having to submit an update to your app.
    @weakify(self);
    [self.catalogService findPlaylistWithPlaylistID:kViewControllerPlaylistID parameters:nil completion:^(BCOVPlaylist *playlist, NSDictionary *jsonResponse, NSError *error) {
        
        @strongify(self);
        
        if (playlist)
        {
            BCOVPlaylist *updatedPlaylist = [self configureCuePoints:playlist];
            [self.playbackController setVideos:updatedPlaylist.videos];
            
            [self.playbackController setAutoPlay:YES];
            [self.playbackController setAutoAdvance:YES];
            
        }
        else
        {
            NSLog(@"ViewController Debug - Error retrieving playlist: %@", error);
        }
        
    }];
}

- (BCOVPlaylist*)configureCuePoints:(BCOVPlaylist *)playlist
{
    BCOVPlaylist *updatedPlaylist = [playlist update:^(id<BCOVMutablePlaylist> mutablePlaylist) {
        
        NSMutableArray *newVideos = [NSMutableArray arrayWithCapacity:mutablePlaylist.videos.count];
        
        [mutablePlaylist.videos enumerateObjectsUsingBlock:^(BCOVVideo *video, NSUInteger idx, BOOL *stop) {
            
            // Update each video to add the Ad Tag URL.
            BCOVVideo *updatedVideo = [video update:^(id<BCOVMutableVideo> mutableVideo) {
                
                NSUInteger adsCount = [mutableVideo.cuePoints adsCount];
                
                // If a single Ad Tag URL will be applied to all videos and cue points in the Playlist
                if (self.adTagWillConfigureOnPlaylist)
                {
                    if (adsCount == 0)
                    {
                        mutableVideo.cuePoints = [[BCOVCuePointCollection alloc] initWithArray:@[
                             [[BCOVCuePoint alloc] initWithType:kBCOVIMACuePointTypeAd position:CMTimeMake(5,1) properties:@{ @"url" : @"www.brov.com", @"correlator": @"5", @"pod": @"1" }],
                             [[BCOVCuePoint alloc] initWithType:kBCOVIMACuePointTypeAd position:CMTimeMake(25,1) properties:@{ @"url" : @"www.after.com", @"correlator": @"25", @"pod": @"2" }],
                             [[BCOVCuePoint alloc] initWithType:kBCOVIMACuePointTypeAd position:CMTimeMake(45,1) properties:@{ @"url" : @"www.brovBrov.com", @"correlator": @"45", @"pod": @"3" }],
                             ]];
                    }
                }
                else
                    // The Ad Tag URL can be applied at the Video Cue Point level
                {
                    // If the Video has no Ad type Cue Points, cue points can be configured here
                    if (adsCount == 0)
                    {
                        mutableVideo.cuePoints = [[BCOVCuePointCollection alloc] initWithArray:@[
                             [[BCOVCuePoint alloc] initWithType:kBCOVIMACuePointTypeAd position:kBCOVCuePointPositionTypeBefore properties:@{ kBCOVIMAAdTag : kViewControllerIMAVASTResponseAdTag1 }],
                             [[BCOVCuePoint alloc] initWithType:kBCOVIMACuePointTypeAd position:CMTimeMake(10,1) properties:@{ kBCOVIMAAdTag : kViewControllerIMAVASTResponseAdTag2 }],
                             [[BCOVCuePoint alloc] initWithType:kBCOVIMACuePointTypeAd position:kBCOVCuePointPositionTypeAfter properties:@{ kBCOVIMAAdTag : kViewControllerIMAVASTResponseAdTag3 }],
                             ]];
                        
                    } else if (adsCount > 0)
                        // If there are Ad type Cue Points on the Video, the Video's Cue Point metadata
                        // (for example, the Cue Point position) will be used.
                        // If the Video does have Ad type Cue Points, a BCOVCuePoint object is created for each of the Video's Cue Points
                        // This includes Code type Cue Points
                    {
                        
                        NSMutableArray *newCuePoints = [NSMutableArray arrayWithCapacity:mutableVideo.cuePoints.count];
                        __block NSMutableDictionary *cuePointProperties = nil;
                        
                        for (BCOVCuePoint *cuePoint in mutableVideo.cuePoints)
                        {
                            
                            BCOVCuePoint *newCuePoint = nil;
                            
                            // For Ad type Cue Points, add the Ad Tag URL property when creating the BCOVCuePoint
                            if ([kBCOVIMACuePointTypeAd isEqualToString:cuePoint.type])
                            {
                                
                                // Setting the kBCOVIMAAdTag property at the Cue Point level means that a different
                                // Ad Tag URL can be configured for Pre-roll, Post-roll, and Mid-roll ads
                                if ([cuePoint.properties[@"name"] isEqualToString:@"Pre-roll" ])
                                {
                                    newCuePoint = [cuePoint update:^(id<BCOVMutableCuePoint> mutableCuePoint) {
                                        
                                        cuePointProperties = [[NSMutableDictionary alloc] initWithDictionary:mutableCuePoint.properties];
                                        mutableCuePoint.position = kBCOVCuePointPositionTypeBefore;
                                        cuePointProperties[kBCOVIMAAdTag] = kViewControllerIMAVASTResponseAdTag1;
                                        mutableCuePoint.properties = cuePointProperties;
                                        
                                    }];
                                    
                                    [newCuePoints addObject: newCuePoint];
                                    
                                }
                                else if ([cuePoint.properties[@"name"] isEqualToString:@"Post-roll" ])
                                {
                                    
                                    newCuePoint = [cuePoint update:^(id<BCOVMutableCuePoint> mutableCuePoint) {
                                        
                                        cuePointProperties = [[NSMutableDictionary alloc] initWithDictionary:mutableCuePoint.properties];
                                        mutableCuePoint.position = kBCOVCuePointPositionTypeAfter;
                                        cuePointProperties[kBCOVIMAAdTag] = kViewControllerIMAVASTResponseAdTag2;
                                        mutableCuePoint.properties = cuePointProperties;
                                        
                                    }];
                                    
                                    [newCuePoints addObject: newCuePoint];
                                    
                                }
                                else
                                {
                                    
                                    newCuePoint = [cuePoint update:^(id<BCOVMutableCuePoint> mutableCuePoint) {
                                        
                                        cuePointProperties = [[NSMutableDictionary alloc] initWithDictionary:mutableCuePoint.properties];
                                        cuePointProperties[kBCOVIMAAdTag] = kViewControllerIMAVASTResponseAdTag3;
                                        mutableCuePoint.properties = cuePointProperties;
                                        
                                    }];
                                    
                                    [newCuePoints addObject: newCuePoint];
                                    
                                }
                                
                            }
                            else
                            {
                                // For Code type Cue Points, add the Cue Point data retrieved from the Video
                                // to the list of BCOVCuePoints
                                [newCuePoints addObject:cuePoint];
                            }
                            
                            mutableVideo.cuePoints = [BCOVCuePointCollection collectionWithArray:newCuePoints];
                            
                        }
                    }
                }
            }];
            
            [newVideos addObject:updatedVideo];
        }];
        
        mutablePlaylist.videos = newVideos;
    }];
    
    return updatedPlaylist;
    
}

- (void)willOpenInAppBrowser
{
    self.isBrowserOpen = YES;
}

- (void)willCloseInAppBrowser
{
    self.isBrowserOpen = NO;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.playbackController.view.frame = self.videoContainerView.bounds;
    self.playbackController.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [self.videoContainerView addSubview:self.playbackController.view];
}

-(void)playbackController:(id<BCOVPlaybackController>)controller didAdvanceToPlaybackSession:(id<BCOVPlaybackSession>)session
{
    self.currentPlaybackSession = session;
    NSLog(@"ViewController Debug - Advanced to new session.");
}

-(void)playbackController:(id<BCOVPlaybackController>)controller playbackSession:(id<BCOVPlaybackSession>)session didReceiveLifecycleEvent:(BCOVPlaybackSessionLifecycleEvent *)lifecycleEvent
{
    // Ad events are emitted by the BCOVIMA plugin through lifecycle events.
    // The events are defined BCOVIMAComponent.h.
    
    NSString *type = lifecycleEvent.eventType;
    
    if ([type isEqualToString:kBCOVIMALifecycleEventAdsLoaderLoaded])
    {
        NSLog(@"ViewController Debug - Ads loaded.");
    }
    else if ([type isEqualToString:kBCOVIMALifecycleEventAdsManagerDidReceiveAdEvent])
    {
        IMAAdEvent *adEvent = lifecycleEvent.properties[@"adEvent"];
        
        switch (adEvent.type)
        {
            case kIMAAdEvent_STARTED:
                NSLog(@"ViewController Debug - Ad Started.");
                self.adIsPlaying = YES;
                break;
            case kIMAAdEvent_COMPLETE:
                NSLog(@"ViewController Debug - Ad Completed.");
                self.adIsPlaying = NO;
                break;
            case kIMAAdEvent_ALL_ADS_COMPLETED:
                NSLog(@"ViewController Debug - All ads completed.");
                break;
            default:
                break;
        }
        
    }
}

- (BCOVPlaybackControllerViewStrategy)videoStillViewStrategyWithFrame
{
    return [^ UIView * (UIView *videoView, id<BCOVPlaybackController> playbackController) {
        
        // Returns a view which covers `videoView` with a UIImageView
        // whose background is black and which presents the video still from
        // each video as it becomes the current video.
        VideoStillView *stillView = [[VideoStillView alloc] initWithVideoView:videoView];
        VideoStillViewMediator *stillViewMediator = [[VideoStillViewMediator alloc] initWithVideoStillView:stillView];
        // The Google Ads SDK for IMA does not play prerolls instantly when
        // the AVPlayer starts playing. Delaying the dismissal of the video
        // still for a second prevents the first video frame from "flashing"
        // briefly when this happens.
        stillViewMediator.dismissalDelay = 1.f;
        
        // (You should save `consumer` to an instance variable if you will need
        // to remove it from the playback controller's session consumers.)
        BCOVDelegatingSessionConsumer *consumer = [[BCOVDelegatingSessionConsumer alloc] initWithDelegate:stillViewMediator];
        [playbackController addSessionConsumer:consumer];
        
        return stillView;
        
    } copy];
}

- (BCOVPlaybackControllerViewStrategy)viewStrategyWithFrame:(CGRect)frame
{
    BCOVPlayerSDKManager *manager = [BCOVPlayerSDKManager sharedManager];
    
    // In this example, we use the defaultControlsViewStrategy. In real app, you
    // wouldn't be using this.  You would add your controls and container view
    // in the composedViewStrategy block below.
    BCOVPlaybackControllerViewStrategy stillViewStrategy = [self videoStillViewStrategyWithFrame];
    BCOVPlaybackControllerViewStrategy defaultControlsViewStrategy = [manager defaultControlsViewStrategy];
    BCOVPlaybackControllerViewStrategy imaViewStrategy = [manager BCOVIMAAdViewStrategy];
    
    // We create a composed view strategy using the defaultControlsViewStrategy
    // and the BCOVIMAAdViewStrategy.  The purpose of this block is to ensure
    // that the ads appear above above the controls so that we don't need to
    // implement any logic to show and hide the controls.  This should be customized
    // how you see fit.
    // This block is not executed until the playbackController.view property is
    // accessed, even though it is an initialization property. You can
    // use the playbackController property to add an object as a session consumer.
    BCOVPlaybackControllerViewStrategy composedViewStrategy = ^ UIView * (UIView *videoView, id<BCOVPlaybackController> playbackController) {
        
        videoView.frame = frame;
        
        UIView *viewWithStill = stillViewStrategy(videoView, playbackController);
        UIView *viewWithControls = defaultControlsViewStrategy(viewWithStill, playbackController); //Replace this with your own container view.
        UIView *viewWithAdsAndControls = imaViewStrategy(viewWithControls, playbackController);
        
        return viewWithAdsAndControls;
        
    };
    
    return [composedViewStrategy copy];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
