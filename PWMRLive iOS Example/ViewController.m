//
//  ViewController.m
//  PWMRLive iOS Example
//
//  Created by 范李林 on 2018/7/12.
//  Copyright © 2018年 FLL. All rights reserved.
//

#import "ViewController.h"
#import <Masonry.h>
#import <AFNetworking/AFNetworking.h>
#import "PWMRLive.h"
#import "PWAPIController.h"

@interface ViewController ()<PWMRLiveSessionDelegate>
{
    NSString                 *_pushUrl;        // 推流地址
    NSString                 *_userID;         // 用户账号，字符串类型，在SDK里面叫openid
    NSString                 *_pwd;            // 用户密码
    uint32_t                 _roomID;          // 房间号
    uint32_t                 _sdkappid;        // 在腾讯云后台注册的产品sdkappid
}
@property (weak, nonatomic) IBOutlet UITextField *room_textField;
@property (weak, nonatomic) IBOutlet UITextField *username_textField;
/*&* <##>*/
@property (nonatomic, assign) BOOL joinState;
/*&* <##>*/
@property (nonatomic, strong) PWMRLiveSession *liveSession;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    _pwd = @"345f";
    _sdkappid = 1400037025;
//    [[PWAPIController sharedInstance] setToKen:@"cff18d51f6af84a660757b5042c69ca9"];

}

- (IBAction)myLive:(UIButton *)sender {
    [[PWAPIController sharedInstance] setToKen:@"d7fb28c59f76a56cd9c6ec91cdeba9ea"];
    if (self.joinState) {
        
    }else {
        if (self.room_textField.text.length == 0) {
            self.room_textField.text = @"1237";
        }
        if (self.username_textField.text.length == 0) {
            self.username_textField.text = @"webrtc33";
        }
        _roomID = (uint32_t)[self.room_textField.text integerValue];
        _userID = self.username_textField.text;
        if (_liveSession == nil) {
            _liveSession = [[PWMRLiveSession alloc] initWithVideoQuality:MR_VIDEO_QUALITY_AUTO_DEFINITION adjustBitrate:YES adjustResolution:NO pureAudio:NO];
            _liveSession.delegate = self;
        }
        
//        [self getRoomSig:^(NSString *roomSig) {
//            NSLog(@"roomSig : %@",roomSig);
//            if (roomSig) {
//                // 注意roomSig是一个json串，里面有空格，需要先url编码
//                NSString *strUrl = [NSString stringWithFormat:@"room://cloud.tencent.com?sdkappid=%u&roomid=%u&userid=%@&roomsig=%@",
//                                    _sdkappid, _roomID, _userID, roomSig];
//                self->_pushUrl = [strUrl stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
//                if (![self.liveSession startConferenceWithPushUrl:self->_pushUrl]) {
//                    return;
//                }
//
//            }
//
//        }];
        
        [self getPushUrlAndSuccess:^(NSString *message) {
//            self->_pushUrl = [message stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            NSString *url = @"room://cloud.tencent.com?sdkappid=1400113039&roomid=470371&userid=201767458583146496&roomsig=%7B%22Key%22%3A%2290dfe9498d0136945a1df42d5df2e7f27d398d85f8b909f28252a5ab260ac0e16750d6fdf16d1890e83b286265944a1e40d74b8ba1906709461bce32513ae81e32959526e7b9f47f558e7501c1cb7edd197136437e326c16%22%2C%22AccessList%22%3A%5B%7B%22Type%22%3A2%2C%22Ip%22%3A%22101.226.211.190%22%2C%22Port%22%3A1935%7D%2C%7B%22Type%22%3A2%2C%22Ip%22%3A%22183.3.225.15%22%2C%22Port%22%3A1935%7D%5D%2C%22RtmpProxy%22%3A%7B%22Type%22%3A3%2C%22Ip%22%3A%22100.65.76.106%22%2C%22Port%22%3A30002%7D%7D";


            if (![self.liveSession startConferenceWithPushUrl:message]) {
                NSLog(@"连麦失败");
                return;
            }
            NSLog(@"连麦成功");
        }];
        
//        NSString *url = @"room://cloud.tencent.com?sdkappid=1400113039&roomid=373846&userid=189433741206417408&roomsig=%7B%22Key%22%3A%22c1e72e927169aea24589e332d9269902104952d90c1630f8235b0eb49737b8efb902b8425e34e2b423f2f83f0b3aad53d307133f55a6a96e76ff8ad23b7eee4e6826c767e96ceed0db75c654296e3066e24df3d2f89f6418%22%2C%22AccessList%22%3A%5B%7B%22Type%22%3A2%2C%22Ip%22%3A%22101.226.211.190%22%2C%22Port%22%3A1935%7D%2C%7B%22Type%22%3A2%2C%22Ip%22%3A%22123.151.79.149%22%2C%22Port%22%3A1935%7D%5D%2C%22RtmpProxy%22%3A%7B%22Type%22%3A3%2C%22Ip%22%3A%22100.65.76.106%22%2C%22Port%22%3A30003%7D%7D";
//
//
//        if (![self.liveSession startConferenceWithPushUrl:url]) {
//            NSLog(@"连麦失败");
//            return;
//        }
//        NSLog(@"连麦成功");
    
    }
}

