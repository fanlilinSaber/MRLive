//
//  PWMRLivePlayListenerWrapper.h
//  PWMRLive
//
//  Created by 范李林 on 2018/7/17.
//  Copyright © 2018年 FLL. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <TXLiteAVSDK_Professional/TXLivePlayListener.h>

// @protocol 视频播放回调协议
@protocol PWMRLivePlayListener <NSObject>
@optional
// 视频播放事件的回调
-(void)onLivePlayEventOfUserId:(NSString *)userId eventID:(int)eventID param:(NSDictionary *)param;
// 视频播放网络状态的回调
-(void)onLivePlayNetStatusOfUserId:(NSString *)userId param:(NSDictionary *)param;
@end

/**
 *  *&* 视频播放代理的 delegate Wrapper*
 */
@interface PWMRLivePlayListenerWrapper : NSObject<TXLivePlayListener>
/*&* userId*/
@property (nonatomic, copy) NSString *userId;
/*&* delegate*/
@property (nonatomic, weak) id<PWMRLivePlayListener> delegate;
@end
