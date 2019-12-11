//
//  PWMRLivePlayListenerWrapper.m
//  PWMRLive
//
//  Created by 范李林 on 2018/7/17.
//  Copyright © 2018年 FLL. All rights reserved.
//

#import "PWMRLivePlayListenerWrapper.h"

@implementation PWMRLivePlayListenerWrapper

#pragma mark - TXLivePlayListener protocol

- (void)onPlayEvent:(int)EvtID withParam:(NSDictionary *)param
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(onLivePlayEventOfUserId:eventID:param:)]) {
        [self.delegate onLivePlayEventOfUserId:self.userId eventID:EvtID param:param];
    }
}

- (void)onNetStatus:(NSDictionary *)param
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(onLivePlayNetStatusOfUserId:param:)]) {
        [self.delegate onLivePlayNetStatusOfUserId:self.userId param:param];
    }
}

@end
