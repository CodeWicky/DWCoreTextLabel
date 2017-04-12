//
//  DWWebImage.m
//  DWAsyncImage
//
//  Created by Wicky on 2017/2/4.
//  Copyright © 2017年 Wicky. All rights reserved.
//

#import "DWWebImage.h"
#import <CommonCrypto/CommonCrypto.h>

#define dispatch_async_main_safe(block)\
if ([NSThread currentThread].isMainThread) {\
block();\
} else {\
    dispatch_async(dispatch_get_main_queue(),block);\
}

#define DWWebImageCacheCompleteNotification @"DWWebImageCacheCompleteNotification"
#define DWErrorWithDescription(aCode,desc) [NSError errorWithDomain:@"com.Wicky.DWWebImage" code:aCode userInfo:@{NSLocalizedDescriptionKey:desc}]


@implementation UIButton (DWWebImage)

-(void)dw_setImageWithUrl:(NSString *)url placeHolder:(UIImage *)placeHolder forState:(UIControlState)state
{
    if (placeHolder) {
        [self setImage:placeHolder forState:state];
    }
    [[DWWebImageManager shareManager] downloadImageWithUrl:url completion:^(UIImage *image) {
        [self setImage:image forState:state];
    }];
}

-(void)dw_setImageWithUrl:(NSString *)url forState:(UIControlState)state
{
    [self dw_setImageWithUrl:url placeHolder:nil forState:state];
}

-(void)dw_setBackgroundImageWithUrl:(NSString *)url placeHolder:(UIImage *)placeHolder forState:(UIControlState)state
{
    if (placeHolder) {
        [self setBackgroundImage:placeHolder forState:state];
    }
    [[DWWebImageManager shareManager] downloadImageWithUrl:url completion:^(UIImage *image) {
        [self setBackgroundImage:image forState:state];
    }];
}

-(void)dw_setBackgroundImageWithUrl:(NSString *)url forState:(UIControlState)state
{
    [self dw_setBackgroundImageWithUrl:url placeHolder:nil forState:state];
}

@end

@implementation UIImageView (DWWebImage)

-(void)dw_setImageWithUrl:(NSString *)url placeHolder:(UIImage *)placeHolder
{
    if (placeHolder) {
        self.image = placeHolder;
    }
    [[DWWebImageManager shareManager] downloadImageWithUrl:url completion:^(UIImage *image) {
        self.image = image;
    }];
}

-(void)dw_setImageWithUrl:(NSString *)url
{
    [self dw_setImageWithUrl:url placeHolder:nil];
}

@end

#pragma mark --- DWWebImageManager ---

@interface DWWebImageManager ()

@property (nonatomic ,strong) NSURLSession * session;

@property (nonatomic ,strong) dispatch_semaphore_t semaphore;

@property (nonatomic ,strong) NSOperationQueue * queue;

@property (nonatomic ,strong) DWWebImageOperation * lastOperation;

@end

@implementation DWWebImageManager

-(instancetype)init
{
    self = [super init];
    if (self) {
        self.semaphore = dispatch_semaphore_create(1);
        self.cache = [DWWebImageCache shareCache];
        self.cache.cachePolicy = DWWebImageCachePolicyDisk | DWWebImageCachePolicyMemory;
        [self.cache removeExpiratedCache];
        dispatch_async_main_safe(^(){
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cacheCompleteFinishNotice:) name:DWWebImageCacheCompleteNotification object:nil];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadFinishNotice:) name:DWWebImageDownloadFinishNotification object:nil];
        });
    }
    return self;
}

