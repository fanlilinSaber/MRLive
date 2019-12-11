//
//  PWMRLiveSession.m
//  PWMRLive
//
//  Created by 范李林 on 2018/7/12.
//  Copyright © 2018年 FLL. All rights reserved.
//

#import "PWMRLiveSession.h"
#import <TXLiteAVSDK_Professional/TXLiveSDKTypeDef.h>
#import <TXLiteAVSDK_Professional/TXLivePush.h>
#import <TXLiteAVSDK_Professional/TXLivePlayer.h>
#import <TXLiteAVSDK_Professional/TXLiveBase.h>
#import <ReplayKit/ReplayKit.h>
#import "PWMRLivePlayListenerWrapper.h"

#ifdef DEBUG
#define MRLog(...) NSLog(@"%s %@", __PRETTY_FUNCTION__, [NSString stringWithFormat:__VA_ARGS__])
#else
#define MRLog(...)
#endif

/*&* 视频最后一帧 buffer*/
static CMSampleBufferRef s_lastSampleBuffer;
/*&* 视频历史记录 buffer 用于校检录屏是否成功*/
static CMSampleBufferRef u_lastSampleBuffer;

@interface PWMRLiveSession ()<TXLivePushListener, PWMRLivePlayListener, RPScreenRecorderDelegate>
{
    BOOL                     _appIsInActive; // app 生命状态是否在前台
    BOOL                     _appIsBackground; // app 生命状态是否在后台
}
/*&* 连麦视频质量（分辨率）*/
@property (nonatomic, assign) PWMRLiveVideoQuality videoQuality;
/*&* 动态码率*/
@property (nonatomic, assign) BOOL adjustBitrate;
/*&* 动态分辨率*/
@property (nonatomic, assign) BOOL adjustResolution;
/*&* 核心推流SDK*/
@property (nonatomic, strong) TXLivePush *livePusher;
/*&* [userID, playerUrl]*/
@property (nonatomic, strong) NSMutableDictionary *livePlayerUrlDic;
/*&* [userID, player]*/
@property (nonatomic, strong) NSMutableDictionary *livePlayerDic;
/*&* [userID, WebRTCPlayerListenerWrapper]*/
@property (nonatomic, strong) NSMutableDictionary *playerEventDic;
/*&* 保存房间列表userID，不包括自己*/
@property (nonatomic, strong) NSMutableArray *userListArray;
/*&* 播放 remoteView*/
@property (nonatomic, strong) NSMutableDictionary *playerViewDic;
/*&* 房间号*/
@property (nonatomic, copy) NSString *roomName;
/*&* sessionQueue*/
@property (nonatomic, strong) dispatch_queue_t sessionQueue;
/*&* 是否推流录屏数据*/
@property (nonatomic, assign) BOOL enableVideo;
/*&* 视频固定码率*/
@property (nonatomic, assign) int videoBitratePIN;
/*&* 视频最小码率*/
@property (nonatomic, assign) int videoBitrateMin;
/*&* 视频最大码率*/
@property (nonatomic, assign) int videoBitrateMax;
/*&* 视频帧率*/
@property (nonatomic, assign) int videoFPS;
/*&* 编码视频分辨率（必须和采集的原始数据 宽高比例对应）*/
@property (nonatomic, assign) CGSize videoSize;
/*&* 推流地址*/
@property (nonatomic, copy) NSString *pushUrl;

@property (nonatomic) UIBackgroundTaskIdentifier backgroundTask;

@end

@implementation PWMRLiveSession

- (void)dealloc
{
    MRLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
}

#pragma mark - init Method

