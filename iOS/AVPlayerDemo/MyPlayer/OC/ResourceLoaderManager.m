//
//  ResourceLoaderManager.m
//  LSPlayer
//
//  Created by mustard on 2017/7/28.
//  Copyright © 2017年 song. All rights reserved.
//

#import "ResourceLoaderManager.h"
#import <CommonCrypto/CommonDigest.h>
#import <MobileCoreServices/MobileCoreServices.h>

@interface ResourceLoaderManager ()<VideoRequestDelegate>

@property (nonatomic, strong, nullable)NSMutableArray *pendingRequests;
@property (nonatomic, copy) NSString *videoPath;
// 标记缓存加载状态(默认YES)
@property (nonatomic, assign) BOOL isLoading;
// 视频id(非必须)
@property (nonatomic, copy) NSString *video_id;
//  當前下載進度
@property (nonatomic) double currentProgress;

@property (nonatomic, copy) NSString *scheme;
@end

@implementation ResourceLoaderManager

- (instancetype)init
{
    if (self = [super init]) {
        _isLoading = YES;
        _currentProgress = 0;
        _pendingRequests = [[NSMutableArray alloc] initWithCapacity:0];
    }
    return self;
}

+ (BOOL)saveAVAssetToLocale:(AVAsset *)asset saveName:(NSString *)name
{
    NSString *savePath = [[VideoRequest getFileSavePath] stringByAppendingPathComponent:name];
    NSURL *fileUrl = [NSURL fileURLWithPath:savePath];
    if (asset != nil) {
        AVMutableComposition *mixComposition = [[AVMutableComposition alloc]init];
        // 视频轨道
        AVMutableCompositionTrack *firstTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        [firstTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration) ofTrack:[[asset tracksWithMediaType:AVMediaTypeVideo]objectAtIndex:0] atTime:kCMTimeZero error:nil];
        // 音频轨道
        AVMutableCompositionTrack *audioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
        [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration) ofTrack:[[asset tracksWithMediaType:AVMediaTypeAudio]objectAtIndex:0] atTime:kCMTimeZero error:nil];
        
        AVAssetExportSession *exporter = [[AVAssetExportSession alloc]initWithAsset:mixComposition presetName:AVAssetExportPresetHighestQuality];
        exporter.outputURL = fileUrl;
        if (exporter.supportedFileTypes) {
            exporter.outputFileType = [exporter.supportedFileTypes objectAtIndex:0] ;
            exporter.shouldOptimizeForNetworkUse = YES;
            [exporter exportAsynchronouslyWithCompletionHandler:^{
                NSLog(@"音视频轨道合成。。。");
            }];
        }
    }
    return NO;
}

- (NSURL *)getSchemeVideoURL:(NSURL *)url VideoID:(NSString *)video_id
{
    self.video_id = video_id;
    
    NSURLComponents *com = [[NSURLComponents alloc] initWithURL:url resolvingAgainstBaseURL:NO];
    self.scheme = com.scheme;
    com.scheme = kCustomVideoScheme;
    
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).lastObject stringByAppendingString:append_temp];
    NSString *fname = [VideoRequest getVideoCacheFileNameWithURL:url VideoID:video_id];
    path = [path stringByAppendingPathComponent:fname];
    self.videoPath = path;
    
    return [com URL];
}


#pragma mark - Delegate : AVAssetResourceLoaderDelegate
// 取消加载
- (void)resourceLoader:(AVAssetResourceLoader *)resourceLoader didCancelLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest
{
    if(resourceLoader && loadingRequest) {
        [_pendingRequests removeObject:loadingRequest];
    }
}

/**
 *  必须返回Yes，如果返回NO，则resourceLoader将会加载出现故障的数据
 *  这里会出现很多个loadingRequest请求， 需要为每一次请求作出处理
 *  @param resourceLoader 资源管理器
 *  @param loadingRequest 每一小块数据的请求
 *
 */
- (BOOL)resourceLoader:(AVAssetResourceLoader *)resourceLoader shouldWaitForLoadingOfRequestedResource:(AVAssetResourceLoadingRequest *)loadingRequest
{
    if(resourceLoader && loadingRequest) {
        [_pendingRequests addObject:loadingRequest];
        
        [self dealWithLoadingRequest:loadingRequest];
    }
    
    return YES;
}

- (void)dealWithLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest
{
    NSURL *interceptedURL = [loadingRequest.request URL];
    
    if (_vRequest) {
        if (_vRequest.downLoadingOffset > 0) {
            [self processPendingRequests];
        }
    }
    else {
        /// 第一次请求数据
        _vRequest = [[VideoRequest alloc] init];
        _vRequest.scheme = self.scheme;
        _vRequest.delegate = self;
        [_vRequest setUrl:interceptedURL VideoID:self.video_id Offset:0];
    }
}

