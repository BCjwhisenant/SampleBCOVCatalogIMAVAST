//
//  ViewController.h
//  SampleBCOVCatalogIMAVAST
//
//  Created by Jim Whisenant on 8/27/14.
//  Copyright (c) 2014 Brightcove. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <BCOVPlayerSDK.h>
#import "BCOVIMA.h"

#import "ViewController.h"
#import "VideoStillView.h"

#import "IMAAdEvent.h"
#import "RACEXTScope.h"


@interface ViewController : UIViewController <BCOVPlaybackControllerDelegate, IMAWebOpenerDelegate>

@end

