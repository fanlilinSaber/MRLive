//
//  PWAPIController.h
//  Unity-iPhone
//
//  Created by Dan Jiang on 2017/5/4.
//
//

#import <Foundation/Foundation.h>

extern NSString * const PWRequestDataTokenNoAvailNotification;

typedef enum {
    Get = 0,
    Post,
} NetworkMethod;

@interface PWAPIController : NSObject

+ (instancetype)sharedInstance;

/*&* <##>*/
@property (nonatomic, copy) NSString *toKen;
/*&* <##>*/
@property (nonatomic, assign,getter=isEnabledMD5Sign) BOOL enabledMD5Sign;


- (void)cancelAllDataTask;

- (void)cancelDataTask:(NSInteger)taskIdentifier;

- (instancetype)initWithBaseURL:(NSString *)baseURL;

- (void)sendRequest:(NSURLRequest *)request
            success:(void (^)(NSString *message, id data))success
              error:(void (^)(NSString *message, int code))error
            failure:(void (^)(NSError *error))failure;

- (void)sendRequestWillRedirect:(NSURLRequest *)request
                       redirect:(void (^)(NSString *url))redirect;

- (NSMutableURLRequest *)requestWithMethod:(NSString *)method
                                 URLString:(NSString *)URLString
                                parameters:(id)parameters;

/**
 request params 默认 EnabledSign YES
 
 @param aPath aPath
 @param params params get url拼接 or post body form 表单形式
 @param method method
 @param success success block
 @param error error block
 @param failure failure block
 */
- (void)requestJsonDataWithPath:(NSString *)aPath
                     withParams:(NSDictionary *)params
                 withMethodType:(NetworkMethod)method
                     andSuccess:(void (^)(NSString *message, id data))success
                       andError:(void (^)(NSString *message, int code))error
                     andFailure:(void (^)(NSError *error))failure;

- (void)requestJsonDataWithPath:(NSString *)aPath
                     withParams:(NSDictionary *)params
                 withMethodType:(NetworkMethod)method
                withEnabledSign:(BOOL)enabledSign
                     andSuccess:(void (^)(NSString *message, id data))success
                       andError:(void (^)(NSString *message, int code))error
                     andFailure:(void (^)(NSError *error))failure;

- (void)requestJsonDataWithPath:(NSString *)aPath
                     withParams:(NSDictionary *)params
                 withMethodType:(NetworkMethod)method
              andTaskIdentifier:(void (^)(NSInteger taskIdentifier))taskIdentifier
                     andSuccess:(void (^)(NSString *message, id data))success
                       andError:(void (^)(NSString *message, int code))error
                     andFailure:(void (^)(NSError *error))failure;

/**
 request body 默认 EnabledSign YES

 @param aPath aPath
 @param params params 为 body 里为 json格式
 @param method method
 @param success success block
 @param error error block
 @param failure failure block
 */
- (void)requestBodyJsonDataWithPath:(NSString *)aPath
                         withParams:(NSDictionary *)params
                     withMethodType:(NetworkMethod)method
                         andSuccess:(void (^)(NSString *message, id data))success
                           andError:(void (^)(NSString *message, int code))error
                         andFailure:(void (^)(NSError *error))failure;

- (void)requestBodyJsonDataWithPath:(NSString *)aPath
                         withParams:(NSDictionary *)params
                     withMethodType:(NetworkMethod)method
                    withEnabledSign:(BOOL)enabledSign
                         andSuccess:(void (^)(NSString *message, id data))success
                           andError:(void (^)(NSString *message, int code))error
                         andFailure:(void (^)(NSError *error))failure;


- (void)downloadFileWithPath:(NSString *)aPath
                  withParams:(NSDictionary *)params
            downloadProgress:(void (^)(NSProgress *downloadProgress))downloadProgressBlock
             downloadSuccess:(void (^)(NSURLResponse *response, NSURL *filePath))downloadSuccessBlock
             downloadFailure:(void (^)(NSError *error))downloadFailureBlock;

@end