/// 取消某段range的数据请求
- (void)cancelCurrentLoading
{
    _isLoading = NO;
    [_vRequest cancel];
}
/// 继续请求数据
- (void)continueCurrentLoading
{
    _isLoading = YES;
    [_vRequest continueLoading];
}

#pragma mark - 请求、缓存
- (void)fillInContentInformation:(AVAssetResourceLoadingContentInformationRequest *)contentInformationRequest
{
    NSString *mimeType = self.vRequest.mimeType;
    CFStringRef contentType = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, (__bridge CFStringRef)(mimeType), NULL);
    contentInformationRequest.byteRangeAccessSupported = YES;
    contentInformationRequest.contentType = CFBridgingRelease(contentType);
    contentInformationRequest.contentLength = self.vRequest.videoLength;
}

- (void)processPendingRequests
{
    NSMutableArray *requestsCompleted = [NSMutableArray array];  //请求完成的数组
    //每次下载一块数据都是一次请求，把这些请求放到数组，遍历数组
    for (AVAssetResourceLoadingRequest *loadingRequest in self.pendingRequests)
    {
        [self fillInContentInformation:loadingRequest.contentInformationRequest]; //对每次请求加上长度，文件类型等信息
        
        @try {
            
            BOOL didRespondCompletely = [self respondWithDataForRequest:loadingRequest.dataRequest]; //判断此次请求的数据是否处理完全
            
            if (didRespondCompletely) {
                
                [requestsCompleted addObject:loadingRequest];  //如果完整，把此次请求放进 请求完成的数组
                [loadingRequest finishLoading];
                
            }
        } @catch (NSException *exception) {
            NSLog(@"[ResourceLoaderManager error]: %@", exception);
        } @finally {}
        
    }
    
    [self.pendingRequests removeObjectsInArray:requestsCompleted];   //在所有请求的数组中移除已经完成的
    
}


- (BOOL)respondWithDataForRequest:(AVAssetResourceLoadingDataRequest *)dataRequest
{
    long long startOffset = dataRequest.requestedOffset;
    
    if (dataRequest.currentOffset != 0) {
        startOffset = dataRequest.currentOffset;
    }
    
    if ((self.vRequest.offset +self.vRequest.downLoadingOffset) < startOffset) {
        return NO;
    }
    
    if (startOffset < self.vRequest.offset) {
        return NO;
    }
    
    NSData *filedata = [NSData dataWithContentsOfURL:[NSURL fileURLWithPath:_videoPath] options:NSDataReadingMappedIfSafe error:nil];
    
    // This is the total data we have from startOffset to whatever has been downloaded so far
    NSUInteger unreadBytes = self.vRequest.downLoadingOffset - ((NSInteger)startOffset - self.vRequest.offset);

    // Respond with whatever is available if we can't satisfy the request fully yet
    NSUInteger numberOfBytesToRespondWith = MIN((NSUInteger)dataRequest.requestedLength, unreadBytes);
    
    [dataRequest respondWithData:[filedata subdataWithRange:NSMakeRange((NSUInteger)startOffset- self.vRequest.offset, (NSUInteger)numberOfBytesToRespondWith)]];
    
    
    
    long long endOffset = startOffset + dataRequest.requestedLength;
    BOOL didRespondFully = (self.vRequest.offset + self.vRequest.downLoadingOffset) >= endOffset;
    
    return didRespondFully;
}


#pragma mark - Delegate : VideoRequestDelegate
- (void)request:(VideoRequest *)vRequest didReceiveVideoLength:(NSUInteger)ideoLength mimeType:(NSString *)mimeType
{
}

/// 数据下载完成且成功
- (void)didFinishLoadingWithRequest:(VideoRequest *)vRequest
{
    if(_delegate && [_delegate respondsToSelector:@selector(didFinishLoadingWithRequest:)]) {
        [_delegate didFinishLoadingWithRequest:vRequest];
    }
}

/// 接收某一段资源数据
- (void)didReceiveVideoDataWithRequest:(VideoRequest *)vRequest
{
    [self processPendingRequests];
    
    // 计算当前下载进度
    double p = (double)vRequest.downLoadingOffset/(double)vRequest.videoLength;
    if (p - self.currentProgress < 0.01) {
        return;
    }
    
    self.currentProgress = p;
    
    if (_delegate && [_delegate respondsToSelector:@selector(getResourceDownloadProgress:)]) {
        // 代理传递下载进度
        [_delegate getResourceDownloadProgress:self.currentProgress];
    }
    
}