///下载图片
-(void)downloadImageWithUrl:(NSString *)url completion:(DWWebImageCallBack)completion
{
    NSAssert(url.length, @"url不能为空");
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        ///从缓存加载图片
        UIImage * image = [UIImage imageWithData:[self.cache objCacheForKey:url]];
        if (image) {
            dispatch_async_main_safe(^(){
                completion(image);
            });
        } else {///无缓存
            dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
            DWWebImageOperation * operation = self.operations[url];///取出下载任务
            if (!operation) {///无任务
                operation = [[DWWebImageOperation alloc] initWithUrl:url session:self.session];
                self.operations[url] = operation;
                if (self.lastOperation) {
                    [self.lastOperation addDependency:operation];
                }
                [self.queue addOperation:operation];
                self.lastOperation = operation;
            }
            if (!operation.donwloader.downloadFinish) {
                [operation.donwloader.callBacks addObject:[completion copy]];
            } else {
                ///从缓存读取图片回调
                dispatch_async_main_safe(^(){
                    completion(operation.donwloader.image);
                });
            }
            dispatch_semaphore_signal(self.semaphore);
        }
    });
}

///下载完成回调
-(void)downloadFinishNotice:(NSNotification *)sender
{
    NSError * error = sender.userInfo[@"error"];
    if (error) {///移除任务
        [self removeOperationByUrl:sender.userInfo[@"url"]];
        [self removeCacheByUrl:sender.userInfo[@"url"]];
    }
}

///缓存完成通知回调
-(void)cacheCompleteFinishNotice:(NSNotification *)sender
{
    NSString * url = sender.userInfo[@"url"];
    if (url.length) {
        [self removeOperationByUrl:sender.userInfo[@"url"]];
    }
}

///移除下载进程
-(void)removeOperationByUrl:(NSString *)url
{
    DWWebImageOperation * operation = self.operations[url];
    [operation cancel];
    [self.operations removeObjectForKey:url];
}

///移除缓存
-(void)removeCacheByUrl:(NSString *)url
{
    [self.cache removeCacheByKey:url];
}

-(NSMutableDictionary<NSString *,DWWebImageOperation *> *)operations
{
    if (!_operations) {
        _operations = [NSMutableDictionary dictionary];
    }
    return _operations;
}

-(NSURLSession *)session
{
    if (!_session) {
        NSURLSessionConfiguration * config = [NSURLSessionConfiguration defaultSessionConfiguration];
        config.timeoutIntervalForRequest = 15;
        _session = [NSURLSession sessionWithConfiguration:config];
    }
    return _session;
}

-(NSOperationQueue *)queue
{
    if (!_queue) {
        _queue = [[NSOperationQueue alloc] init];
        _queue.maxConcurrentOperationCount = 6;
    }
    return _queue;
}

#pragma mark --- 单例 ---
static DWWebImageManager * mgr = nil;
+(instancetype)shareManager
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        mgr = [[self alloc] init];
    });
    return mgr;
}

+(instancetype)allocWithZone:(struct _NSZone *)zone
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        mgr = [super allocWithZone:zone];
    });
    return mgr;
}

-(id)copyWithZone:(NSZone *)zone
{
    return mgr;
}

@end



#pragma mark --- DWWebImageDownloader ---
@interface DWWebImageDownloader ()

@property (nonatomic ,copy) NSString * url;

@property (nonatomic ,strong) NSURLSession * session;

@end

@implementation DWWebImageDownloader

#pragma mark --- 接口方法 ---
-(instancetype)initWithUrl:(NSString *)url session:(NSURLSession *)session
{
    self = [super init];
    if (self) {
        _url = url;
        _session = session;
        _downloadFinish = NO;
    }
    return self;
}

-(void)downloadImageWithUrlString:(NSString *)url
{
    if (!url.length) {
        dispatch_async_main_safe((^(){
            [[NSNotificationCenter defaultCenter] postNotificationName:DWWebImageDownloadFinishNotification object:nil userInfo:@{@"error":DWErrorWithDescription(10001,@"url为空"),@"url":self.url}];
        }));
        return;
    }
    [self downloadImageWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:url]]];
}

