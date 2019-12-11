//
//  PWAPIController.m
//  Unity-iPhone
//
//  Created by Dan Jiang on 2017/5/4.
//
//

#import "PWAPIController.h"
#import <AFNetworking/AFNetworking.h>
#import "NSString+Additions.h"

NSString *const PWRequestDataTokenNoAvailNotification = @"PWRequestDataTokenNoAvailNotification";

typedef NSString * (^AFQueryStringSerializationBlock)(NSString *urlString, id parameters, NSError *__autoreleasing *error);

/*&* 启用 htpps*/
static BOOL enabledSecurity = NO;

@interface PWAPIController ()

@property (strong, nonatomic) AFHTTPSessionManager *manager;
@property (copy, nonatomic) NSString *baseURL;
@property (copy, nonatomic) NSString *cliInfo;

@property (nonatomic, strong) AFHTTPRequestSerializer <AFURLRequestSerialization> * requestFormSerializer;

@property (nonatomic, strong) AFJSONRequestSerializer <AFURLRequestSerialization> * requestJsonSerializer;

/*&* <##>*/
@property (nonatomic, copy) AFQueryStringSerializationBlock queryStringJsonSerialization;
@end

@implementation PWAPIController

+ (instancetype)sharedInstance {
    static id sharedInstance = nil;
    
//    NSString *resourceServer = [[NSUserDefaults standardUserDefaults] stringForKey:PWResourceServerKey];
//    NSAssert(resourceServer != nil, @"Resource server is not ready");
    NSString *resourceServer = @"http://101.132.181.123";
//    NSString *resourceServer = @"http://192.168.0.137:9001";
    if ([resourceServer hasPrefix:@"https://"]) {
        enabledSecurity = YES;
    }else {
        enabledSecurity = NO;
    }
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{        
        sharedInstance = [[self alloc] initWithBaseURL:resourceServer];
    });
    
    return sharedInstance;
}

- (AFSecurityPolicy *)customSecurityPolicy {
    /*&* 先导入证书 证书由服务端生成，具体由服务端人员操作*/
    NSString *cerPath = [[NSBundle mainBundle] pathForResource:@"marsdt" ofType:@"cer"];
    NSData *cerData = [NSData dataWithContentsOfFile:cerPath];
    NSSet *certSet = [NSSet setWithObject:cerData];
    /*&* AFSSLPinningModeCertificate 使用证书验证模式*/
    AFSecurityPolicy *securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate withPinnedCertificates:certSet];
    /*&* 如果是需要验证自建证书，需要设置为YES*/
    securityPolicy.allowInvalidCertificates = YES;
    //validatesDomainName 是否需要验证域名，默认为YES;
    //假如证书的域名与你请求的域名不一致，需把该项设置为NO；如设成NO的话，即服务器使用其他可信任机构颁发的证书，也可以建立连接，这个非常危险，建议打开。
    //置为NO，主要用于这种情况：客户端请求的是子域名，而证书上的是另外一个域名。因为SSL证书上的域名是独立的，假如证书上注册的域名是www.google.com，那么mail.google.com是无法验证通过的；当然，有钱可以注册通配符的域名*.google.com，但这个还是比较贵的。
    //如置为NO，建议自己添加对应域名的校验逻辑。
    securityPolicy.validatesDomainName = NO;
    
    return securityPolicy;
}

- (void)setEnabledMD5Sign:(BOOL)enabledMD5Sign {
    if (_enabledMD5Sign != enabledMD5Sign) {
        _enabledMD5Sign = enabledMD5Sign;
        if (enabledMD5Sign) {
            [self registerQueryStringSerializationWithBlock];
        }else {
            [self.requestFormSerializer setQueryStringSerializationWithBlock:nil];
        }
    }
}

- (void)cancelAllDataTask{
    for (NSURLSessionDataTask *dataTask in self.manager.dataTasks) {
        if (dataTask.state != NSURLSessionTaskStateCompleted) {
//            NSLog(@"taskIdentifier = %ld",dataTask.taskIdentifier);
            [dataTask cancel];
        }
    }
}

- (void)cancelDataTask:(NSInteger)taskIdentifier{
    for (NSURLSessionDataTask *dataTask in self.manager.dataTasks) {
        if (dataTask.taskIdentifier == taskIdentifier) {
            if (dataTask.state != NSURLSessionTaskStateCompleted) {
                [dataTask cancel];
            }
            break;
        }
    }
}

- (void)cancelAllDownloadTask{
    for (NSURLSessionDataTask *downloadTask in self.manager.downloadTasks) {
        if (downloadTask.state != NSURLSessionTaskStateCompleted) {
            [downloadTask cancel];
        }
    }
}