/// 下载失败
- (void)didFailLoadingWithRequest:(VideoRequest *)vRequest WithError:(NSInteger)errorCode
{
    if(_delegate && [_delegate respondsToSelector:@selector(didFailLoadingWithRequest:WithError:)]) {
        [_delegate didFailLoadingWithRequest:vRequest WithError:errorCode];
    }
}
@end



#pragma mark - 网络资源请求类
@interface VideoRequest ()< AVAssetResourceLoaderDelegate, NSURLSessionDataDelegate>
// 请求链接
@property (nonatomic, strong) NSURL           *url;
@property (nonatomic, assign) NSUInteger      offset;
// 资源长度(eg:视频总长)
@property (nonatomic, assign) NSUInteger      videoLength;
@property (nonatomic, strong) NSString        *mimeType;

@property (nonatomic, strong) NSURLSession *session;
// 每次请求的长度
@property (nonatomic, assign) NSUInteger      downLoadingOffset;
// 请求连接是否一次
@property (nonatomic, assign) BOOL            once;
// 文件处理
@property (nonatomic, strong) NSFileHandle    *fileHandle;
// 临时路径
@property (nonatomic, strong) NSString        *tempPath;
// 文件名字(cache)
@property (nonatomic, copy) NSString *videoFileName;
@end

@implementation VideoRequest

- (instancetype)init
{
    if (self = [super init]) {
    }
    return self;
}

#pragma mark - Public methods
/// 设置网络请求
- (void)setUrl:(NSURL *)url VideoID:(NSString *)video_id Offset:(NSUInteger)offset
{
    _url = url;
    _offset = offset;
    _videoFileName = [VideoRequest getVideoCacheFileNameWithURL:_url VideoID:video_id];
    
    _downLoadingOffset = 0;
    
    NSURLComponents *actualURLComponents = [[NSURLComponents alloc] initWithURL:url resolvingAgainstBaseURL:NO];
    actualURLComponents.scheme = self.scheme;
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[actualURLComponents URL] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:20.0];
    
    if (offset > 0 && self.videoLength > 0) {
        [request addValue:[NSString stringWithFormat:@"bytes=%ld-%ld",(unsigned long)offset, (unsigned long)self.videoLength - 1] forHTTPHeaderField:@"Range"];
    }
    
    /// session 设置
    [self.session invalidateAndCancel];
    self.session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    
    /// 任务设置
    NSURLSessionDataTask *dataTask = [_session dataTaskWithRequest:request];
    [dataTask resume];
}

/// 取消当前请求
- (void)cancel
{
    [self.session invalidateAndCancel];
}

// 继续上次中断的请求
- (void)continueLoading
{
    _once = YES;
    NSURLComponents *actualURLComponents = [[NSURLComponents alloc] initWithURL:_url resolvingAgainstBaseURL:NO];
    actualURLComponents.scheme = self.scheme;
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[actualURLComponents URL] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:20.0];// 超过20s认为请求超时
    
    [request addValue:[NSString stringWithFormat:@"bytes=%ld-%ld",(unsigned long)_downLoadingOffset, (unsigned long)self.videoLength - 1] forHTTPHeaderField:@"Range"];
    
    /// 重新设置sesion
    [self.session invalidateAndCancel];
    self.session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    
    /// 重新设置任务
    NSURLSessionDataTask *dataTask = [_session dataTaskWithRequest:request];
    [dataTask resume];
}

/// 清理数据
- (void)clearData
{
    [self.session invalidateAndCancel];
    
    // 移除临时文件
    [[NSFileManager defaultManager] removeItemAtPath:_tempPath error:nil];
}


#pragma mark - NSURLSession delegate
// 1.接收到服务器的响应
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler
{
    // 拼接临时缓存路径
    self.tempPath = [self setupTempPath];
    
    _isFinishLoad = NO;
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
    
    NSDictionary *dic = (NSDictionary *)[httpResponse allHeaderFields] ;
    
    NSString *content = [dic valueForKey:@"Content-Range"];
    NSArray *array = [content componentsSeparatedByString:@"/"];
    NSString *length = array.lastObject;
    
    NSUInteger videoLength;
    
    if ([length integerValue] == 0) {
        videoLength = (NSUInteger)httpResponse.expectedContentLength;
    } else {
        videoLength = [length integerValue];
    }
    
    self.videoLength = videoLength;
    //    self.mimeType = @"video/mp4";
    self.mimeType = [NSString stringWithFormat:@"video/%@", [self.videoFileName componentsSeparatedByString:@"."][1]];
    
    if ([self.delegate respondsToSelector:@selector(request:didReceiveVideoLength:mimeType:)]) {
        [_delegate request:self didReceiveVideoLength:_videoLength mimeType:_mimeType];
    }
    
    self.fileHandle = [NSFileHandle fileHandleForWritingAtPath:_tempPath];
    
    // 允许处理服务器的响应，才会继续接收服务器返回的数据
    completionHandler(NSURLSessionResponseAllow);
}

