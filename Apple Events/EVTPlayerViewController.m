//
//  EVTPlayerViewController.m
//  Apple Events
//
//  Created by Guilherme Rambo on 9/5/16.
//  Copyright © 2016 Guilherme Rambo. All rights reserved.
//

#import "EVTPlayerViewController.h"

#import "EVTEventsViewController.h"
#import "EVTEvent.h"

@import AVFoundation;
@import AVKit;
@import EventsUI;

@interface EVTPlayerViewController ()

@property (copy) EVTEvent *event;
@property (copy) NSURL *videoURL;

@property (strong) AVPlayer *player;
@property (strong) AVPlayerView *playerView;

@property (assign) BOOL aspectRatioSet;

@end

@implementation EVTPlayerViewController

+ (instancetype)playerViewControllerWithEvent:(EVTEvent *)event videoURL:(NSURL *)videoURL
{
    EVTPlayerViewController *vc = [[EVTPlayerViewController alloc] initWithNibName:nil bundle:nil];
    
    vc.videoURL = videoURL;
    vc.event = event;
    
    return vc;
}

- (EVTEventsViewController *)mainController
{
    return (EVTEventsViewController *)self.parentViewController;
}

- (void)loadView
{
    self.view = [[NSView alloc] initWithFrame:NSZeroRect];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.player = [AVPlayer playerWithURL:self.videoURL];
    
    [self.player addObserver:self forKeyPath:@"currentItem.presentationSize" options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew context:NULL];
    
    self.playerView = [[AVPlayerView alloc] initWithFrame:self.view.bounds];
    self.playerView.controlsStyle = AVPlayerViewControlsStyleFloating;
    [self.view addSubview:self.playerView];
    self.playerView.autoresizingMask = NSViewWidthSizable|NSViewHeightSizable;
    self.playerView.player = self.player;
    
    [self.player play];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"currentItem.presentationSize"]) {
        [self updateAspectRatio];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)updateAspectRatio
{
    if (self.aspectRatioSet) return;
    
    if (self.player.currentItem.presentationSize.width == 0 || self.player.currentItem.presentationSize.height == 0) return;
    
    self.aspectRatioSet = YES;
    
    if ([(EVTWindow *)self.view.window isInPiPMode]) return;
    
    NSSize videoSize = self.player.currentItem.presentationSize;
    self.view.window.aspectRatio = videoSize;
    [self sizeWindowToFitVideoSize:videoSize ignoringScreenSize:YES animated:YES];
}

- (void)viewWillAppear
{
    [super viewWillAppear];
    
    [self updateAspectRatio];
}

- (void)viewDidAppear
{
    [super viewDidAppear];
    
    self.view.window.title = [NSString stringWithFormat:@"%@ - %@", self.event.title, self.event.localizedDateString];
}

- (void)stop
{
    [self.player pause];
    [self.player cancelPendingPrerolls];
    [self.player removeObserver:self forKeyPath:@"currentItem.presentationSize"];
}

- (void)sizeWindowToFitVideoSize:(NSSize)videoSize ignoringScreenSize:(BOOL)ignoreScreen animated:(BOOL)animate
{
    if ((self.view.window.styleMask & NSFullScreenWindowMask) == NSFullScreenWindowMask) return;
    
    CGFloat wRatio, hRatio, resizeRatio;
    NSRect screenRect = [NSScreen mainScreen].frame;
    NSSize screenSize = screenRect.size;
    
    if (videoSize.width >= videoSize.height) {
        wRatio = screenSize.width / videoSize.width;
        hRatio = screenSize.height / videoSize.height;
    } else {
        wRatio = screenSize.height / videoSize.width;
        hRatio = screenSize.width / videoSize.height;
    }
    
    resizeRatio = MIN(wRatio, hRatio);
    
    NSSize newSize = NSMakeSize(videoSize.width*resizeRatio, videoSize.height*resizeRatio);
    
    if (ignoreScreen) {
        newSize.width = videoSize.width;
        newSize.height = videoSize.height;
    }
    
    NSRect newRect = NSMakeRect(screenSize.width/2-newSize.width/2, screenSize.height/2-newSize.height/2, newSize.width, newSize.height);
    
    [self.view.window setFrame:newRect display:YES animate:animate];
}

@end