- (void)sendRequestDataTokenNoAvailNotification {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:PWRequestDataTokenNoAvailNotification object:nil];
    });
}

- (instancetype)initWithBaseURL:(NSString *)baseURL {
    self = [super init];
    if (self) {
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        self.manager = [[AFHTTPSessionManager alloc] initWithBaseURL:[NSURL URLWithString:baseURL] sessionConfiguration:configuration];
        self.requestFormSerializer = [AFHTTPRequestSerializer serializer];
        self.requestJsonSerializer = [AFJSONRequestSerializer serializer];
        self.baseURL = baseURL;
        NSMutableString *cliInfo = [NSMutableString new];
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
            [cliInfo appendString:@"phone"];
        } else {
            [cliInfo appendString:@"tablet"];
        }
        [cliInfo appendFormat:@"&%@", @"IOS"];
        NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
        NSString *version = [infoDictionary objectForKey:@"CFBundleShortVersionString"];
        NSString *build = [infoDictionary objectForKey:@"CFBundleVersion"];
        [cliInfo appendFormat:@"&%@b%@", version, build];
        CGRect bounds = UIScreen.mainScreen.bounds;
        int width = (int)bounds.size.width;
        int height = (int)bounds.size.height;
        [cliInfo appendFormat:@"&%d,%d", width, height];
        self.cliInfo = [cliInfo copy];
        if (enabledSecurity) {
            [self.manager setSecurityPolicy:[self customSecurityPolicy]];
        }
    }
    
    return self;
}

- (void)registerQueryStringSerializationWithBlock {
    __weak PWAPIController *weakSelf = self;
    [self.requestFormSerializer setQueryStringSerializationWithBlock:^NSString * _Nonnull(NSURLRequest * _Nonnull request, id  _Nonnull parameters, NSError * _Nullable __autoreleasing * _Nullable error) { @autoreleasepool {
        __strong PWAPIController *strongSelf = weakSelf;
        NSString *query = @"";
        NSString *sign = @"";
        if ([parameters isKindOfClass:[NSDictionary class]] && parameters) {
            
            if (((NSDictionary *)parameters).count > 0) {
                query = AFQueryStringFromParameters(parameters);
                query = [query stringByAppendingString:@"&"];
                NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"description" ascending:YES selector:@selector(compare:)];
                NSDictionary *dictionary = parameters;
                for (id nestedKey in [dictionary.allKeys sortedArrayUsingDescriptors:@[ sortDescriptor ]]) {
                    id nestedValue = dictionary[nestedKey];
                    sign = [sign stringByAppendingFormat:@"%@",nestedValue];
                }
            }
        }
    
        NSDate *date = [NSDate dateWithTimeIntervalSinceNow:0];
        NSTimeInterval time = [date timeIntervalSince1970];
        NSString *timeString = [NSString stringWithFormat:@"%.0f", time];
        sign = [sign stringByAppendingFormat:@"%@%@",timeString,strongSelf.toKen ? strongSelf.toKen : @""];
        NSString *signMd5 = [sign md5String];
        query = [query stringByAppendingFormat:@"timestamp=%@&sign=%@",timeString,signMd5];
//        NSLog(@"query = %@",query);
        return query;
        }
    }];
}

- (void)sendRequest:(NSURLRequest *)request
            success:(void (^)(NSString *message, id data))success
              error:(void (^)(NSString *message, int code))error
            failure:(void (^)(NSError *error))failure {
    
    NSURLSessionDataTask *dataTask = [self dataTaskWithRequest:request success:success error:error failure:failure];

    [dataTask resume];
}

- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request
                                      success:(void (^)(NSString *message, id data))success
                                        error:(void (^)(NSString *message, int code))error
                                      failure:(void (^)(NSError *error))failure {
    
    __weak PWAPIController *weakSelf = self;
    NSURLSessionDataTask *dataTask = [self.manager dataTaskWithRequest:request uploadProgress:nil downloadProgress:nil completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable err) {
        __strong PWAPIController *strongSelf = weakSelf;
        if (err) {
            NSLog(@"%@, 请求failure %@",response.URL,err);
            dispatch_async(dispatch_get_main_queue(), ^{
                failure(err);
            });
        } else {
            int code = ((NSNumber *)responseObject[@"code"]).intValue;
            NSString *message = responseObject[@"message"];
            if (code == 200) {
                id data = responseObject[@"data"];
                dispatch_async(dispatch_get_main_queue(), ^{
                    success(message, data);
                });
            } else {
                NSLog(@"%@, 请求error %@",response.URL,responseObject);
                if (code == 40006) {
                    [strongSelf sendRequestDataTokenNoAvailNotification];
                }else {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        error(message, code);
                    });
                }
            }
        }
    }];

    return dataTask;
}

