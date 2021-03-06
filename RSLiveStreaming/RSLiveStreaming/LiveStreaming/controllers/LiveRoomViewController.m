//
//  LiveRoomViewController.m
//  RSLiveStreaming
//
//  Created by Ron_Samkulami on 2020/5/27.
//  Copyright © 2020 Ron_Samkulami. All rights reserved.
//

#import "LiveRoomViewController.h"
#import <IJKMediaFramework/IJKMediaFramework.h>
#import <UIImageView+WebCache.h>
//#import <Accelerate/Accelerate.h>
#import "RSLikesView.h"
@interface LiveRoomViewController () <UIGestureRecognizerDelegate>

@property (atomic, retain) id <IJKMediaPlayback> player;
@property (weak, nonatomic) UIView *PlayerView;          //这里用了weak？？？？

@property (nonatomic, strong) UIImageView *dimImage;
@property (nonatomic, assign) int number;
@property (nonatomic, assign) CGFloat heartSize;


@end

@implementation LiveRoomViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
//    NSString *url = @"https://wswebhls.inke.cn/live/1590914820268938/playlist.m3u8?msUid=&auth_version=1&from=h5&ts=1590918726&md5sum=1154";    //hls
    NSString *url = self.liveUrl;
   
    UIView *displayView = [[UIView alloc] initWithFrame:self.view.bounds];  //创建UIview
    self.PlayerView = displayView;
    [self.view addSubview:self.PlayerView];
    
//    self.player = [[IJKFFMoviePlayerController alloc] initWithContentURLString:url withOptions:options];  //创建播放控制器
    self.player = [[IJKAVMoviePlayerController alloc] initWithContentURLString:url];
    self.player.shouldAutoplay = YES;
    UIView *playerView = [self.player view];                                //获取播放器的view
    playerView.frame = self.PlayerView.frame;
    playerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.PlayerView insertSubview:playerView atIndex:0];
    
    [_player setScalingMode:IJKMPMovieScalingModeAspectFill];
    [self installMovieNotificationObservers];

    [self loadingView];
    [self changeBackBtn];
}
   
#pragma mark --------

// 加载图
- (void)loadingView {
    self.dimImage = [[UIImageView alloc] initWithFrame:self.view.bounds];
//    [_dimIamge sd_setImageWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://img.ikstatic.cn/MTU4OTQ0MDYxMDYyOSM1ODUjanBn.jpg"]]];
    [_dimImage sd_setImageWithURL:[NSURL URLWithString:self.imageUrl]];
    _dimImage.contentMode = UIViewContentModeScaleAspectFill;
    _dimImage.clipsToBounds = YES;
    UIVisualEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
    UIVisualEffectView *visualEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    visualEffectView.frame = _dimImage.bounds;
    [_dimImage addSubview:visualEffectView];
    [self.view addSubview:_dimImage];
    NSLog(@"加载背景图");
    
}


#pragma mark - Notification Selector

- (void)loadStateDidChange:(NSNotification*)notification {
    IJKMPMovieLoadState loadState = _player.loadState;
    
    if ((loadState & IJKMPMovieLoadStatePlaythroughOK) != 0) {
        NSLog(@"LoadStateDidChange: IJKMovieLoadStatePlayThroughOK: %d\n",(int)loadState);
    }else if ((loadState & IJKMPMovieLoadStateStalled) != 0) {
        NSLog(@"loadStateDidChange: IJKMPMovieLoadStateStalled: %d\n", (int)loadState);
    } else {
        NSLog(@"loadStateDidChange: ???: %d\n", (int)loadState);
    }
}

- (void)moviePlayBackFinish:(NSNotification*)notification {
    int reason =[[[notification userInfo] valueForKey:IJKMPMoviePlayerPlaybackDidFinishReasonUserInfoKey] intValue];
    switch (reason) {
        case IJKMPMovieFinishReasonPlaybackEnded:
            NSLog(@"playbackStateDidChange: IJKMPMovieFinishReasonPlaybackEnded: %d\n", reason);
            break;
            
        case IJKMPMovieFinishReasonUserExited:
            NSLog(@"playbackStateDidChange: IJKMPMovieFinishReasonUserExited: %d\n", reason);
            break;
            
        case IJKMPMovieFinishReasonPlaybackError:
            NSLog(@"playbackStateDidChange: IJKMPMovieFinishReasonPlaybackError: %d\n", reason);
            break;
            
        default:
            NSLog(@"playbackPlayBackDidFinish: ???: %d\n", reason);
            break;
    }
}