#pragma mark --- Tool Method ---
-(void)downloadImageWithRequest:(NSURLRequest *)request
{
    if (!request) {
        dispatch_async_main_safe((^(){
            [[NSNotificationCenter defaultCenter] postNotificationName:DWWebImageDownloadFinishNotification object:nil userInfo:@{@"error":DWErrorWithDescription(10002,@"无法生成request对象"),@"url":self.url}];
        }));
        return;
    }
    
    self.url = request.URL.absoluteString;
    
    self.task = [self.session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {///下载错误
            dispatch_async_main_safe((^(){
                [[NSNotificationCenter defaultCenter] postNotificationName:DWWebImageDownloadFinishNotification object:nil userInfo:@{@"error":DWErrorWithDescription(10003, @"任务取消或错误"),@"url":self.url}];
            }));
            return ;
        }
        _session = nil;
        UIImage * image = [UIImage imageWithData:data];
        self.downloadFinish = YES;///标志下载完成
        self.image = image;
        if (!image) {
            dispatch_async_main_safe((^(){
                [[NSNotificationCenter defaultCenter] postNotificationName:DWWebImageDownloadFinishNotification object:nil userInfo:@{@"error":DWErrorWithDescription(10000, ([NSString stringWithFormat:@"图片下载失败：%@",self.url])),@"url":self.url}];
            }));
            return ;
        }
        //保存数据
        [[DWWebImageCache shareCache] cacheObj:data forKey:self.url];
        
        ///并发遍历
        [self.callBacks enumerateObjectsWithOptions:(NSEnumerationConcurrent | NSEnumerationReverse) usingBlock:^(DWWebImageCallBack  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (obj) {
                //图片回调
                dispatch_async_main_safe(^(){
                    obj(image);
                });
            }
        }];
        ///发送通知
        dispatch_async_main_safe((^(){
            [[NSNotificationCenter defaultCenter] postNotificationName:DWWebImageDownloadFinishNotification object:nil userInfo:@{@"url":self.url,@"image":image}];
        }));
    }];
}

-(NSMutableArray<DWWebImageCallBack> *)callBacks
{
    if (!_callBacks) {
        _callBacks = [NSMutableArray array];
    }
    return _callBacks;
}

@end



#pragma mark --- DWWebImageOperation ---
@implementation DWWebImageOperation

-(instancetype)initWithUrl:(NSString *)url session:(NSURLSession *)session
{
    self = [super init];
    if (self) {
        _donwloader = [[DWWebImageDownloader alloc] initWithUrl:url session:session];
        [_donwloader downloadImageWithUrlString:url];
    }
    return self;
}

-(void)start
{
    [super start];
    [self.donwloader.task resume];
}

-(void)cancel
{
    [super cancel];
    [self.donwloader.task cancel];
}

@end



#pragma mark --- DWWebImageCache ---
@interface DWWebImageCache ()

@property (nonatomic ,strong) NSCache * memCache;

@property (nonatomic ,strong) dispatch_semaphore_t semaphore;

@property (nonatomic ,strong) NSFileManager * fileMgr;

@end

@implementation DWWebImageCache

#pragma mark --- 接口方法 ---
-(instancetype)init
{
    self = [super init];
    if (self) {
        _memCache = [[NSCache alloc] init];
        _memCache.totalCostLimit = DWWebImageCacheDefaultCost;
        _memCache.countLimit = 20;
        _expirateTime = DWWebImageCacheDefaultExpirateTime;
        _useSecureKey = YES;
        _cachePolicy = DWWebImageCachePolicyDisk;
        _cacheType = DWWebImageCacheTypeData;
        _semaphore = dispatch_semaphore_create(1);
        _fileMgr = [NSFileManager defaultManager];
        [self createTempPath];
    }
    return self;
}