- (instancetype)initWithVideoSize:(CGSize)videoSize videoBitratePIN:(int)videoBitratePIN videoBitrateMin:(int)videoBitrateMin videoBitrateMax:(int)videoBitrateMax videoFPS:(int)videoFPS adjustBitrate:(BOOL)adjustBitrate adjustResolution:(BOOL)adjustResolution pureAudio:(BOOL)pureAudio
{
    self = [super init];
    if (self) {
        _appIsInActive = YES;
        _appIsBackground = NO;
        self.enableVideo = YES;
        self.videoSize = videoSize;
        self.videoBitratePIN = videoBitratePIN;
        self.videoBitrateMin = videoBitrateMin;
        self.videoBitrateMax = videoBitrateMax;
        self.videoFPS = videoFPS;
        self.adjustBitrate = adjustBitrate;
        self.adjustResolution = adjustResolution;
        self.pureAudio = pureAudio;
        self.livePlayerUrlDic = [[NSMutableDictionary alloc] init];
        self.livePlayerDic = [[NSMutableDictionary alloc] init];
        self.playerEventDic = [[NSMutableDictionary alloc] init];
        self.userListArray = [[NSMutableArray alloc] init];
        self.playerViewDic = [[NSMutableDictionary alloc] init];
        self.sessionQueue = dispatch_queue_create("com.mrlive.session.queue", DISPATCH_QUEUE_CONCURRENT);
        self.livePusher = [[TXLivePush alloc] initWithConfig:[[TXLivePushConfig alloc] init]];
        self.livePusher.delegate = self;
        /*&* 核心推流服务配置*/
        [self setupConfigAndLivePusher];
        /*&* add app 生命周期通知*/
        [self addNotificationCenter];
    }
    
    return self;
}

- (instancetype)initWithVideoQuality:(PWMRLiveVideoQuality)videoQuality adjustBitrate:(BOOL)adjustBitrate adjustResolution:(BOOL)adjustResolution pureAudio:(BOOL)pureAudio
{
    CGSize screenSize = [[UIScreen mainScreen] bounds].size;
    CGSize videoSize;
    int videoBitrateMin, videoBitratePIN, videoBitrateMax, videoFPS;
    
    if (videoQuality == MR_VIDEO_QUALITY_STANDARD_DEFINITION) {
        videoSize = CGSizeMake(540 * screenSize.width / screenSize.height, 540);
        videoBitrateMin = 1200;
        videoBitratePIN = 1600;
        videoBitrateMax = 2000;
        videoFPS = 24;
    }else if (videoQuality == MR_VIDEO_QUALITY_HIGH_DEFINITION) {
        videoSize = CGSizeMake(720 * screenSize.width / screenSize.height, 720);
        videoBitrateMin = 1500;
        videoBitratePIN = 2000;
        videoBitrateMax = 2500;
        videoFPS = 24;
    }else if (videoQuality == MR_VIDEO_QUALITY_SUPER_DEFINITION) {
        videoSize = CGSizeMake(1080 * screenSize.width / screenSize.height, 1080);
        videoBitrateMin = 1500;
        videoBitratePIN = 2000;
        videoBitrateMax = 2500;
        videoFPS = 24;
    }else  {
        videoSize = CGSizeZero;
        videoBitrateMin = 1500;
        videoBitratePIN = 2000;
        videoBitrateMax = 2500;
        videoFPS = 24;
    }
    
    return [self initWithVideoSize:videoSize videoBitratePIN:videoBitratePIN videoBitrateMin:videoBitrateMin videoBitrateMax:videoBitrateMax videoFPS:videoFPS adjustBitrate:adjustBitrate adjustResolution:adjustResolution pureAudio:pureAudio];
}

#pragma mark - setters

- (void)setPauseImg:(UIImage *)pauseImg
{
    _pauseImg = pauseImg;
    if (self.livePusher) {
        TXLivePushConfig *config = self.livePusher.config;
        config.pauseImg = pauseImg;
        config.pauseFps = 10;
        config.pauseTime = 300;
        [self.livePusher setConfig:config];
    }
}

- (void)setEnableAEC:(BOOL)enableAEC
{
    _enableAEC = enableAEC;
    if (self.livePusher) {
        TXLivePushConfig *config = self.livePusher.config;
        config.enableAEC = enableAEC;
        [self.livePusher setConfig:config];
    }
}

