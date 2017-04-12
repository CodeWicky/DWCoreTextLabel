//
//  DWWebImage.h
//  DWAsyncImage
//
//  Created by Wicky on 2017/2/4.
//  Copyright © 2017年 Wicky. All rights reserved.
//

/**
 DWWebImage
 轻量级图片异步下载缓存类
 
 version 1.0.0
 提供异步下载功能，提供图片缓存功能，线程安全。
 */

#import <UIKit/UIKit.h>

#ifndef DWWebImageMarco
#define DWWebImageMarco

///回调block
typedef void(^DWWebImageCallBack)(UIImage * image);

///文件下载完成通知
/**
 下载成功userInfo携带图片url及image对象
 下载失败携带错误原因
 */
#define DWWebImageDownloadFinishNotification @"DWWebImageDownloadFinishNotification"

///默认内存缓存成本（5Mb）
#define DWWebImageCacheDefaultCost (5 * 1024 * 1024)

///默认磁盘缓存过期时间（7天）
#define DWWebImageCacheDefaultExpirateTime (7 * 24 * 60 * 60)

#endif

typedef NS_OPTIONS(NSUInteger, DWWebImageCachePolicy) {///缓存策略
    DWWebImageCachePolicyNoCache = 1 << 0,///不缓存
    DWWebImageCachePolicyMemory = 1 << 1,///内存缓存
    DWWebImageCachePolicyDisk = 1 << 2,///磁盘缓存
};

typedef NS_ENUM(NSUInteger, DWWebImageCacheType) {///缓存数据类型
    DWWebImageCacheTypeUndefined,///未定义
    DWWebImageCacheTypeData,///缓存data数据
    DWWebImageCacheTypeImage,///缓存image数据
};

@interface UIButton (DWWebImage)

-(void)dw_setImageWithUrl:(NSString *)url forState:(UIControlState)state;

-(void)dw_setImageWithUrl:(NSString *)url placeHolder:(UIImage *)placeHolder forState:(UIControlState)state;

-(void)dw_setBackgroundImageWithUrl:(NSString *)url forState:(UIControlState)state;

-(void)dw_setBackgroundImageWithUrl:(NSString *)url placeHolder:(UIImage *)placeHolder forState:(UIControlState)state;

@end

@interface UIImageView (DWWebImage)

-(void)dw_setImageWithUrl:(NSString *)url;

-(void)dw_setImageWithUrl:(NSString *)url placeHolder:(UIImage *)placeHolder;

@end

#pragma mark --- 缓存管理类 ---
@interface DWWebImageCache : NSObject<NSCopying>

///缓存策略
@property (nonatomic ,assign) DWWebImageCachePolicy cachePolicy;

///缓存数据类型
@property (nonatomic ,assign) DWWebImageCacheType cacheType;

///缓存过期时间，默认值7天
@property (nonatomic ,assign) unsigned long long expirateTime;

///是否加密缓存
@property (nonatomic ,assign) BOOL useSecureKey;

///缓存空间
@property (nonatomic ,copy) NSString * cacheSpace;

///单例
+(instancetype)shareCache;

///通过key存缓存
-(void)cacheObj:(id)obj forKey:(NSString *)key;

///通过key取缓存
-(id)objCacheForKey:(NSString *)key;

///通过key移除缓存
-(void)removeCacheByKey:(NSString *)key;

///移除过期缓存
-(void)removeExpiratedCache;

@end



#pragma mark --- 图片下载类 ---
@interface DWWebImageDownloader : NSObject

///回调数组
@property (nonatomic ,strong) NSMutableArray <DWWebImageCallBack>* callBacks;

///下载任务
@property (nonatomic ,strong) NSURLSessionDataTask * task;

///下载图像实例
/**
 任务完成前为nil
 */
@property (nonatomic ,strong) UIImage * image;

///现在完成标志
@property (nonatomic ,assign) BOOL downloadFinish;

///以url下载图片
-(void)downloadImageWithUrlString:(NSString *)url;
@end



#pragma mark --- 任务线程类 ---
@interface DWWebImageOperation : NSOperation

///图片下载器
@property (nonatomic ,strong) DWWebImageDownloader * donwloader;

///以url及session下载图片
-(instancetype)initWithUrl:(NSString *)url session:(NSURLSession *)session;

@end



#pragma mark --- 下载管理类 ---
@interface DWWebImageManager : NSObject<NSCopying>

///线程字典
/**
 url为key，对应任务线程
 */
@property (nonatomic ,strong) NSMutableDictionary <NSString *,DWWebImageOperation *>* operations;

///缓存管理对象
@property (nonatomic ,strong) DWWebImageCache * cache;

///单例
+(instancetype)shareManager;

///以url下载图片，进行回调
-(void)downloadImageWithUrl:(NSString *)url completion:(DWWebImageCallBack)completion;

///以url移除下载任务
-(void)removeOperationByUrl:(NSString *)url;

@end
