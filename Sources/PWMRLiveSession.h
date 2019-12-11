//
//  PWMRLiveSession.h
//  PWMRLive
//
//  Created by 范李林 on 2018/7/12.
//  Copyright © 2018年 FLL. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class PWMRLiveSession;
/**
 *  *&* 直播推流视频质量*
 */
typedef NS_ENUM(NSInteger, PWMRLiveVideoQuality) {
    /*&* 标清*/
    MR_VIDEO_QUALITY_STANDARD_DEFINITION      = 1,
    /*&* 高清*/
    MR_VIDEO_QUALITY_HIGH_DEFINITION          = 2,
    /*&* 超清*/
    MR_VIDEO_QUALITY_SUPER_DEFINITION         = 3,
    /*&* 自适应录屏的分辨率*/
    MR_VIDEO_QUALITY_AUTO_DEFINITION          = 4,
};

/**
 *  *&* 连麦状态*
 */
typedef NS_ENUM(NSUInteger, MRRTCState) {
    /*&* 加入连麦成功*/
    MRRTC_ENTER_ROOM_SUCCESS = -1,
    /*&* 加入连麦失败或者超时*/
    MRRTC_ERR_ENTER_ROOM_OUT = -2,
    /*&* 网络异常*/
    MRRTC_ERR_NET_DISCONNECT = -3,
    /*&* 重新进入房间，原因是网络发生切换*/
    MRRTC_ERR_ROOM_NEED_REENTER = -4,
    /*&* 获取麦克风权限失败*/
    MRRTC_ERR_OPEN_MIC_FAIL = -5,
    /*&* 调用系统屏幕录制失败*/
    MRRTC_ERR_OPEN_SCREEN_RECORDER_FAIL = -6,
    /*&* 网络不佳*/
    MRRTC_WARNING_NET_BUSY = -7,
    /*&* 尝试重新启动录屏*/
    MRRTC_TRY_OPEN_SCREEN_RECORDER = -8
};

// @protocol
@protocol PWMRLiveSessionDelegate <NSObject>
@optional
// 连麦状态已变更的回调
- (void)RTCMRLiveSession:(PWMRLiveSession *)session rtcDidChangeState:(MRRTCState)state;
// 连麦时，远端用户（以 userID 标识）的视频首帧解码后的回调
- (void)RTCMRLiveSession:(PWMRLiveSession *)session firstVideoFrameDecodedOfUserId:(NSString *)userId remoteView:(UIView *)remoteView;
// 连麦时，取消远端用户（以 userID 标识）的视频 后的回调
- (void)RTCMRLiveSession:(PWMRLiveSession *)session userId:(NSString *)userId didDetachRemoteView:(UIView *)remoteView;
// 其它连麦者加入了房间的回调
- (void)RTCMRLiveSession:(PWMRLiveSession *)session didJoinConferenceOfUserId:(NSString *)userId roomName:(NSString *)roomName;
// 其它连麦者离开了房间的回调
- (void)RTCMRLiveSession:(PWMRLiveSession *)session didLeaveConferenceOfUserId:(NSString *)userId roomName:(NSString *)roomName;
// 推流状态(比如码率、分辨率、FPS等)的回调
- (void)RTCMRLiveSession:(PWMRLiveSession *)session onNetStatus:(NSDictionary *)param;

@end

/**
 *  *&* 录屏直播推流 核心 Session*
 */
@interface PWMRLiveSession : NSObject

/**
 init

 @param videoSize 编码视频分辨率
 @param videoBitratePIN 视频固定码率
 @param videoBitrateMin 视频最小码率
 @param videoBitrateMax 视频最大码率
 @param videoFPS 视频帧率
 @param adjustBitrate 动态码率
 @param adjustResolution 动态分辨率
 @param pureAudio 是否纯音频推流
 @return PWMRLiveSession Object
 */
- (instancetype)initWithVideoSize:(CGSize)videoSize
                  videoBitratePIN:(int)videoBitratePIN
                  videoBitrateMin:(int)videoBitrateMin
                  videoBitrateMax:(int)videoBitrateMax
                         videoFPS:(int)videoFPS
                    adjustBitrate:(BOOL)adjustBitrate
                 adjustResolution:(BOOL)adjustResolution
                        pureAudio:(BOOL)pureAudio;

/**
 init

 @param videoQuality 直播推流视频质量
 @param adjustBitrate 动态码率
 @param adjustResolution 动态分辨率
 @param pureAudio 是否纯音频推流
 @return PWMRLiveSession Object
 */
- (instancetype)initWithVideoQuality:(PWMRLiveVideoQuality)videoQuality adjustBitrate:(BOOL)adjustBitrate adjustResolution:(BOOL)adjustResolution pureAudio:(BOOL)pureAudio;

/*&* delegate*/
@property (nonatomic, weak) id<PWMRLiveSessionDelegate> delegate;
/*&* 设置后台推流图片*/
@property (nonatomic, strong) UIImage *pauseImg;
/*&* 是否 runing*/
@property (nonatomic, assign, getter=isRuning, readonly) BOOL runing;
/*&* 是否开启回声消除, 默认值为NO*/
@property(nonatomic, assign) BOOL enableAEC;
/*&* 是否开启耳返, 默认值为NO*/
@property(nonatomic, assign) BOOL enableAudioPreview;
/*&* 自动重试调用系统api*/
@property (nonatomic, assign) BOOL automaticrRetry;
/*&* 是否纯音频推流*/
@property (nonatomic, assign) BOOL pureAudio;

/**
 开始MR会议
 
 @param pushUrl 推流地址
 @return 成功 or 失败
 */
- (BOOL)startConferenceWithPushUrl:(NSString *)pushUrl;

/**
 开始MR会议

 @param pushUrl 推流地址
 @param roomName 房间名
 @return 成功 or 失败
 */
- (BOOL)startConferenceWithPushUrl:(NSString *)pushUrl roomName:(NSString *)roomName;

/**
 停止MR会议并释放

 @return YES
 */
- (BOOL)stopConference;

/**
 关闭推流音频（静音）

 @param bEnable YES or NO
 */
- (void)stopPushAudio:(BOOL)bEnable;

/**
 关闭推流视频

 @param bEnable YES or NO
 */
- (void)stopPushVideo:(BOOL)bEnable;

/**
 关闭播放全部音频

 @param bEnable YES or NO
 */
- (void)stopPlayAudio:(BOOL)bEnable;

/**
 关闭播放的全部视频

 @param bEnable YES or NO
 */
- (void)stopPlayVideo:(BOOL)bEnable;

/**
 暂停推流
 */
- (void)pausePush;

/**
 播放指定流媒体

 @param url 流地址
 @param userId 流管理id
 */
- (void)playerUrl:(NSString *)url fromUserId:(NSString *)userId;

/**
 更新播放user列表

 @param userList 包含 userId 和 playUrl 的dict
 */
- (void)updateUserList:(NSArray *)userList;

/*
 * 截屏
 * @param snapshotCompletionBlock 通过回调返回当前图像
 */
- (void)snapshot:(void (^)(UIImage *image))snapshotCompletionBlock;

@end