// 2.接收到服务器的数据（可能调用多次）
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
        if(data.length > 0) {
        // 处理每次接收的数据
        [self.fileHandle seekToEndOfFile];
        
        [self.fileHandle writeData:data];
        
        _downLoadingOffset += data.length;
        
        if ([self.delegate respondsToSelector:@selector(didReceiveVideoDataWithRequest:)]) {
            [self.delegate didReceiveVideoDataWithRequest:self];
        }
    }
}

// 3.请求成功或者失败（如果失败，error有值）
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    // 请求完成,成功或者失败的处理
    if (!error) {
        _isFinishLoad = YES;
        
        if(![[NSFileManager defaultManager] fileExistsAtPath:self.tempPath]) {
            return;
        }
        
        NSString *savePath = [VideoRequest getFileSavePath];
        savePath = [savePath stringByAppendingPathComponent:self.videoFileName];
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            // 异步保存文件到沙盒
            BOOL isSuccess = [[NSFileManager defaultManager] moveItemAtPath:self.tempPath toPath:savePath error:nil];
            if(isSuccess) {
//                NSLog(@"文件保存成功");
                // 完整资源数据保存后 清空临时数据
                [self clearData];
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([self.delegate respondsToSelector:@selector(didFinishLoadingWithRequest:)]) {
                    [self.delegate didFinishLoadingWithRequest:self];
                }
            });
        });
    }
    /// 下载失败
    else {
        if (error.code == -1001 && !_once) {
            // 网络超时，重连一次
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self continueLoading];
            });
        }
        if ([self.delegate respondsToSelector:@selector(didFailLoadingWithRequest:WithError:)]) {
            [self.delegate didFailLoadingWithRequest:self WithError:error.code];
        }
        if (error.code == -1009) {
            //        NSLog(@"无网络连接");
        }
    }
}



#pragma mark Private
/// md5加密的文件名
+ (NSString *)getFileNameWithURL:(NSString *)url {
    const char *cStr = [url UTF8String];
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5( cStr, (unsigned)strlen(cStr), digest );
    
    NSMutableString *md5 = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [md5 appendFormat:@"%02x", digest[i]];
    }
    
    return [NSString stringWithFormat:@"%@.%@",md5,[url pathExtension]];
}
/// 设置临时缓存路径
- (NSString *)setupTempPath
{
    NSString *path = [VideoRequest getFileTempCachePath];
    path = [path stringByAppendingPathComponent:self.videoFileName];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:path] && !self.once) {
        [fileManager removeItemAtPath:path error:nil];
    }
    [fileManager createFileAtPath:path contents:nil attributes:nil];
    
    return path;
}


/// 获取拼接后的文件名(id-name)
+ (NSString *)getVideoCacheFileNameWithURL:(NSURL*)url VideoID:(NSString *)video_id
{
    if(!url) {
        return @"";
    }
    
    if(!video_id || video_id.length == 0) {
        return [VideoRequest getVideoCacheFileNameWithURL:url];
    }
    
    return [NSString stringWithFormat:@"%@-%@", video_id, [VideoRequest getVideoCacheFileNameWithURL:url]];
}

/// 获取视频缓存文件名
+ (NSString *)getVideoCacheFileNameWithURL:(NSURL*)url
{
    NSString *name = [url.absoluteString.lastPathComponent componentsSeparatedByString:@"?"].firstObject;
    return name;
}

/// 获取完整视频文件的保存路径
+ (NSString *)getFileSavePath
{
    return [self getFilePathWithAppendingString:append_save];
}

/// 获取临时缓存存储路径
+ (NSString *)getFileTempCachePath
{
   return [self getFilePathWithAppendingString:append_temp];
}

/// 根据拼接字符串，设置对应路径
+ (NSString *)getFilePathWithAppendingString:(NSString *)apdStr
{    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).lastObject stringByAppendingString:apdStr];
    
    // Make folder.
    // 创建文件夹
    if (![fileManager fileExistsAtPath:path]) {
        [fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    return path;
}

/// 清空视频缓存
+ (void)clearAllVideoCache
{
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *spath = [VideoRequest getFileSavePath];
    NSString *tpath = [VideoRequest getFileTempCachePath];
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [fm removeItemAtPath:spath error:nil];
        [fm removeItemAtPath:tpath error:nil];
    });
}
@end