- (IBAction)joinLive:(UIButton *)sender {
    [[PWAPIController sharedInstance] setToKen:@"03924c8dffb792dc9aaec6d9b7ce2a07"];
    if (self.joinState) {
        
    }else {
        if (self.room_textField.text.length == 0) {
            self.room_textField.text = @"1237";
        }
        if (self.username_textField.text.length == 0) {
            self.username_textField.text = @"webrtc44";
        }
        _roomID = (uint32_t)[self.room_textField.text integerValue];
        _userID = self.username_textField.text;
        if (_liveSession == nil) {
            _liveSession = [[PWMRLiveSession alloc] initWithVideoQuality:1 adjustBitrate:YES adjustResolution:NO pureAudio:YES];
            _liveSession.delegate = self;
        }
        
//        [self getRoomSig:^(NSString *roomSig) {
//            NSLog(@"roomSig : %@",roomSig);
//            if (roomSig) {
//                // 注意roomSig是一个json串，里面有空格，需要先url编码
//                NSString *strUrl = [NSString stringWithFormat:@"room://cloud.tencent.com?sdkappid=%u&roomid=%u&userid=%@&roomsig=%@",
//                                    _sdkappid, _roomID, _userID, roomSig];
//                self->_pushUrl = [strUrl stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
//                if (![self.liveSession startConferenceWithPushUrl:self->_pushUrl]) {
//                    return;
//                }
//
//            }
//
//        }];
        
        [[PWAPIController sharedInstance] requestJsonDataWithPath:@"api/live/joinRoom" withParams:@{@"roomId" : @(_roomID)} withMethodType:Post andSuccess:^(NSString *message, id data) {
            NSLog(@"data = %@",data);
            NSString *rtmpPush = data[@"rtmpPush"];
            
            if (![self.liveSession startConferenceWithPushUrl:rtmpPush]) {
                NSLog(@"连麦失败");
                return;
            }
            NSLog(@"连麦成功");
            
        } andError:^(NSString *message, int code) {
            NSLog(@"message = %@",message);
        } andFailure:^(NSError *error) {
            NSLog(@"error = %@",error);
        }];
        
//        [self getPushUrlAndSuccess:^(NSString *message) {
////            self->_pushUrl = [message stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
//            if (![self.liveSession startConferenceWithPushUrl:message]) {
//                NSLog(@"连麦失败");
//                return;
//            }
//            NSLog(@"连麦成功");
//        }];
    }
}

- (IBAction)closeLive:(UIButton *)sender {
    if ([self.liveSession stopConference]) {
        self.liveSession = nil;
    }
}

- (IBAction)closeSendAudio:(UIButton *)sender {
    sender.selected = !sender.selected;
    [self.liveSession stopPushAudio:sender.selected];
}

- (IBAction)closeSendVideo:(UIButton *)sender {
    sender.selected = !sender.selected;
    [self.liveSession stopPushVideo:sender.selected];
}

#pragma mark - PWMRLiveSessionDelegate
- (void)RTCMRLiveSession:(PWMRLiveSession *)session firstVideoFrameDecodedOfUserId:(NSString *)userId remoteView:(UIView *)remoteView {
    UIView *video = remoteView;
    video.frame = CGRectMake(100, 200, 300, 300);
    NSLog(@"video= %@",remoteView);
    [self.view addSubview:video];
}

/**
 连麦时，取消远端用户（以 userID 标识）的视频 后的回调
 
 @param session session
 @param userId userId
 @param remoteView 渲染视频播放的view
 */