- (void)sendRequestWillRedirect:(NSURLRequest *)request
                        redirect:(void (^)(NSString *url))redirect {
    
    __weak PWAPIController *weakSelf = self;
    [self.manager setTaskWillPerformHTTPRedirectionBlock:^NSURLRequest * _Nonnull(NSURLSession * _Nonnull session, NSURLSessionTask * _Nonnull task, NSURLResponse * _Nonnull response, NSURLRequest * _Nonnull request) {
        __strong PWAPIController *strongSelf = weakSelf;
        redirect(request.URL.absoluteString);
        [strongSelf.manager setTaskWillPerformHTTPRedirectionBlock:nil];
        return nil;
    }];
    [[self.manager dataTaskWithRequest:request uploadProgress:nil downloadProgress:nil completionHandler:nil] resume];
}

- (NSMutableURLRequest *)requestWithMethod:(NSString *)method
                                 URLString:(NSString *)URLString
                                parameters:(id)parameters {
    
    NSError *error = nil;
    NSString *urlString = [[NSURL URLWithString:URLString relativeToURL:[NSURL URLWithString:self.baseURL]] absoluteString];
    /*&* EnabledMD5Sign 无参数不能传nil*/
    id parame;
    if (self.isEnabledMD5Sign) {
        parame = parameters ? parameters : @{};
    }else {
        parame = parameters;
    }
    NSMutableURLRequest *request = [self.requestFormSerializer requestWithMethod:method URLString:urlString parameters:parame error:&error];
//    NSLog(@"request urlString = %@",urlString);
    request.timeoutInterval = 30;
    if (error) {
        NSAssert(NO, @"!!! Error: http request serialization error !!!\n%@\n", [error localizedDescription]);
    }
    [request setValue:self.cliInfo forHTTPHeaderField:@"CLI_INFO"];
    if (self.toKen.length > 0 && self.toKen) {
        [request setValue:self.toKen forHTTPHeaderField:@"x_access_token"];
    }
    
    return request;
}

- (NSMutableURLRequest *)requestJsonWithMethod:(NSString *)method
                                     URLString:(NSString *)URLString
                                    parameters:(id)parameters {
    
    NSError *error = nil;
    NSString *urlString = [[NSURL URLWithString:URLString relativeToURL:[NSURL URLWithString:self.baseURL]] absoluteString];
    if (self.isEnabledMD5Sign) {
        NSString *sign = @"";
        NSDate *date = [NSDate dateWithTimeIntervalSinceNow:0];
        NSTimeInterval time = [date timeIntervalSince1970];
        NSString *timeString = [NSString stringWithFormat:@"%.0f", time];
        
        NSError *jsonError;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:parameters
                                                           options:0
                                                             error:&jsonError];
        NSString *jsonString = @"";
        if (jsonError) {
             NSAssert(NO, @"!!! Error: jsonString serialization error !!!\n%@\n", [jsonError localizedDescription]);
        }else {
            jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        }
        jsonString = [jsonString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        [jsonString stringByReplacingOccurrencesOfString:@"\n" withString:@""];
        sign = [NSString stringWithFormat:@"%@%@%@",jsonString,timeString,self.toKen];
        
        NSString *signMd5 = [sign md5String];
        urlString = [urlString stringByAppendingFormat:@"?timestamp=%@&sign=%@",timeString,signMd5];
    }
    NSMutableURLRequest *request = [self.requestJsonSerializer requestWithMethod:method URLString:urlString parameters:parameters error:&error];
//    NSLog(@"request urlString = %@",urlString);
    request.timeoutInterval = 30;
    if (error) {
        NSAssert(NO, @"!!! Error: http request serialization error !!!\n%@\n", [error localizedDescription]);
    }
    [request setValue:self.cliInfo forHTTPHeaderField:@"CLI_INFO"];
    if (self.toKen.length > 0 && self.toKen) {
        [request setValue:self.toKen forHTTPHeaderField:@"x_access_token"];
    }
    
    return request;
}

- (void)requestJsonDataWithPath:(NSString *)aPath
                     withParams:(NSDictionary *)params
                 withMethodType:(NetworkMethod)method
                     andSuccess:(void (^)(NSString *message, id data))success
                       andError:(void (^)(NSString *message, int code))error
                     andFailure:(void (^)(NSError *error))failure {
    
    [self requestJsonDataWithPath:aPath withParams:params withMethodType:method withEnabledSign:YES andSuccess:success andError:error andFailure:failure];
}