- (void)setEnableAudioPreview:(BOOL)enableAudioPreview
{
    _enableAudioPreview = enableAudioPreview;
    if (self.livePusher) {
        TXLivePushConfig *config = self.livePusher.config;
        config.enableAudioPreview = enableAudioPreview;
        [self.livePusher setConfig:config];
    }
}

#pragma mark - private Method
#pragma mark - config
// 初始化 livePusher 配置
- (void)setupConfigAndLivePusher
{
    TXLivePushConfig *config = [[TXLivePushConfig alloc] init];
    config.customModeType |= CUSTOM_MODE_VIDEO_CAPTURE;
    config.enableHWAcceleration = YES;
    config.connectRetryCount = 10;
    config.enableAutoBitrate = self.adjustBitrate;
    // 纯音频推流
    if (self.pureAudio) {
        config.enablePureAudioPush = YES;
    }else {
        if (self.videoSize.width == 0 || self.videoSize.height == 0) {
            config.autoSampleBufferSize = YES;
        }else {
            config.sampleBufferSize = self.videoSize;
        }
        config.videoBitrateMin = self.videoBitrateMin;
        config.videoBitratePIN = self.videoBitratePIN;
        config.videoBitrateMax = self.videoBitrateMax;
        config.videoFPS = self.videoFPS;
    }
    
    [self.livePusher setVideoQuality:VIDEO_QUALITY_REALTIME_VIDEOCHAT adjustBitrate:self.adjustBitrate adjustResolution:self.adjustResolution];
    [self.livePusher setConfig:config];
}

// 尝试重新恢复
- (BOOL)retryStartConference
{
    if (self.pushUrl.length >0 && self.roomName.length  > 0) {
        return [self startConferenceWithPushUrl:self.pushUrl roomName:self.roomName];
    }
    
    return NO;
}

// 释放 LivePusher
- (void)releaseLivePusher
{
    if (_livePusher) {
        _livePusher = nil;
    }
}

// 重试启用录屏
- (void)retryScreenRecorder
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (!self->_appIsBackground && self->_appIsInActive && self->_runing) {
            [self startCapture];
        }
    });
}

// 检测当前录屏状态 如果没有成功尝试重启录屏采集
- (void)checkScreenRecorderAndRetry
{
    runOnTheMainQueue(^{
        if (!self->_appIsBackground && self->_appIsInActive && self->_runing) {
            if (![RPScreenRecorder sharedRecorder].isRecording) {
                MRLog(@"校验录屏失败了；尝试重新调用录屏!");
                [self startCapture];
            }else {
                if (u_lastSampleBuffer == s_lastSampleBuffer) {
                    MRLog(@"校验录屏成功了,但是没有数据m，尝试重新开启录屏!");
                    [self stopCapture];
                    [self retryScreenRecorder];
                    if (self.delegate && [self.delegate respondsToSelector:@selector(RTCMRLiveSession:rtcDidChangeState:)]) {
                        [self.delegate RTCMRLiveSession:self rtcDidChangeState:MRRTC_TRY_OPEN_SCREEN_RECORDER];
                    }
                }else {
                    if (u_lastSampleBuffer) {
                        CFRelease(u_lastSampleBuffer);
                    }
                    u_lastSampleBuffer = s_lastSampleBuffer;
                    CFRetain(u_lastSampleBuffer);
                    MRLog(@"校验录屏成功了!");
                }
            }
        }
    });
}

// 停止录屏采集
- (void)stopCapture
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(checkScreenRecorderAndRetry) object:nil];
    if (@available(iOS 11.0, *)) {
        runOnTheMainQueue(^{
            if ([RPScreenRecorder sharedRecorder].isRecording) {
                [RPScreenRecorder sharedRecorder].delegate = nil;
                [[RPScreenRecorder sharedRecorder] stopCaptureWithHandler:^(NSError * _Nullable error) {
                    MRLog(@"停止采集视频数据!");
                }];
            }
        });
    }
}