- (void)mediaIsPreparedToPlayDidChange:(NSNotification*)notification {
    NSLog(@"mediaIsPrepareToPlayDidChange\n");
}

- (void)moviePlayBackStateDidChange:(NSNotification*)notification {
    if ([self.player isPlaying]) {
        _dimImage.hidden = YES;
    }
//    _dimIamge.hidden = YES;

        switch (_player.playbackState) {
            
        case IJKMPMoviePlaybackStateStopped:
            NSLog(@"IJKMPMoviePlayBackStateDidChange %d: stoped", (int)_player.playbackState);
            break;
            
        case IJKMPMoviePlaybackStatePlaying:
            NSLog(@"IJKMPMoviePlayBackStateDidChange %d: playing", (int)_player.playbackState);
            break;
            
        case IJKMPMoviePlaybackStatePaused:
            NSLog(@"IJKMPMoviePlayBackStateDidChange %d: paused", (int)_player.playbackState);
            break;
            
        case IJKMPMoviePlaybackStateInterrupted:
            NSLog(@"IJKMPMoviePlayBackStateDidChange %d: interrupted", (int)_player.playbackState);
            break;
            
        case IJKMPMoviePlaybackStateSeekingForward:
        case IJKMPMoviePlaybackStateSeekingBackward: {
            NSLog(@"IJKMPMoviePlayBackStateDidChange %d: seeking", (int)_player.playbackState);
            break;
        }
            
        default: {
            NSLog(@"IJKMPMoviePlayBackStateDidChange %d: unknown", (int)_player.playbackState);
            break;
        }
    }
}

#pragma mark - Install Notifiacation

- (void)installMovieNotificationObservers {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(loadStateDidChange:)
                                                 name:IJKMPMoviePlayerLoadStateDidChangeNotification
                                               object:_player];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(moviePlayBackFinish:)
                                                 name:IJKMPMoviePlayerPlaybackDidFinishNotification
                                               object:_player];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(mediaIsPreparedToPlayDidChange:)
                                                 name:IJKMPMediaPlaybackIsPreparedToPlayDidChangeNotification
                                               object:_player];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(moviePlayBackStateDidChange:)
                                                 name:IJKMPMoviePlayerPlaybackStateDidChangeNotification
                                               object:_player];
    
}

- (void)removeMovieNotificationObservers {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:IJKMPMoviePlayerLoadStateDidChangeNotification
                                                  object:_player];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:IJKMPMoviePlayerPlaybackDidFinishNotification
                                                  object:_player];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:IJKMPMediaPlaybackIsPreparedToPlayDidChangeNotification
                                                  object:_player];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:IJKMPMoviePlayerPlaybackStateDidChangeNotification
                                                  object:_player];
    
}