-(void)cacheObj:(id)obj forKey:(NSString *)key
{
    NSString * url = key;
    key = transferKey(key, self.useSecureKey);
    if (self.cachePolicy & DWWebImageCachePolicyDisk) {///磁盘缓存
        writeFileWithKey(obj, url, key, self.semaphore, self.fileMgr,self.cacheSpace);
    }
    if (self.cachePolicy & DWWebImageCachePolicyMemory) {
        ///做内存缓存
        [self.memCache setObject:obj forKey:key cost:costForObj(obj)];
    }
}

-(id)objCacheForKey:(NSString *)key
{
    __block id obj = nil;
    key = transferKey(key, self.useSecureKey);
    obj = [self.memCache objectForKey:key];
    if (!obj) {
        NSAssert((self.cacheType != DWWebImageCacheTypeUndefined), @"you must set a cacheType but not DWWebImageCacheTypeUndefined");
        readFileWithKey(key, self.cacheType, self.semaphore, self.cacheSpace,^(id object) {
            obj = object;
        });
    }
    return obj;
}

-(void)removeCacheByKey:(NSString *)key
{
    key = transferKey(key, self.useSecureKey);
    [self.memCache removeObjectForKey:key];
    [self.fileMgr removeItemAtPath:objPathWithKey(key,self.cacheSpace) error:nil];
}

-(void)removeExpiratedCache
{
    if (self.expirateTime) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            NSDirectoryEnumerator *dir=[self.fileMgr enumeratorAtPath:sandBoxPath(self.cacheSpace)];
            NSString *path=[NSString new];
            unsigned long long timeStamp = [[NSDate date] timeIntervalSince1970];
            while ((path=[dir nextObject])!=nil) {
                NSString * fileP = objPathWithKey(path,self.cacheSpace);
                NSDictionary * attrs = [self.fileMgr attributesOfItemAtPath:fileP error:nil];
                NSDate * dataCreate = attrs[NSFileModificationDate];
                if ((timeStamp - [dataCreate timeIntervalSince1970]) > self.expirateTime) {
                    [self.fileMgr removeItemAtPath:fileP error:nil];
                }
            }
        });
    }
}

#pragma mark -- Tool Method ---
-(void)createTempPath
{
    if (![self.fileMgr fileExistsAtPath:sandBoxPath(self.cacheSpace)]) {
        [self.fileMgr createDirectoryAtPath:sandBoxPath(self.cacheSpace) withIntermediateDirectories:YES attributes:nil error:NULL];
    }
}

#pragma mark --- Setter、getter ---
-(void)setExpirateTime:(unsigned long long)expirateTime
{
    _expirateTime = expirateTime;
    if (expirateTime) {
        [self removeExpiratedCache];
    }
}

-(NSString *)cacheSpace
{
    if (!_cacheSpace) {
        return @"defaultCacheSpace";
    }
    return _cacheSpace;
}

#pragma mark --- 单例 ---
static DWWebImageCache * cache = nil;
+(instancetype)shareCache
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cache = [[self alloc] init];
    });
    return cache;
}

+(instancetype)allocWithZone:(struct _NSZone *)zone
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cache = [super allocWithZone:zone];
    });
    return cache;
}

-(id)copyWithZone:(NSZone *)zone
{
    return cache;
}

#pragma mark --- 内联函数 ---

/**
 异步文件写入

 @param obj 写入对象
 @param url 下载url
 @param key 缓存key
 @param semaphore 信号量
 @param fileMgr 文件管理者
 @param cacheSpace  缓存空间
 */
static inline void writeFileWithKey(id obj,NSString * url,NSString * key,dispatch_semaphore_t semaphore,NSFileManager * fileMgr,NSString * cacheSpace){
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        NSString * path = objPathWithKey(key,cacheSpace);
        if ([fileMgr fileExistsAtPath:path]) {
            [fileMgr removeItemAtPath:path error:nil];
        }
        if ([obj2Data(obj) writeToFile:path atomically:YES]) {
            dispatch_async_main_safe(^(){
                [[NSNotificationCenter defaultCenter] postNotificationName:
                 DWWebImageCacheCompleteNotification object:nil userInfo:@{@"url":url}];
            });
        }
        dispatch_semaphore_signal(semaphore);
    });
};