// 成员加入
- (void)onWebRTCUserJoin:(NSString *)userid playUrl:(NSString *)playUrl
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(RTCMRLiveSession:didJoinConferenceOfUserId:roomName:)]) {
        [self.delegate RTCMRLiveSession:self didJoinConferenceOfUserId:userid roomName:self.roomName];
    }
    UIView *playerView = [[UIView alloc] init];
    [self.playerViewDic setObject:playerView forKey:userid];
    
    TXLivePlayer *player = [self.livePlayerDic objectForKey:userid];
    if (!player) {
        PWMRLivePlayListenerWrapper *listenerWrapper = [[PWMRLivePlayListenerWrapper alloc] init];
        listenerWrapper.userId = userid;
        listenerWrapper.delegate = self;
        
        player = [[TXLivePlayer alloc] init];
        player.delegate = listenerWrapper;
        [player setRenderMode:RENDER_MODE_FILL_EDGE];
        
        TXLivePlayConfig *config = [[TXLivePlayConfig alloc] init];
        config.bAutoAdjustCacheTime = YES;
        config.cacheTime = 0.2;
        config.maxAutoAdjustCacheTime = 1.2;
        config.minAutoAdjustCacheTime = 0.2;
        config.connectRetryCount = 10;
        config.connectRetryInterval = 3;
        config.enableAEC = YES;
        
        [player setConfig:config];
        [self.livePlayerDic setObject:player forKey:userid];
        [self.playerEventDic setObject:listenerWrapper forKey:userid];
    }
    [player setupVideoWidget:CGRectZero containView:playerView insertIndex:0];
    [player startPlay:playUrl type:PLAY_TYPE_LIVE_RTMP_ACC];
}

// 成员离开
- (void)onWebRTCUserQuit:(NSString *)userid
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(RTCMRLiveSession:didLeaveConferenceOfUserId:roomName:)]) {
        [self.delegate RTCMRLiveSession:self didLeaveConferenceOfUserId:userid roomName:self.roomName];
    }
    // 关闭播放器
    // 更新UI
    [self deleteRemoteViewForUserId:userid];
}

// 移除成员
- (void)deleteRemoteViewForUserId:(NSString *)userId
{
    TXLivePlayer *player = [self.livePlayerDic objectForKey:userId];
    if (player) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [player stopPlay];
            [player removeVideoWidget];
            player.delegate = nil;
            UIView *playerView = [self.playerViewDic objectForKey:userId];
            [playerView removeFromSuperview];
        });
    }
    
    PWMRLivePlayListenerWrapper *playerEventWrapper = [self.playerEventDic objectForKey:userId];
    playerEventWrapper.delegate = nil;
    
    UIView *playerView = [self.playerViewDic objectForKey:userId];
    
    [self.livePlayerUrlDic removeObjectForKey:userId];
    [self.livePlayerDic removeObjectForKey:userId];
    [self.playerEventDic removeObjectForKey:userId];
    [self.playerViewDic removeObjectForKey:userId];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(RTCMRLiveSession:userId:didDetachRemoteView:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate RTCMRLiveSession:self userId:userId didDetachRemoteView:playerView];
        });
    }
}

#pragma mark - NotificationCenter

- (void)addNotificationCenter
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAppDidEnterBackGround:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAppWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAppWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAppDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
}

#pragma mark - public Method

- (BOOL)startConferenceWithPushUrl:(NSString *)pushUrl
{
    return [self startConferenceWithPushUrl:pushUrl roomName:nil];
}

- (BOOL)startConferenceWithPushUrl:(NSString *)pushUrl roomName:(NSString *)roomName
{
    _pushUrl = pushUrl;
    _roomName = roomName;
    if (self.livePusher == nil) {
        self.livePusher = [[TXLivePush alloc] initWithConfig:[[TXLivePushConfig alloc] init]];
        self.livePusher.delegate = self;
        [self setupConfigAndLivePusher];
        [self addNotificationCenter];
    }
    if ([self.livePusher startPush:pushUrl] == 0) {
        _runing = YES;
        if (!self.pureAudio) {
            [self startCapture];
        }
        return YES;
    }
    _runing = NO;
    
    return NO;
}

