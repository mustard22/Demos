//
//  ResourceLoaderManager.h
//  LSPlayer
//
//  Created by mustard on 2017/7/28.
//  Copyright © 2017年 song. All rights reserved.
//

/**
 * ResourceLoaderManager使用
 
 ResourceLoaderManager *resourceLoader = [[ResourceLoaderManager alloc] init];
 resourceLoader.delegate = self;
 NSURL *vurl = [resourceLoader getSchemeVideoURL:[NSURL URLWithString:url]];
 AVURLAsset *urlAsset = [AVURLAsset URLAssetWithURL:vurl options:nil];
 [urlAsset.resourceLoader setDelegate:resourceLoader queue:dispatch_get_main_queue()];
 */

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@class VideoRequest;

#pragma mark - Protocol : ResourceLoaderManagerDelegate
@protocol ResourceLoaderManagerDelegate <NSObject>
@optional
/// 视频加载完毕
- (void)didFinishLoadingWithRequest:(VideoRequest *)vRequest;
/// 视频加载失败
- (void)didFailLoadingWithRequest:(VideoRequest *)vRequest WithError:(NSInteger )errorCode;
/// 获取资源下载进度
- (void)getResourceDownloadProgress:(double)progress;
@end


#pragma mark - Class : ResourceLoaderManager

static NSString *kCustomVideoScheme = @"kCustomVideoScheme";

@interface ResourceLoaderManager : NSObject<AVAssetResourceLoaderDelegate>
@property (nonatomic, strong) VideoRequest *vRequest;
@property (nonatomic, weak) id<ResourceLoaderManagerDelegate> delegate;
// 标记缓存加载状态(默认YES)
@property (nonatomic, assign, readonly) BOOL isLoading;

/**
 *  @see NSURLComponents用来替代NSMutableURL，可以readwrite修改URL，这里通过更改请求策略，将容量巨大的连续媒体数据进行分段，分割为数量众多的小文件进行传递。采用了一个不断更新的轻量级索引文件来控制分割后小媒体文件的下载和播放，可同时支持直播和点播
 */
- (NSURL *)getSchemeVideoURL:(NSURL *)url  VideoID:(NSString *)video_id;

/// 取消当前加载
- (void)cancelCurrentLoading;
/// 继续当前加载
- (void)continueCurrentLoading;

/**
 *  将系统的AVAsset保存到本地
 *  @param asset AVPlayer的AVPlayerItem中的AVAsset，保存着播放资源的元数据
 *  @param name 保存到本地的文件名(xx.mp4)
 *  @discussion 使用AVURLAsset播放一个视频时，会缓存数据，缓存完毕时，把AVPlayerItem的属性AVAsset中资源的元数据写入到本地
 */
+ (BOOL)saveAVAssetToLocale:(AVAsset*)asset saveName:(NSString*)name;
@end




#pragma mark - Protocol : VideoRequestDelegate
@protocol VideoRequestDelegate <NSObject>

- (void)request:(VideoRequest *)vRequest didReceiveVideoLength:(NSUInteger)ideoLength mimeType:(NSString *)mimeType;

- (void)didReceiveVideoDataWithRequest:(VideoRequest *)vRequest;

/// 数据加载完毕
- (void)didFinishLoadingWithRequest:(VideoRequest *)vRequest;

/// 数据加载失败
- (void)didFailLoadingWithRequest:(VideoRequest *)vRequest WithError:(NSInteger )errorCode;
@end


#pragma mark - Class : VideoRequest

/// 临时缓存
static NSString *append_temp = @"/NewsDetailVideo_temp";
/// 完整文件
static NSString *append_save = @"/NewsDetailVideo_save";
/**
 *  视频请求
 *  \see 当视频没有缓存完全时，若进行快进|退操作，缓存数据不完整，不会保存到本地
 */
@interface VideoRequest : NSObject
@property (nonatomic, copy) NSString *scheme;
@property (nonatomic, readonly) NSUInteger  offset;
// 视频总长度
@property (nonatomic, readonly) NSUInteger  videoLength;
// 当前下载长度
@property (nonatomic, readonly) NSUInteger  downLoadingOffset;
@property (nonatomic, strong, readonly) NSString * mimeType;
@property (nonatomic, assign) BOOL          isFinishLoad;
@property (nonatomic, weak) id <VideoRequestDelegate> delegate;


- (void)setUrl:(NSURL *)url  VideoID:(NSString *)video_id Offset:(NSUInteger)offset;

/// 取消当前的数据请求
- (void)cancel;
/// 继续请求数据
- (void)continueLoading;
/// 清理临时数据（目前没有用）
- (void)clearData;

/// 过滤掉URL链接的特殊字符 返回的字符串作为文件名字
+ (NSString *)getFileNameWithURL:(NSString *)url;
/// 获取拼接后的文件名(id-name)
+ (NSString *)getVideoCacheFileNameWithURL:(NSURL*)url VideoID:(NSString *)video_id;
/// 获取完整视频文件的保存路径
+ (NSString *)getFileSavePath;
/// 获取临时缓存存储路径
+ (NSString *)getFileTempCachePath;
/// 异步清空视频缓存(完整视频文件 + 临时缓存)
+ (void)clearAllVideoCache;
@end