/**
 文件读取

 @param key 缓存key
 @param type 文件类型
 @param semaphore 信号量
 @param cacheSpace 缓存空间
 @param completion 读取完成回调
 */
static inline void readFileWithKey(NSString * key,DWWebImageCacheType type,dispatch_semaphore_t semaphore,NSString * cacheSpace,void (^completion)(id obj)){
    dispatch_sync(dispatch_get_global_queue(0, 0), ^{
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        NSData * data = [NSData dataWithContentsOfFile:objPathWithKey(key,cacheSpace)];
        if (data && completion) {
            completion(transferDataToObj(data, type));
        }
        dispatch_semaphore_signal(semaphore);
    });
};


/**
 数据格式转换

 @param data 源数据
 @param type 数据类型
 @return 转换后数据
 */
static inline id transferDataToObj(NSData * data,DWWebImageCacheType type){
    switch (type) {
        case DWWebImageCacheTypeData:
            return data;
            break;
        case DWWebImageCacheTypeImage:
            return [UIImage imageWithData:data];
            break;
        default:
            return nil;
            break;
    }
};


/**
 返回文件路径

 @param key 缓存key
 @param cacheSpace 缓存空间
 @return 文件路径
 */
static inline NSString * objPathWithKey(NSString * key,NSString * cacheSpace){
    return [NSString stringWithFormat:@"%@/%@",sandBoxPath(cacheSpace),key];
};


/**
 对象转为NSData

 @param obj 对象
 @return 转换后data
 */
static inline NSData * obj2Data(id obj){
    NSData * data = nil;
    if ([obj isKindOfClass:[NSData class]]) {
        data = obj;
    }
    else if([obj isKindOfClass:[UIImage class]]) {
        data = UIImageJPEGRepresentation(obj, 1);
    }
    return data;
}


/**
 沙盒路径

 @param cacheSpace 缓存空间
 @return 沙盒路径
 */
static inline NSString * sandBoxPath(NSString * cacheSpace){
    return [NSHomeDirectory() stringByAppendingString:[NSString stringWithFormat:@"/Documents/DWWebImageCache/%@/",cacheSpace]];
};


/**
 计算对象所需缓存成本

 @param obj 对象
 @return 缓存成本
 */
static inline NSUInteger costForObj(id obj){
    NSUInteger cost = 0;
    ///根据数据类型计算cost
    if ([obj isKindOfClass:[NSData class]]) {
        cost = [[obj valueForKey:@"length"] unsignedIntegerValue];
    } else if ([obj isKindOfClass:[UIImage class]]) {
        UIImage * image = (UIImage *)obj;
        cost = (NSUInteger)image.size.width * image.size.height * image.scale * image.scale;
    }
    return cost;
};


/**
 返回缓存key

 @param originKey 原始key
 @param useSecureKey 是否加密
 @return 缓存key
 */
static inline NSString * transferKey(NSString * originKey,BOOL useSecureKey){
    return useSecureKey?encryptToMD5(originKey):originKey;
};


/**
 返回MD5加密字符串

 @param str 原始字符串
 @return 加密后字符串
 */
static inline NSString *encryptToMD5(NSString * str){
    CC_MD5_CTX md5;
    CC_MD5_Init (&md5);
    CC_MD5_Update (&md5, [str UTF8String], (CC_LONG)[str length]);
    
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5_Final (digest, &md5);
    return  [NSString stringWithFormat: @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
             digest[0],  digest[1],
             digest[2],  digest[3],
             digest[4],  digest[5],
             digest[6],  digest[7],
             digest[8],  digest[9],
             digest[10], digest[11],
             digest[12], digest[13],
             digest[14], digest[15]];
};

@end