- (BOOL)stopConference
{
    if (!self.isRuning) {
        return YES;
    }
    _runing = NO;
    // 取消录屏检查
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(checkScreenRecorderAndRetry) object:nil];
    // 停止录屏采集
    [self stopCapture];
    // 释放delegate
    _livePusher.delegate = nil;
    [RPScreenRecorder sharedRecorder].delegate = nil;
    // 停止推流并释放
    [self.livePusher stopPush];
    [self releaseLivePusher];
    // 释放 buffer
    if (s_lastSampleBuffer) {
        CFRelease(s_lastSampleBuffer);
        s_lastSampleBuffer = NULL;
    }
    if (u_lastSampleBuffer) {
        CFRelease(u_lastSampleBuffer);
        u_lastSampleBuffer = NULL;
    }
    // 关闭所有播放器
    NSArray *allPlayer  = [self.livePlayerDic allValues];
    for (TXLivePlayer *player in allPlayer) {
        [player stopPlay];
        [player removeVideoWidget];
        player.delegate = nil;
    }
    [self.livePlayerUrlDic removeAllObjects];
    [self.livePlayerDic removeAllObjects];
    [self.playerViewDic removeAllObjects];
    [self.playerEventDic removeAllObjects];
    [self.userListArray removeAllObjects];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    return YES;
}

- (void)stopPushAudio:(BOOL)bEnable
{
    [self.livePusher setMute:bEnable];
}

- (void)stopPushVideo:(BOOL)bEnable
{
    self.enableVideo = !bEnable;
    if (self.enableVideo && !self.pureAudio) {
        [self startCapture];
    }
}

- (void)stopPlayAudio:(BOOL)bEnable
{
    if (bEnable) {
        NSArray *allPlayer  = [self.livePlayerDic allValues];
        for (TXLivePlayer *player in allPlayer) {
            [player setMute:YES];
        }
    }else {
        NSArray *allPlayer  = [self.livePlayerDic allValues];
        for (TXLivePlayer *player in allPlayer) {
            [player setMute:NO];
        }
    }
}

- (void)stopPlayVideo:(BOOL)bEnable
{
    if (bEnable) {
        NSArray *allPlayer  = [self.livePlayerDic allValues];
        for (TXLivePlayer *player in allPlayer) {
            [player pause];
        }
    }else {
        NSArray *allPlayer  = [self.livePlayerDic allValues];
        for (TXLivePlayer *player in allPlayer) {
            [player resume];
        }
    }
}

- (void)pausePush
{
    [self.livePusher pausePush];
}

- (void)playerUrl:(NSString *)url fromUserId:(NSString *)userId
{
    [self onWebRTCUserJoin:userId playUrl:url];
}

- (void)updateUserList:(NSArray *)userList
{
    if (userList == nil) {
        return;
    }
    // 判断哪些人是进房或者退房, userlist为空表示房间里只有自己了
    NSMutableArray *oldUserListArray = _userListArray;
    NSMutableArray *newUserListArray = [[NSMutableArray alloc] init];
    for (id dic in userList) {
        [newUserListArray addObject:dic[@"userId"]];
        [self.livePlayerUrlDic setValue:dic[@"playUrl"] forKey:dic[@"userId"]];
    }
    
    NSMutableSet *leaveSet = [[NSMutableSet alloc] init];
    for (id userid in oldUserListArray) {
        [leaveSet addObject:userid];
    }
    
    for (int i = 0; i < [newUserListArray count]; ++i) {
        id userid = newUserListArray[i];
        if ([leaveSet containsObject:userid]) {
            [leaveSet removeObject:userid];
        } else {
            NSDictionary *dic = userList[i];
            NSString *playUrl = dic[@"playUrl"];
            MRLog(@"加入房间: userID[%@] playUrl[%@]",userid,playUrl);
            dispatch_async(dispatch_get_main_queue(), ^{
                // 加入房间
                [self onWebRTCUserJoin:userid playUrl:playUrl];
            });
        }
    }
    // 退房
    for (id userid in leaveSet) {
        [self onWebRTCUserQuit:userid];
    }
    // 更新
    self.userListArray = newUserListArray;
}