- (void)RTCMRLiveSession:(PWMRLiveSession *)session userId:(NSString *)userId didDetachRemoteView:(UIView *)remoteView {
    
    [remoteView removeFromSuperview];
    
    NSLog(@"取消远端用户（以 userID 标识）的视频 后的回调");
}

/**
 连麦状态已变更的回调
 
 @param session session
 @param state 回调状态
 */
- (void)RTCMRLiveSession:(PWMRLiveSession *)session rtcDidChangeState:(MRRTCState)state {
    NSLog(@" 连麦状态已变更的回调 rtcDidChangeState = %ld",state);
}




/**
 userID 加入房间
 
 @param session session
 @param userId userId
 @param roomName 房间号
 */
- (void)RTCMRLiveSession:(PWMRLiveSession *)session didJoinConferenceOfUserId:(NSString *)userId roomName:(NSString *)roomName {
    NSLog(@" 加入房间 didJoinConferenceOfUserId = %@ roomName = %@",userId,roomName);
}

/**
 userID 离开房间
 
 @param session session
 @param userId userId
 @param roomName 房间号
 */
- (void)RTCMRLiveSession:(PWMRLiveSession *)session didLeaveConferenceOfUserId:(NSString *)userId roomName:(NSString *)roomName {
    NSLog(@" 离开房间 didLeaveConferenceOfUserId = %@ roomName = %@",userId,roomName);
}


typedef void (^GetPushUrlCompletion)(NSString *url);

- (void)getPushUrlAndSuccess:(void (^)(NSString *message))success {
    [[PWAPIController sharedInstance] requestJsonDataWithPath:@"api/live/createRoom" withParams:nil withMethodType:Post andSuccess:^(NSString *message, id data) {
        NSLog(@"data = %@",data);
        NSString *rtmpPush = data[@"rtmpPush"];
        NSString *mrcoopId = data[@"mrcoopId"];
        self.room_textField.text = mrcoopId;
        success(rtmpPush);
        
    } andError:^(NSString *message, int code) {
        NSLog(@"message = %@",message);
    } andFailure:^(NSError *error) {
        NSLog(@"error = %@",error);
    }];
    
}

// 获取进房签名
typedef void (^IGetRoomSigCompletion)(NSString *roomSig);
- (void)getRoomSig:(IGetRoomSigCompletion)completion {
    [self loginAppServer:_userID pwd:_pwd roomID:_roomID sdkappid:_sdkappid withCompletion:^(NSString *userSig, NSString *privMapEncrypt) {
        if (userSig && privMapEncrypt) {
            [self requestSigServer:_userID userSig:userSig privMapEncrypt:privMapEncrypt roomID:_roomID sdkappid:_sdkappid withCompletion:^(NSString *roomSig) {
                if (completion) {
                    completion(roomSig);
                }
            }];
        } else if (completion) {
            completion(nil);
        }
    }];
}

// 请求腾讯云签名服务器，拿到roomSig，用来进入WebRTC房间
typedef void (^IRequestSigCompletion)(NSString *roomSig);
- (void)requestSigServer:(NSString *)userID userSig:(NSString *)userSig privMapEncrypt:(NSString *)privMapEncrypt roomID:(uint32_t)roomID sdkappid:(uint32_t)sdkappid withCompletion:(IRequestSigCompletion)completion {
    NSDictionary *reqHead = @{@"Cmd": @(1), @"SeqNo": @(1), @"BusType": @(7), @"GroupId": @(roomID)};
    NSDictionary *reqBody = @{@"PrivMapEncrypt": privMapEncrypt, @"TerminalType": @(1), @"FromType": @(3), @"SdkVersion": @(26280566)};
    
    NSDictionary *reqParam = @{@"ReqHead": reqHead, @"ReqBody": reqBody};
    
    NSString *reqUrl = nil;
    
    // 测试环境
    reqUrl = [NSString stringWithFormat:@"https://test.tim.qq.com/v4/openim/jsonvideoapp?sdkappid=%u&identifier=%@&usersig=%@&random=9999&contenttype=json", sdkappid, userID,
              userSig];
    
    //        reqUrl = [NSString stringWithFormat:@"https://yun.tim.qq.com/v4/openim/jsonvideoapp?sdkappid=%u&identifier=%@&usersig=%@&random=9999&contenttype=json", sdkappid, userID, userSig];
    [self POST:reqUrl parameters:reqParam retryCount:0 retryLimit:5 progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        dispatch_async(dispatch_get_main_queue(), ^{
            id rspHead = responseObject[@"RspHead"];
            id rspBody = responseObject[@"RspBody"];
            NSLog(@"requestSigServer:[%@]", responseObject);
            
            if ([rspHead[@"ErrorCode"] integerValue] != 0) {
                
                
                // 有错误就返回nil
                if (completion) {
                    completion(nil);
                }
                return;
            }
            
            // 将rspBody作为roomSig返回
            if (completion) {
                if (rspBody) {
                    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:rspBody options:NSJSONWritingPrettyPrinted error:NULL];
                    NSString *roomSig = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                    completion(roomSig);
                } else {
                    completion(nil);
                }
            }
            
        });
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(nil);
            }
        });
    }];
}

