//
//  SLAFBaseManager.m
//  Pods
//
//  Created by sunbeam on 2016/12/21.
//
//

#import "SLAFBaseManager.h"
#import "SLAFServiceContext.h"
#import "SLAFServiceProperty.h"
#import "SLAFHTTPClient.h"

#define SLAF_REQUEST_ID_DEFAULT @(0)

@interface SLAFBaseManager()

@end

@implementation SLAFBaseManager

- (instancetype)init
{
    if (self = [super init]) {
        if ([self conformsToProtocol:@protocol(SLAFManagerProtocol)]) {
            _childManager = (id<SLAFManagerProtocol>) self;
        } else {
            NSLog(@"%@不符合SLAFManagerProtocol", self);
        }
        _requestParams = nil;
        _requestParamsValidator = nil;
        _requestInterceptor = nil;
        _responseDataFormatter = nil;
        _responseDataValidator = nil;
    }
    
    return self;
}

- (void)dealloc
{
    //[[SLAFHTTPSessionManager sharedSLAFHTTPSessionManager] cancelAllRequest];
}

- (NSNumber *) loadDataTask:(void(^)(NSString* identifier, id responseObject, NSError* error)) completion
{
    NSError* error = [self beforeRequest];
    if (error != nil) {
        completion(self.childManager.identifier, nil, error);
        
        return SLAF_REQUEST_ID_DEFAULT;
    }
    
    NSDictionary* params = nil;
    if (self.requestParams && [self.requestParams respondsToSelector:@selector(generatorRequestParams)]) {
        params = [self.requestParams generatorRequestParams];
    }
    
    __weak __typeof__(self) weakSelf = self;
    if (self.childManager.method == GET || self.childManager.method == POST) {
        // get请求、post请求
        return [[[SLAFHTTPClient alloc] init] loadDataTask:self.childManager.URI identifier:self.childManager.identifier method:self.childManager.method params:params completion:^(SLAFResponse *response) {
            __strong __typeof__(weakSelf) strongSelf = weakSelf;
            if (response.error == nil) {
                id jsonData = [strongSelf formatResponseData:response.responseObject];
                NSLog(@"\nhttps GET/POST请求响应格式化后数据：%@\n<<<end==========================================https GET/POST请求序号:%@", jsonData, response.requestId);
                if (self.responseDataValidator && [self.responseDataValidator respondsToSelector:@selector(responseDataValidate:)]) {
                    NSError* error = [self.responseDataValidator responseDataValidate:jsonData];
                    if (error != nil) {
                        completion(strongSelf.childManager.identifier, nil, error);
                        if (strongSelf.requestInterceptor && [strongSelf.requestInterceptor respondsToSelector:@selector(interceptorForRequestFailed)]) {
                            [strongSelf.requestInterceptor interceptorForRequestFailed];
                        }
                        
                        return ;
                    }
                }
                completion(strongSelf.childManager.identifier, jsonData, nil);
                if (strongSelf.requestInterceptor && [strongSelf.requestInterceptor respondsToSelector:@selector(interceptorForRequestSuccess)]) {
                    [strongSelf.requestInterceptor interceptorForRequestSuccess];
                }
            } else {
                completion(strongSelf.childManager.identifier, nil, response.error);
                if (strongSelf.requestInterceptor && [strongSelf.requestInterceptor respondsToSelector:@selector(interceptorForRequestFailed)]) {
                    [strongSelf.requestInterceptor interceptorForRequestFailed];
                }
            }
        }];
    } else {
        completion(self.childManager.identifier, nil, [NSError errorWithDomain:SLAF_ERROR_DOMAIN code:REQUEST_METHOD_NOT_SUPPORT userInfo:@{NSLocalizedDescriptionKey:@"request method not support"}]);
        
        return SLAF_REQUEST_ID_DEFAULT;
    }
}

- (NSNumber *) loadUploadTask:(NSMutableDictionary *) uploadFiles uploadProgressBlock:(void (^)(NSProgress *uploadProgress)) uploadProgressBlock completion:(void(^)(NSString* identfier, id responseObject, NSError* error)) completion
{
    NSError* error = [self beforeRequest];
    if (error != nil) {
        completion(self.childManager.identifier, nil, error);
        
        return SLAF_REQUEST_ID_DEFAULT;
    }
    
    NSDictionary* params = nil;
    if (self.requestParams && [self.requestParams respondsToSelector:@selector(generatorRequestParams)]) {
        params = [self.requestParams generatorRequestParams];
    }
    
    __weak __typeof__(self) weakSelf = self;
    if (self.childManager.method == UPLOAD) {
        return [[[SLAFHTTPClient alloc] init] loadUploadTask:self.childManager.URI identifier:self.childManager.identifier method:self.childManager.method params:params uploadFiles:uploadFiles uploadProgressBlock:uploadProgressBlock completion:^(SLAFResponse *response) {
            __strong __typeof__(weakSelf) strongSelf = weakSelf;
            if (response.error == nil) {
                id jsonData = [strongSelf formatResponseData:response.responseObject];
                if (self.responseDataValidator && [self.responseDataValidator respondsToSelector:@selector(responseDataValidate:)]) {
                    NSError* error = [self.responseDataValidator responseDataValidate:jsonData];
                    if (error != nil) {
                        completion(strongSelf.childManager.identifier, nil, error);
                        if (strongSelf.requestInterceptor && [strongSelf.requestInterceptor respondsToSelector:@selector(interceptorForRequestFailed)]) {
                            [strongSelf.requestInterceptor interceptorForRequestFailed];
                        }
                        
                        return ;
                    }
                }
                completion(strongSelf.childManager.identifier, jsonData, nil);
                if (strongSelf.requestInterceptor && [strongSelf.requestInterceptor respondsToSelector:@selector(interceptorForRequestSuccess)]) {
                    [strongSelf.requestInterceptor interceptorForRequestSuccess];
                }
            } else {
                completion(strongSelf.childManager.identifier, nil, response.error);
                if (strongSelf.requestInterceptor && [strongSelf.requestInterceptor respondsToSelector:@selector(interceptorForRequestFailed)]) {
                    [strongSelf.requestInterceptor interceptorForRequestFailed];
                }
            }
        }];
    } else {
        completion(self.childManager.identifier, nil, [NSError errorWithDomain:SLAF_ERROR_DOMAIN code:REQUEST_METHOD_NOT_SUPPORT userInfo:@{NSLocalizedDescriptionKey:@"request method not support"}]);
        
        return SLAF_REQUEST_ID_DEFAULT;
    }
}