- (void)snapshot:(void (^)(UIImage *image))snapshotCompletionBlock
{
    TXLivePlayer *player = self.livePlayerDic.allValues.firstObject;
    if (player) {
        [player snapshot:snapshotCompletionBlock];
    }
}

#pragma mark - asyncRun

typedef void (^block)(void);
- (void)asyncRun:(block)block
{
    dispatch_barrier_async(_sessionQueue, ^{
        block();
    });
}

void runOnTheMainQueue(void (^block)(void))
{
    if ([NSThread isMainThread]) {
        block();
    } else {
        dispatch_async(dispatch_get_main_queue(), block);
    }
}

#pragma mark - Handle App Life Style

- (void)onAppWillResignActive:(NSNotification*)notification
{
    _appIsInActive = NO;
    [_livePusher pausePush];
    if (!self.pureAudio) {
        [self stopCapture];
    }
}

- (void)onAppDidBecomeActive:(NSNotification*)notification
{
    _appIsInActive = YES;
    if (!_appIsBackground && _appIsInActive) {
        [_livePusher resumePush];
        if (!self.pureAudio) {
            [self startCapture];
        }
    }
}

- (void)onAppDidEnterBackGround:(NSNotification *)notification
{
    __weak typeof(self) weakSelf = self;
    self.backgroundTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf endBackgroundTask];
    }];
    
    _appIsBackground = YES;
    [_livePusher pausePush];
    if (!self.pureAudio) {
        [self stopCapture];
    }
}

- (void)onAppWillEnterForeground:(NSNotification *)notification
{
    [self endBackgroundTask];
    _appIsBackground = NO;
    if (!_appIsBackground && _appIsInActive) {
        [_livePusher resumePush];
    }
}

- (void)endBackgroundTask
{
    if (self.backgroundTask) {
        [[UIApplication sharedApplication] endBackgroundTask:self.backgroundTask];
        self.backgroundTask = UIBackgroundTaskInvalid;
    }
}

#pragma mark - TXLivePushListener protocol

- (void)onPushEvent:(int)EvtID withParam:(NSDictionary *)param
{
    [self asyncRun:^{
        // 网络断连,且经多次重连抢救无效,可以放弃治疗,更多重试请自行重启推流
        if (EvtID == PUSH_ERR_NET_DISCONNECT) {
            // 关闭会议并释放 需要重新加入会议需要重新初始化PWMRLiveSession
            [self stopConference];
            if (self.delegate && [self.delegate respondsToSelector:@selector(RTCMRLiveSession:rtcDidChangeState:)]) {
                [self.delegate RTCMRLiveSession:self rtcDidChangeState:MRRTC_ERR_NET_DISCONNECT];
            }
        } else if (EvtID == PUSH_EVT_ROOM_USERLIST) {
            NSString *msg = (NSString *)[param valueForKey:EVT_MSG];
            // 下发webrtc房间成员列表(不包括自己)
            [self onWebRTCUserListPush:msg];
            
        }  else if (EvtID == PUSH_EVT_ROOM_OUT) {
            // 不在webrtc房间里面，进房失败或者中途退出房间时通知;关闭会议并释放 需要重新加入会议需要重新初始化PWMRLiveSession
            [self stopConference];
            if (self.delegate && [self.delegate respondsToSelector:@selector(RTCMRLiveSession:rtcDidChangeState:)]) {
                [self.delegate RTCMRLiveSession:self rtcDidChangeState:MRRTC_ERR_ENTER_ROOM_OUT];
            }
        } else if (EvtID == PUSH_EVT_ROOM_NEED_REENTER) {
            // 需要重新进入房间，原因是网络发生切换，需要重新拉取最优的服务器地址
            if (self.delegate && [self.delegate respondsToSelector:@selector(RTCMRLiveSession:rtcDidChangeState:)]) {
                [self.delegate RTCMRLiveSession:self rtcDidChangeState:MRRTC_ERR_ROOM_NEED_REENTER];
            }
        } else if (EvtID == PUSH_ERR_OPEN_MIC_FAIL) {
            // 获取麦克风权限失败，请前往隐私-麦克风设置里面打开应用权限
            if (self.delegate && [self.delegate respondsToSelector:@selector(RTCMRLiveSession:rtcDidChangeState:)]) {
                [self.delegate RTCMRLiveSession:self rtcDidChangeState:MRRTC_ERR_OPEN_MIC_FAIL];
            }
        } else if (EvtID == PUSH_WARNING_NET_BUSY) {
            // 网络状况不佳
            if (self.delegate && [self.delegate respondsToSelector:@selector(RTCMRLiveSession:rtcDidChangeState:)]) {
                [self.delegate RTCMRLiveSession:self rtcDidChangeState:MRRTC_WARNING_NET_BUSY];
            }
        } else if (EvtID == PUSH_EVT_PUSH_BEGIN) {
            // 已经与服务器握手完毕,开始推流
            if (self.delegate && [self.delegate respondsToSelector:@selector(RTCMRLiveSession:rtcDidChangeState:)]) {
                [self.delegate RTCMRLiveSession:self rtcDidChangeState:MRRTC_ENTER_ROOM_SUCCESS];
            }
        }
    }];
}