#pragma mark - 登录和鉴权

// 登录客户自己的服务器，拿到userSig和privMapEncrypt，用于获取roomSig
typedef void (^ILoginAppCompletion)(NSString *userSig, NSString *privMapEncrypt);
- (void)loginAppServer:(NSString *)userID pwd:(NSString *)pwd roomID:(uint32_t)roomID sdkappid:(uint32_t)sdkappid withCompletion:(ILoginAppCompletion)completion {
    NSDictionary *reqParam = @{@"identifier": userID, @"pwd": pwd, @"appid": @(sdkappid), @"roomnum": @(roomID), @"privMap": @(255)};
    NSString *reqUrl = @"https://sxb.qcloud.com/sxb_dev/?svc=account&cmd=authPrivMap";
    
    [self POST:reqUrl parameters:reqParam retryCount:0 retryLimit:5 progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        dispatch_async(dispatch_get_main_queue(), ^{
            id data = responseObject[@"data"];
            id userSig = data[@"userSig"];
            id privMapEncrypt = data[@"privMapEncrypt"];
            NSLog(@"loginAppServer:[%@]", responseObject);
            if (userSig == nil || privMapEncrypt == nil) {
                
            }
            
            if (completion) {
                completion(userSig, privMapEncrypt);
            }
        });
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(nil, nil);
            }
        });
    }];
}

// 网络请求包装，每次请求重试若干次
- (void)POST:(NSString *)URLString
  parameters:(id)parameters
  retryCount:(NSInteger)retryCount
  retryLimit:(NSInteger)retryLimit
    progress:(void (^)(NSProgress * _Nonnull))uploadProgress
     success:(void (^)(NSURLSessionDataTask * _Nonnull, id _Nullable))success
     failure:(void (^)(NSURLSessionDataTask * _Nullable, NSError * _Nonnull))failure {
    
    AFHTTPSessionManager *_httpSession;
    _httpSession = [AFHTTPSessionManager manager];
    [_httpSession setRequestSerializer:[AFJSONRequestSerializer serializer]];
    [_httpSession setResponseSerializer:[AFJSONResponseSerializer serializer]];
    [_httpSession.requestSerializer willChangeValueForKey:@"timeoutInterval"];
    _httpSession.requestSerializer.timeoutInterval = 5.0;
    [_httpSession.requestSerializer didChangeValueForKey:@"timeoutInterval"];
    _httpSession.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/json", @"text/javascript", @"text/html", @"text/xml", @"text/plain", nil];
    
    [_httpSession POST:URLString parameters:parameters progress:uploadProgress success:success failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (retryCount < retryLimit) {
            // 1秒后重试
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                
                [self POST:URLString parameters:parameters retryCount:retryCount+1 retryLimit:retryLimit progress:uploadProgress success:success failure:failure];
            });
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (failure) {
                    failure(task, error);
                }
            });
        }
        
    }];
}

- (void)axcBasePopUpPromptAlertViewWithTitle:(NSString *)title
                                     message:(NSString *)message
                                     handler:(void (^ __nullable)(UIAlertAction *action))handler{
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *action = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:handler];
    [alert addAction:action];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)axcBasePopUpPromptAlertViewWithTitle:(NSString *)title
                                     message:(NSString *)message
                                     handler:(void (^ __nullable)(UIAlertAction *action))handler
                               cancelHandler:(void (^ __nullable)(UIAlertAction *action))cancelHandler{
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *action = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:handler];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleDestructive handler:cancelHandler];
    [alert addAction:action];
    [alert addAction:cancelAction];
    [self presentViewController:alert animated:YES completion:nil];
}


@end