- (NSNumber *) loadDownloadTask:(NSString *) downloadUrl downloadProgressBlock:(void (^)(NSProgress *uploadProgress)) downloadProgressBlock completion:(void(^)(NSString* identfier, NSURL* downloadFileurl, NSError* error)) completion
{
    NSError* error = [self beforeRequest];
    if (error != nil) {
        completion(self.childManager.identifier, nil, error);
        
        return SLAF_REQUEST_ID_DEFAULT;
    }
    
    NSDictionary* params = nil;
    if (self.requestParams && [self.requestParams respondsToSelector:@selector(generatorRequestParams)]) {
        params = [self.requestParams generatorRequestParams];
    }
    
    __weak __typeof__(self) weakSelf = self;
    if (self.childManager.method == DOWNLOAD) {
        return [[[SLAFHTTPClient alloc] init] loadDownloadTask:self.childManager.URI identifier:self.childManager.identifier method:self.childManager.method params:params downloadUrl:downloadUrl downloadProgressBlock:downloadProgressBlock completion:^(SLAFResponse *response) {
            __strong __typeof__(weakSelf) strongSelf = weakSelf;
            if (response.error == nil) {
                completion(strongSelf.childManager.identifier, response.downloadFileUrl, nil);
                if (strongSelf.requestInterceptor && [strongSelf.requestInterceptor respondsToSelector:@selector(interceptorForRequestSuccess)]) {
                    [strongSelf.requestInterceptor interceptorForRequestSuccess];
                }
            } else {
                completion(strongSelf.childManager.identifier, nil, response.error);
                if (strongSelf.requestInterceptor && [strongSelf.requestInterceptor respondsToSelector:@selector(interceptorForRequestFailed)]) {
                    [strongSelf.requestInterceptor interceptorForRequestFailed];
                }
            }
        }];
    } else {
        completion(self.childManager.identifier, nil, [NSError errorWithDomain:SLAF_ERROR_DOMAIN code:REQUEST_METHOD_NOT_SUPPORT userInfo:@{NSLocalizedDescriptionKey:@"request method not support"}]);
        
        return SLAF_REQUEST_ID_DEFAULT;
    }
}

#pragma mark - private method
/**
 检测网络参数等

 @return NSError
 */
- (NSError *) beforeRequest
{
    // 判断网络是否正常
    if (![[SLAFServiceContext sharedSLAFServiceContext] networkIsReachable])
    {
        return [NSError errorWithDomain:SLAF_ERROR_DOMAIN code:NETWORK_NOT_REACHABLE_ERROR userInfo:@{NSLocalizedDescriptionKey:@"network is not reachable"}];
    }
    
    // 判断当前是否有网络请求正在执行(取决于是否支持多个请求同时执行)
    if ([[SLAFHTTPSessionManager sharedSLAFHTTPSessionManager] requestIsRunning])
    {
        if ([SLAFServiceContext sharedSLAFServiceContext].requestRunningStrategy == RUNNING_FIRST_IN) {
            // 该处采取的策略是阻止新的请求，执行旧的请求
            return [NSError errorWithDomain:SLAF_ERROR_DOMAIN code:REQUEST_RUNING_ERROR userInfo:@{NSLocalizedDescriptionKey:@"network request is busy"}];
        } else if ([SLAFServiceContext sharedSLAFServiceContext].requestRunningStrategy == RUNNING_LAST_IN) {
            // 该处采取的策略是取消旧的请求，执行新的请求
            [[SLAFHTTPSessionManager sharedSLAFHTTPSessionManager] cancelAllRequest];
        }
    }
    
    // 判断网络请求参数是否合法，错误会返回NSError（由外部判断后返回）
    if (self.requestParamsValidator && [self.requestParamsValidator respondsToSelector:@selector(requestParamsValidator)]) {
        return [self.requestParamsValidator requestParamsValidate];
    }
    
    return nil;
}

/**
 格式化响应数据

 @param formatter 格式化方法
 @return json
 */
- (id) formatResponseData:(id) responseObject
{
    // 如果formatter不为空，则默认外部进行格式化处理
    if (self.responseDataFormatter && [self.responseDataFormatter respondsToSelector:@selector(responseDataFormat:)]) {
        return [self.responseDataFormatter responseDataFormat:responseObject];
    }
    
    if (responseObject == nil || [responseObject length] == 0) {
        return nil;
    }
    
    NSError* error = nil;
    id returnDictionary = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingAllowFragments error:&error];
    if (error) {
        NSLog(@"\n网络请求数据NSJSONReadingAllowFragments格式化失败：%@", error);
        return nil;
    }
    
    return returnDictionary;
}

@end