-(void)onNetStatus:(NSDictionary*)param
{
    MRLog(@"onNetStatus = %@",param);
    if (self.delegate && [self.delegate respondsToSelector:@selector(RTCMRLiveSession:onNetStatus:)]) {
        [self.delegate RTCMRLiveSession:self onNetStatus:param];
    }
}

- (void)onWebRTCUserListPush:(NSString *)msg
{
    if (!msg) {
        return;
    }
    NSData *jsonData = [msg dataUsingEncoding:NSUTF8StringEncoding];
    NSError *err = NULL;
    NSDictionary *jsonDic = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&err];
    if (err) {
        return;
    }
    NSArray *userList = jsonDic[@"userlist"];
    if (userList == nil) {
        return;
    }
    [self updateUserList:userList];
}

#pragma mark - PWMRLivePlayListener protocol

- (void)onLivePlayEventOfUserId:(NSString *)userId eventID:(int)eventID param:(NSDictionary *)param
{
    [self asyncRun:^{
        
        if (eventID == PLAY_EVT_PLAY_BEGIN) {
            // NSLog(@"视频播放开始了 ：%@ param = %@",userId,param);
        }
        else if (eventID == PLAY_EVT_RCV_FIRST_I_FRAME){
            // 渲染首个视频数据包回调
            if (self.delegate && [self.delegate respondsToSelector:@selector(RTCMRLiveSession:firstVideoFrameDecodedOfUserId:remoteView:)]) {
                UIView *playerView = [self.playerViewDic objectForKey:userId];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.delegate RTCMRLiveSession:self firstVideoFrameDecodedOfUserId:userId remoteView:playerView];
                });
            }
        }
        else if (eventID == PLAY_ERR_NET_DISCONNECT){
            TXLivePlayer *player = [self.livePlayerDic objectForKey:userId];
            if (player) {
                NSString *playUrl = [self.livePlayerUrlDic objectForKey:userId];
                [player startPlay:playUrl type:PLAY_TYPE_LIVE_RTMP_ACC];
            }
        }
    }];
//    NSLog(@"PWMRLivePlayListener = %@",param);
}

- (void)onLivePlayNetStatusOfUserId:(NSString *)userId param:(NSDictionary *)param {
    
}

- (BOOL)isRecordingSucceed
{
    // 判断是否在录屏
    if ([RPScreenRecorder sharedRecorder].isRecording && s_lastSampleBuffer != u_lastSampleBuffer) {
        MRLog(@"正在录屏!");
        return YES;
    }
    
    return NO;
}

#pragma mark - screenRecorder