- (void)requestJsonDataWithPath:(NSString *)aPath
                     withParams:(NSDictionary *)params
                 withMethodType:(NetworkMethod)method
                withEnabledSign:(BOOL)enabledSign
                     andSuccess:(void (^)(NSString *message, id data))success
                       andError:(void (^)(NSString *message, int code))error
                     andFailure:(void (^)(NSError *error))failure {
    
    self.enabledMD5Sign = enabledSign;
    NSString *networkmethod;
    switch (method) {
        case Get:{
            networkmethod = @"GET";
        }
            break;
        case Post:{
            networkmethod = @"POST";
        }
            break;
        default:
            break;
    }
    NSMutableURLRequest *requeset = [self requestWithMethod:networkmethod URLString:aPath parameters:params];
    [self sendRequest:requeset success:success error:error failure:failure];
}

- (NSURLSessionDataTask *)dataTaskRequestJsonDataWithPath:(NSString *)aPath
                                               withParams:(NSDictionary *)params
                                           withMethodType:(NetworkMethod)method
                                               andSuccess:(void (^)(NSString *message, id data))success
                                                 andError:(void (^)(NSString *message, int code))error
                                               andFailure:(void (^)(NSError *error))failure {
    
    NSString *networkmethod;
    switch (method) {
        case Get:{
            networkmethod = @"GET";
        }
            break;
        case Post:{
            networkmethod = @"POST";
        }
            break;
        default:
            break;
    }
    NSMutableURLRequest *requeset = [self requestWithMethod:networkmethod URLString:aPath parameters:params];
    NSURLSessionDataTask *dataTask = [self dataTaskWithRequest:requeset success:success error:error failure:failure];
    
    [dataTask resume];
    
    return dataTask;
}

- (void)requestJsonDataWithPath:(NSString *)aPath
                     withParams:(NSDictionary *)params
                 withMethodType:(NetworkMethod)method
              andTaskIdentifier:(void (^)(NSInteger taskIdentifier))taskIdentifier
                     andSuccess:(void (^)(NSString *message, id data))success
                       andError:(void (^)(NSString *message, int code))error
                     andFailure:(void (^)(NSError *error))failure {
    
    NSString *networkmethod;
    switch (method) {
        case Get:{
            networkmethod = @"GET";
        }
            break;
        case Post:{
            networkmethod = @"POST";
        }
            break;
        default:
            break;
    }
    NSMutableURLRequest *requeset = [self requestWithMethod:networkmethod URLString:aPath parameters:params];
    
    NSURLSessionDataTask *dataTask = [self dataTaskWithRequest:requeset success:success error:error failure:failure];
    
    [dataTask resume];
    if (taskIdentifier) {
        taskIdentifier(dataTask.taskIdentifier);
    }
}

- (void)requestBodyJsonDataWithPath:(NSString *)aPath
                         withParams:(NSDictionary *)params
                     withMethodType:(NetworkMethod)method
                         andSuccess:(void (^)(NSString *message, id data))success
                           andError:(void (^)(NSString *message, int code))error
                         andFailure:(void (^)(NSError *error))failure {
    
    [self requestBodyJsonDataWithPath:aPath withParams:params withMethodType:method withEnabledSign:NO andSuccess:success andError:error andFailure:failure];
}

- (void)requestBodyJsonDataWithPath:(NSString *)aPath
                         withParams:(NSDictionary *)params
                     withMethodType:(NetworkMethod)method
                    withEnabledSign:(BOOL)enabledSign
                         andSuccess:(void (^)(NSString *message, id data))success
                           andError:(void (^)(NSString *message, int code))error
                         andFailure:(void (^)(NSError *error))failure {
    
    self.enabledMD5Sign = enabledSign;
    NSString *networkmethod;
    switch (method) {
        case Get:{
            networkmethod = @"GET";
        }
            break;
        case Post:{
            networkmethod = @"POST";
        }
            break;
        default:
            break;
    }
    
    NSMutableURLRequest *requeset = [self requestJsonWithMethod:networkmethod URLString:aPath parameters:params];
    [self sendRequest:requeset success:success error:error failure:failure];
}


- (void)downloadFileWithPath:(NSString *)aPath
                  withParams:(NSDictionary *)params
            downloadProgress:(void (^)(NSProgress *downloadProgress))downloadProgressBlock
             downloadSuccess:(void (^)(NSURLResponse *response, NSURL *filePath))downloadSuccessBlock
             downloadFailure:(void (^)(NSError *error))downloadFailureBlock {
    
    NSURLSessionDownloadTask *task =
    [self.manager downloadTaskWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:aPath]] progress:^(NSProgress * _Nonnull downloadProgress) {
        downloadProgressBlock(downloadProgress);
    } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        
        NSString *cachesPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
        NSString *path = [cachesPath stringByAppendingPathComponent:response.suggestedFilename];
        return [NSURL fileURLWithPath:path];
        
    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        if (!error) {
            downloadSuccessBlock(response,filePath);
        }else{
            downloadFailureBlock(error);
        }
    }];
    
    [task resume];
}

@end