// 按钮
- (void)changeBackBtn {
    // 返回
    UIButton * backBtn = [UIButton buttonWithType:(UIButtonTypeCustom)];
    backBtn.frame = CGRectMake(10, 64 / 2 - 8, 33, 33);
    [backBtn setImage:[UIImage imageNamed:@"返回"] forState:(UIControlStateNormal)];
    [backBtn addTarget:self action:@selector(goBack) forControlEvents:(UIControlEventTouchUpInside)];
    backBtn.layer.shadowColor = [UIColor blackColor].CGColor;
    backBtn.layer.shadowOffset = CGSizeMake(0, 0);
    backBtn.layer.shadowOpacity = 0.5;
    backBtn.layer.shadowRadius = 1;
    [self.view addSubview:backBtn];
    
    // 暂停
    UIButton * playBtn = [UIButton buttonWithType:(UIButtonTypeCustom)];
    playBtn.frame = CGRectMake([UIScreen mainScreen].bounds.size.width - 33-10, 64 / 2 - 8, 33, 33);
    
    if (self.number == 0) {
        [playBtn setImage:[UIImage imageNamed:@"暂停"] forState:(UIControlStateNormal)];
        [playBtn setImage:[UIImage imageNamed:@"开始"] forState:(UIControlStateSelected)];
    }else{
        [playBtn setImage:[UIImage imageNamed:@"开始"] forState:(UIControlStateNormal)];
        [playBtn setImage:[UIImage imageNamed:@"暂停"] forState:(UIControlStateSelected)];
    }
    
    [playBtn addTarget:self action:@selector(play_btn:) forControlEvents:(UIControlEventTouchUpInside)];
    playBtn.layer.shadowColor = [UIColor blackColor].CGColor;
    playBtn.layer.shadowOffset = CGSizeMake(0, 0);
    playBtn.layer.shadowOpacity = 0.5;
    playBtn.layer.shadowRadius = 1;
    [self.view addSubview:playBtn];
    
    // 点赞
    UIButton * likeBtn = [UIButton buttonWithType:(UIButtonTypeCustom)];
    likeBtn.frame = CGRectMake(playBtn.frame.origin.x/2, [UIScreen mainScreen].bounds.size.height-33-10, 33, 33);
    [likeBtn setImage:[UIImage imageNamed:@"点赞"] forState:(UIControlStateNormal)];
    [likeBtn addTarget:self action:@selector(showTheLove:) forControlEvents:(UIControlEventTouchUpInside)];
    likeBtn.layer.shadowColor = [UIColor blackColor].CGColor;
    likeBtn.layer.shadowOffset = CGSizeMake(0, 0);
    likeBtn.layer.shadowOpacity = 0.5;
    likeBtn.layer.shadowRadius = 1;
    likeBtn.adjustsImageWhenHighlighted = NO;
    [self.view addSubview:likeBtn];
    
    
}

#pragma mark - Btn Selector
// 返回
- (void)goBack {
    // 停播
    [self.player shutdown];
    
    [self.navigationController popViewControllerAnimated:true];
    
}

// 暂停开始
- (void)play_btn:(UIButton *)sender {
    
    sender.selected =! sender.selected;
    if (![self.player isPlaying]) {
        // 播放
        [self.player play];
    }else{
        // 暂停
        [self.player pause];
    }
}

// 点赞
-(void)showTheLove:(UIButton *)sender{
    RSLikesView* heart = [[RSLikesView alloc]initWithFrame:CGRectMake(0, 0, _heartSize, _heartSize)];
    [self.view addSubview:heart];
    CGPoint fountainSource = CGPointMake(([UIScreen mainScreen].bounds.size.width-_heartSize-10)/2 + _heartSize/2.0, self.view.bounds.size.height - _heartSize/2.0 - 10);
    heart.center = fountainSource;
    [heart animateInView:self.view];
    
    // button点击动画
    CAKeyframeAnimation *btnAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
    btnAnimation.values = @[@(1.0),@(0.7),@(0.5),@(0.3),@(0.5),@(0.7),@(1.0), @(1.2), @(1.4), @(1.2), @(1.0)];
    btnAnimation.keyTimes = @[@(0.0),@(0.1),@(0.2),@(0.3),@(0.4),@(0.5),@(0.6),@(0.7),@(0.8),@(0.9),@(1.0)];
    btnAnimation.calculationMode = kCAAnimationLinear;
    btnAnimation.duration = 0.3;
    [sender.layer addAnimation:btnAnimation forKey:@"SHOW"];
}




#pragma mark - life circle


        
- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    

    [self.navigationController setNavigationBarHidden:YES];     //隐藏导航栏
    self.tabBarController.tabBar.hidden = YES;
    
    self.navigationController.interactivePopGestureRecognizer.delegate = self;  //保持返回手势pop
    self.navigationController.interactivePopGestureRecognizer.enabled = YES;
    if (![self.player isPlaying]) {
        // 准备播放
        [self.player prepareToPlay];
    }
//    [self.player play];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
//    [self.navigationController setNavigationBarHidden:NO animated:YES];
    
    [self.navigationController setNavigationBarHidden:NO];
    //关闭直播
//    [self.player shutdown];
  
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    [self.player shutdown];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