- (void)startCapture
{
    if (@available(iOS 11.0, *)) {
        runOnTheMainQueue(^{
           // 取消延时检查录屏状态
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(checkScreenRecorderAndRetry) object:nil];
            // 延时检查录屏状态
            [self performSelector:@selector(checkScreenRecorderAndRetry) withObject:nil afterDelay:3];
            
            // 判断是否在录屏
            if ([self isRecordingSucceed]) {
                MRLog(@"正在录屏!");
                return;
            }
            if (s_lastSampleBuffer) {
                [self.livePusher sendVideoSampleBuffer:s_lastSampleBuffer];
                // 更新最后一帧，用来检查是否录屏成功
                if (u_lastSampleBuffer) {
                    CFRelease(u_lastSampleBuffer);
                }
                u_lastSampleBuffer = s_lastSampleBuffer;
                CFRetain(u_lastSampleBuffer);
            }
            __weak PWMRLiveSession *weakSelf = self;
            [RPScreenRecorder sharedRecorder].delegate = self;
            [[RPScreenRecorder sharedRecorder] startCaptureWithHandler:^(CMSampleBufferRef  _Nonnull sampleBuffer, RPSampleBufferType bufferType, NSError * _Nullable error) {
                __strong PWMRLiveSession *strongSelf = weakSelf;
                if (!error) {
                    switch (bufferType) {
                        case RPSampleBufferTypeVideo:{
                            @autoreleasepool {
                                
                                if (!strongSelf.enableVideo) {
                                    return ;
                                }
                                
                                if (!CMSampleBufferIsValid(sampleBuffer))
                                    return;
                                
                                // 保存一帧在startPush时发送,防止推流启动后或切换横竖屏因无画面数据而推流不成功
                                if (s_lastSampleBuffer) {
                                    CFRelease(s_lastSampleBuffer);
                                }
                                s_lastSampleBuffer = sampleBuffer;
                                CFRetain(s_lastSampleBuffer);
                                
                                [strongSelf.livePusher sendVideoSampleBuffer:sampleBuffer];
                            }
                        }
                            // Handle video sample buffer
                            break;
                        case RPSampleBufferTypeAudioApp:
                            
                            break;
                        case RPSampleBufferTypeAudioMic:
                            // Handle audio sample buffer for mic audio
                            break;
                        default:
                            break;
                    }
                }
            } completionHandler:^(NSError * _Nullable error) {
                __strong PWMRLiveSession *strongSelf = weakSelf;
                if (!error) {
                    MRLog(@"录屏成功!");
                }else{
                    MRLog(@"录屏发生错误：%@",error);
                    if (error.code == -5807) {
                        if (strongSelf.delegate && [strongSelf.delegate respondsToSelector:@selector(RTCMRLiveSession:rtcDidChangeState:)]) {
                            [strongSelf.delegate RTCMRLiveSession:strongSelf rtcDidChangeState:MRRTC_ERR_OPEN_SCREEN_RECORDER_FAIL];
                        }
                    }
                    if (strongSelf.automaticrRetry && error.code != -5807) {
                        // 录屏发生错误：Error Domain=com.apple.ReplayKit.RPRecordingErrorDomain Code=-5807 "录制因多任务和调整内容大小而中断"
                        [strongSelf retryScreenRecorder];
                    }
                }
            }];
        });
    }
}

#pragma mark - RPScreenRecorderDelegate

- (void)screenRecorderDidChangeAvailability:(RPScreenRecorder *)screenRecorder \
{
    MRLog(@"screenRecorder change isRecording: %d",[RPScreenRecorder sharedRecorder].isRecording);
    if ([RPScreenRecorder sharedRecorder].isRecording == NO) {
        if (!self.pureAudio) {
            [self retryScreenRecorder];
        }
    }
//    if (!self.pureAudio) {
//        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(checkScreenRecorderAndRetry) object:nil];
//        [self performSelector:@selector(checkScreenRecorderAndRetry) withObject:nil afterDelay:5];
//    }
}

@end


