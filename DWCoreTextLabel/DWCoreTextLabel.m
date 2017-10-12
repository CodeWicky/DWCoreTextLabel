
//  DWCoreTextLabel.m
//  DWCoreTextLabel
//
//  Created by Wicky on 16/12/4.
//  Copyright © 2016年 Wicky. All rights reserved.
//

#import "DWCoreTextLabel.h"
#import <CoreText/CoreText.h>
#import "DWAsyncLayer.h"
#import "DWWebImage.h"
#import "DWCoreTextLabelCalculator.h"
#import "DWCoreTextLayout.h"
#import "DWCoreTextSelectionView.h"

///绘制取消
#define DRAWCANCELED \
do {\
if (isCanceled()) {\
return;\
}\
} while(0);

///绘制取消并且安全释放
#define DRAWCANCELEDWITHREALSE(x,y) \
do {\
if (isCanceled()) {\
CFSAFERELEASE(x)\
CFSAFERELEASE(y)\
return;\
}\
} while(0);

@interface DWCoreTextLabel ()

///绘制文本
@property (nonatomic ,strong) NSMutableAttributedString * mAStr;

///以路径绘制图片数组
@property (nonatomic ,strong) NSMutableArray * pathImageArr;

///插入模式的图片数组
@property (nonatomic ,strong) NSMutableArray * insertImageArr;

///占位图字典
@property (nonatomic ,strong) NSMutableDictionary <NSString *,NSMutableArray *>* placeHolderDic;

///活跃文本范围数组
@property (nonatomic ,strong) NSMutableArray * textRangeArr;

///绘制surround图片是排除区域数组
@property (nonatomic ,strong) NSMutableArray * imageExclusion;

///绘制插入图片是保存插入位置的数组
@property (nonatomic ,strong) NSMutableArray * arrLocationImgHasAdd;

///点击状态
@property (nonatomic ,assign) BOOL textClicked;

///自动链接点击状态
@property (nonatomic ,assign) BOOL linkClicked;

///保存可变排除区域的数组
@property (nonatomic ,strong) NSMutableArray * exclusionP;

///排除区域配置字典
@property (nonatomic ,strong) NSDictionary * exclusionDic;

///具有响应事件
@property (nonatomic ,assign) BOOL hasActionToDo;

///高亮范围字典
@property (nonatomic ,strong) NSDictionary * highlightDic;

///重新计算
@property (nonatomic ,assign) BOOL reCalculate;

///绘制范围
@property (nonatomic ,strong) UIBezierPath * drawPath;

///首次绘制
@property (nonatomic ,assign) BOOL finishFirstDraw;

///自动链接检测结果字典
@property (nonatomic ,strong) NSMutableDictionary * autoCheckLinkDic;

///自定制链接检测结果字典
@property (nonatomic ,strong) NSMutableDictionary * customLinkDic;

///重新自动检测
@property (nonatomic ,assign) BOOL reCheck;

///绘制队列
@property (nonatomic ,strong) dispatch_queue_t syncQueue;

///布局计算类
@property (nonatomic ,strong) DWCoreTextLayout * layout;

///选中状态蒙层
@property (nonatomic ,strong) DWCoreTextSelectionView * selectionView;

///选择模式手势
@property (nonatomic ,weak) UITapGestureRecognizer * selectGes;

///当前选中的范围
@property (nonatomic ,assign) NSRange seletedRange;

///正在拖动
@property (nonatomic ,assign) BOOL grabbing;

///拖动模式下不变的位置
@property (nonatomic ,assign) NSUInteger stableLoc;

@end

static DWTextImageDrawMode DWTextImageDrawModeInsert = 2;

@implementation DWCoreTextLabel
@synthesize font = _font;
@synthesize textColor = _textColor;
@synthesize exclusionPaths = _exclusionPaths;
@synthesize lineSpacing = _lineSpacing;
@synthesize autoCheckConfig = _autoCheckConfig;
@synthesize phoneNoAttributes = _phoneNoAttributes;
@synthesize phoneNoHighlightAttributes = _phoneNoHighlightAttributes;
@synthesize emailAttributes = _emailAttributes;
@synthesize emailHighlightAttributes = _emailHighlightAttributes;
@synthesize URLAttributes = _URLAttributes;
@synthesize URLHighlightAttributes = _URLHighlightAttributes;
@synthesize naturalNumAttributes = _naturalNumAttributes;
@synthesize naturalNumHighlightAttributes = _naturalNumHighlightAttributes;
@synthesize customLinkAttributes = _customLinkAttributes;
@synthesize customLinkHighlightAttributes = _customLinkHighlightAttributes;

#pragma mark --- 接口方法 ---

///以指定模式绘制图片
-(void)dw_DrawImage:(UIImage *)image withImageID:(NSString *)imageID atFrame:(CGRect)frame margin:(CGFloat)margin drawMode:(DWTextImageDrawMode)mode target:(id)target selector:(SEL)selector {
    NSMutableDictionary * dic = [self configImage:image withImageID:imageID atFrame:frame margin:margin drawMode:mode target:target selector:selector];
    if (!dic) {
        return;
    }
    [self.pathImageArr addObject:dic];
    [self handleAutoRedrawWithRecalculate:YES reCheck:NO];
}

-(void)dw_DrawImageWithUrl:(NSString *)url withImageID:(NSString *)imageID atFrame:(CGRect)frame margin:(CGFloat)margin drawMode:(DWTextImageDrawMode)mode target:(id)target selector:(SEL)selector {
    [self dw_DrawImageWithUrl:url withImageID:imageID placeHolder:nil atFrame:frame margin:margin drawMode:mode target:target selector:selector];
}
    
-(void)dw_DrawImageWithUrl:(NSString *)url withImageID:(NSString *)imageID placeHolder:(UIImage *)placeHolder atFrame:(CGRect)frame margin:(CGFloat)margin drawMode:(DWTextImageDrawMode)mode target:(id)target selector:(SEL)selector {
    if (!placeHolder) {
        placeHolder = [UIImage new];
    }
    NSMutableDictionary * dic = [self configImage:placeHolder withImageID:imageID atFrame:frame margin:margin drawMode:mode target:target selector:selector];
    if (!dic) {
        return;
    }
    [self handlePlaceHolderDic:dic withUrl:url insertMode:NO editImage:nil];
}

///以路径绘制图片
-(void)dw_DrawImage:(UIImage *)image withImageID:(NSString *)imageID path:(UIBezierPath *)path margin:(CGFloat)margin drawMode:(DWTextImageDrawMode)mode target:(id)target selector:(SEL)selector {
    NSMutableDictionary * dic = [self configImage:image withImageID:imageID path:path margin:margin drawMode:mode target:target selector:selector];
    if (!dic) {
        return;
    }
    [self.pathImageArr addObject:dic];
    [self handleAutoRedrawWithRecalculate:YES reCheck:NO];
}

-(void)dw_DrawImageWithUrl:(NSString *)url withImageID:(NSString *)imageID path:(UIBezierPath *)path margin:(CGFloat)margin drawMode:(DWTextImageDrawMode)mode target:(id)target selector:(SEL)selector {
    [self dw_DrawImageWithUrl:url withImageID:imageID placeHolder:nil path:path margin:margin drawMode:mode target:self selector:selector];
}
    
-(void)dw_DrawImageWithUrl:(NSString *)url withImageID:(NSString *)imageID placeHolder:(UIImage *)placeHolder path:(UIBezierPath *)path margin:(CGFloat)margin drawMode:(DWTextImageDrawMode)mode target:(id)target selector:(SEL)selector {
    if (!placeHolder) {
        placeHolder = [UIImage new];
    }
    NSMutableDictionary * dic = [self configImage:placeHolder withImageID:imageID path:path margin:margin drawMode:mode target:target selector:selector];
    if (!dic) {
        return;
    }
    [self handlePlaceHolderDic:dic withUrl:url insertMode:NO editImage:^(UIImage *image) {
        UIBezierPath * newPath = [path copy];
        [newPath applyTransform:CGAffineTransformMakeTranslation(-newPath.bounds.origin.x, -newPath.bounds.origin.y)];
        return [DWCoreTextLabel dw_ClipImage:image withPath:newPath mode:(DWImageClipModeScaleAspectFill)];
    }];
}

///在字符串指定位置插入图片
-(void)dw_InsertImage:(UIImage *)image withImageID:(NSString *)imageID size:(CGSize)size padding:(CGFloat)padding descent:(CGFloat)descent atLocation:(NSUInteger)location target:(id)target selector:(SEL)selector {
    NSMutableDictionary * dic = [self configImage:image withImageID:imageID size:size padding:padding descent:descent atLocation:location target:target selector:selector];
    if (!dic) {
        return;
    }
    [self.insertImageArr addObject:dic];
    [self handleAutoRedrawWithRecalculate:YES reCheck:YES];
}

-(void)dw_InsertImageWithUrl:(NSString *)url withImageID:(NSString *)imageID size:(CGSize)size padding:(CGFloat)padding descent:(CGFloat)descent atLocation:(NSUInteger)location target:(id)target selector:(SEL)selector {
    [self dw_InsertImageWithUrl:url withImageID:imageID placeHolder:nil size:size padding:padding descent:descent atLocation:location target:self selector:selector];
}
    
-(void)dw_InsertImageWithUrl:(NSString *)url withImageID:(NSString *)imageID placeHolder:(UIImage *)placeHolder size:(CGSize)size padding:(CGFloat)padding descent:(CGFloat)descent atLocation:(NSUInteger)location target:(id)target selector:(SEL)selector {
    if (!placeHolder) {
        placeHolder = [UIImage new];
    }
    NSMutableDictionary * dic = [self configImage:placeHolder withImageID:imageID size:size padding:padding descent:descent atLocation:location target:target selector:selector];
    if (!dic) {
        return;
    }
    [self handlePlaceHolderDic:dic withUrl:url insertMode:YES editImage:nil];
}

-(void)dw_RemoveImageByID:(NSString *)imageID {
    if (!imageID.length) {
        return;
    }
    [self handleDeleteImageConfigArr:self.insertImageArr withImageID:imageID];
    [self handleDeleteImageConfigArr:self.pathImageArr withImageID:imageID];
    [self handleAutoRedrawWithRecalculate:YES reCheck:NO reDraw:YES];
}

-(void)handleDeleteImageConfigArr:(NSMutableArray *)configArr withImageID:(NSString *)imageID {
    NSInteger count = configArr.count;
    for (int i = 0; i < count; i ++) {
        NSMutableDictionary * dic = configArr[i];
        NSString * ID = dic[@"imageID"];
        if ([ID isEqualToString:imageID]) {
            [configArr removeObject:dic];
            i --;
            count --;
        }
    }
}

///给指定范围添加响应事件
-(void)dw_AddTarget:(id)target selector:(SEL)selector toRange:(NSRange)range {
    if (target && selector && range.length > 0) {
        NSMutableDictionary * dic = [NSMutableDictionary dictionaryWithDictionary:@{@"target":target,@"SEL":NSStringFromSelector(selector),@"range":[NSValue valueWithRange:range]}];
        [self.textRangeArr addObject:dic];
        [self handleAutoRedrawWithRecalculate:YES reCheck:YES];
    }
}

///返回指定路径的图片
+(UIImage *)dw_ClipImage:(UIImage *)image withPath:(UIBezierPath *)path mode:(DWImageClipMode)mode {
    if (!image) {
        return nil;
    }
    CGFloat originScale = image.size.width * 1.0 / image.size.height;
    CGRect boxBounds = path.bounds;
    CGFloat width = boxBounds.size.width;
    CGFloat height = width / originScale;
    
    switch (mode) {
        case DWImageClipModeScaleAspectFit:
        {
            if (height > boxBounds.size.height) {
                height = boxBounds.size.height;
                width = height * originScale;
            }
        }
            break;
        case DWImageClipModeScaleAspectFill:
        {
            if (height < boxBounds.size.height) {
                height = boxBounds.size.height;
                width = height * originScale;
            }
        }
            break;
        default:
            if (height != boxBounds.size.height) {
                height = boxBounds.size.height;
            }
            break;
    }
    
    ///开启上下文
    UIGraphicsBeginImageContextWithOptions(boxBounds.size, NO, [UIScreen mainScreen].scale);
    CGContextRef bitmap = UIGraphicsGetCurrentContext();
    
    ///切图
    UIBezierPath * newPath = [path copy];
    if (!(newPath.bounds.origin.x * newPath.bounds.origin.y)) {
        [newPath applyTransform:CGAffineTransformMakeTranslation(-newPath.bounds.origin.x, -newPath.bounds.origin.y)];
    }
    [newPath addClip];
    
    ///移动原点至图片中心
    CGContextTranslateCTM(bitmap, boxBounds.size.width/2.0, boxBounds.size.height/2.0);
    CGContextScaleCTM(bitmap, 1.0, -1.0);
    CGContextDrawImage(bitmap, CGRectMake(-width / 2, -height / 2, width, height), image.CGImage);
    
    ///生成图片
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}

+(void)dw_ClipImageWithUrl:(NSString *)url withPath:(UIBezierPath *)path mode:(DWImageClipMode)mode completion:(void(^)(UIImage * image))completion {
    [[DWWebImageManager shareManager] downloadImageWithUrl:url completion:^(UIImage *image) {
        image = [DWCoreTextLabel dw_ClipImage:image withPath:path mode:mode];
        completion(image);
    }];
}

#pragma mark --- 插入图片相关 ---

///将所有插入图片插入字符串
-(void)handleStr:(NSMutableAttributedString *)str withInsertImageArr:(NSMutableArray *)arr arrLocationImgHasAdd:(NSMutableArray *)arrLocationImgHasAdd {
    [arr enumerateObjectsUsingBlock:^(NSMutableDictionary * dic, NSUInteger idx, BOOL * _Nonnull stop) {
        handleInsertPic(self,dic,str,arrLocationImgHasAdd);
    }];
}

///将图片设置代理后插入富文本
static inline void handleInsertPic(DWCoreTextLabel * label,NSMutableDictionary * dic,NSMutableAttributedString * str,NSMutableArray * arrLocationImgHasAdd) {
    NSInteger location = [dic[@"location"] integerValue];
    if (location > str.length) {
        return;
    }
    CTRunDelegateCallbacks callBacks;
    memset(&callBacks, 0, sizeof(CTRunDelegateCallbacks));
    callBacks.version = kCTRunDelegateVersion1;
    callBacks.getAscent = ascentCallBacks;
    callBacks.getDescent = descentCallBacks;
    callBacks.getWidth = widthCallBacks;
    CTRunDelegateRef delegate = CTRunDelegateCreate(& callBacks, (__bridge void *)dic);
    unichar placeHolder = 0xFFFC;
    NSString * placeHolderStr = [NSString stringWithCharacters:&placeHolder length:1];
    NSMutableAttributedString * placeHolderAttrStr = [[NSMutableAttributedString alloc] initWithString:placeHolderStr];
    CFAttributedStringSetAttribute((CFMutableAttributedStringRef)placeHolderAttrStr, CFRangeMake(0, 1), kCTRunDelegateAttributeName, delegate);
    CFSAFERELEASE(delegate);
    NSInteger offset = getInsertOffset(arrLocationImgHasAdd,location);
    [str insertAttributedString:placeHolderAttrStr atIndex:location + offset];
}

///根据三种类型获取配置字典
-(NSMutableDictionary *)configImage:(UIImage *)image withImageID:(NSString *)imageID atFrame:(CGRect)frame margin:(CGFloat)margin drawMode:(DWTextImageDrawMode)mode target:(id)target selector:(SEL)selector {
    if (!image) {
        return nil;
    }
    if (CGRectEqualToRect(frame, CGRectZero)) {
        return nil;
    }
    CGRect drawFrame = CGRectInset(frame, margin, margin);
    UIBezierPath * drawPath = [UIBezierPath bezierPathWithRect:frame];
    UIBezierPath * activePath = getImageAcitvePath(drawPath,margin);
    NSMutableDictionary * dic = [NSMutableDictionary dictionaryWithDictionary:@{@"image":image,@"drawPath":drawPath,@"activePath":activePath,@"frame":[NSValue valueWithCGRect:drawFrame],@"margin":@(margin),@"drawMode":@(mode)}];
    if (target && selector) {
        [dic setValue:target forKey:@"target"];
        [dic setValue:NSStringFromSelector(selector) forKey:@"SEL"];
    }
    if (imageID.length) {
        [dic setValue:imageID forKey:@"imageID"];
    }
    return dic;
}

-(NSMutableDictionary *)configImage:(UIImage *)image withImageID:(NSString *)imageID path:(UIBezierPath *)path margin:(CGFloat)margin drawMode:(DWTextImageDrawMode)mode target:(id)target selector:(SEL)selector {
    if (!image) {
        return nil;
    }
    if (!path) {
        return nil;
    }
    UIBezierPath * newPath = [path copy];
    [newPath applyTransform:CGAffineTransformMakeTranslation(-newPath.bounds.origin.x, -newPath.bounds.origin.y)];
    image = [DWCoreTextLabel dw_ClipImage:image withPath:newPath mode:(DWImageClipModeScaleAspectFill)];
    UIBezierPath * activePath = getImageAcitvePath(path,margin);
    
    NSMutableDictionary * dic = [NSMutableDictionary dictionaryWithDictionary:@{@"image":image,@"drawPath":path,@"activePath":activePath,@"frame":[NSValue valueWithCGRect:CGRectInset(path.bounds, margin, margin)],@"drawMode":@(mode)}];
    if (target && selector) {
        [dic setValue:target forKey:@"target"];
        [dic setValue:NSStringFromSelector(selector) forKey:@"SEL"];
    }
    if (imageID.length) {
        [dic setValue:imageID forKey:@"imageID"];
    }
    return dic;
}

-(NSMutableDictionary *)configImage:(UIImage *)image withImageID:(NSString *)imageID size:(CGSize)size padding:(CGFloat)padding descent:(CGFloat)descent atLocation:(NSUInteger)location target:(id)target selector:(SEL)selector {
    if (!image) {
        return nil;
    }
    if (padding != 0) {
        size = CGSizeMake(size.width + padding * 2, size.height);
    }
    NSMutableDictionary * dic = [NSMutableDictionary dictionaryWithDictionary:@{@"image":image,@"size":[NSValue valueWithCGSize:size],@"padding":@(padding),@"location":@(location),@"descent":@(descent),@"drawMode":@(DWTextImageDrawModeInsert)}];
    if (target && selector) {
        [dic setValue:target forKey:@"target"];
        [dic setValue:NSStringFromSelector(selector) forKey:@"SEL"];
    }
    if (imageID.length) {
        [dic setValue:imageID forKey:@"imageID"];
    }
    return dic;
}

///处理占位图的绘制及替换工作
-(void)handlePlaceHolderDic:(NSMutableDictionary *)dic withUrl:(NSString *)url insertMode:(BOOL)insertMode editImage:(UIImage *(^)(UIImage * image))edit {
    ///将配置字典添加到占位图字典中
    NSMutableArray * placeHolderArr = self.placeHolderDic[url];
    if (!placeHolderArr) {
        placeHolderArr = [NSMutableArray array];
        self.placeHolderDic[url] = placeHolderArr;
    }
    if (![placeHolderArr containsObject:dic]) {
        [placeHolderArr addObject:dic];
    }
    
    ///绘制占位图
    if (insertMode) {
        [self.insertImageArr addObject:dic];
    } else {
        [self.pathImageArr addObject:dic];
    }
    [self handleAutoRedrawWithRecalculate:YES reCheck:NO];
    
    ///下载网络图片
    __weak typeof(self)weakSelf = self;
    [[DWWebImageManager shareManager] downloadImageWithUrl:url completion:^(UIImage *image) {
        ///下载完成后替换占位图配置字典中图片为网络图片并绘制
        if (image) {
            if (edit) {
                image = edit(image);
            }
            NSMutableArray * placeHolderArr = weakSelf.placeHolderDic[url];
            if (placeHolderArr) {
                [placeHolderArr enumerateObjectsUsingBlock:^(NSMutableDictionary * obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    [obj setValue:image forKey:@"image"];
                }];
                [placeHolderArr removeAllObjects];
                [weakSelf handleAutoRedrawWithRecalculate:NO reCheck:NO];
            }
        }
    }];
}

#pragma mark ---文本相关---

///处理句尾省略号
-(void)handleLastLineTruncateWithLastLineRange:(CFRange)range attributeString:(NSMutableAttributedString *)mAStr{
    NSRange r = NSRangeFromCFRange(range);
    NSDictionary * lastAttribute = [mAStr attributesAtIndex:(NSMaxRange(r) - 1) effectiveRange:NULL];
    NSMutableParagraphStyle * newPara = [lastAttribute[NSParagraphStyleAttributeName] mutableCopy];
    if (!newPara) {
        newPara = [[NSMutableParagraphStyle alloc] init];
    }
    newPara.lineBreakMode = NSLineBreakByTruncatingTail;
    [mAStr addAttribute:NSParagraphStyleAttributeName value:newPara range:r];
}

///添加活跃文本属性方法
-(void)handleActiveTextWithStr:(NSMutableAttributedString *)str visibleRange:(NSRange)visibleRange rangeSet:(NSMutableSet *)rangeSet {
    [self.textRangeArr enumerateObjectsUsingBlock:^(NSMutableDictionary * dic  , NSUInteger idx, BOOL * _Nonnull stop) {
        NSRange range = [dic[@"range"] rangeValue];
        if (NSEqualRanges(NSIntersectionRange(range, visibleRange), NSRangeZero)) {
            return ;
        }
        range = getRangeOffset(range,self.arrLocationImgHasAdd);
        [rangeSet addObject:[NSValue valueWithRange:range]];
        [str addAttribute:@"clickAttribute" value:dic range:range];
        if (self.textClicked && self.highlightDic) {
            if (NSEqualRanges([dic[@"range"] rangeValue], [self.highlightDic[@"range"] rangeValue])) {
                [str addAttributes:self.activeTextHighlightAttributes range:range];
            } else {
                if (self.activeTextAttributes) {
                    [str addAttributes:self.activeTextAttributes range:range];
                }
            }
        } else {
            if (self.activeTextAttributes) {
                [str addAttributes:self.activeTextAttributes range:range];
            }
        }
    }];
}

#pragma mark ---自动检测链接相关---
///自动检测链接方法
-(void)handleAutoCheckLinkWithStr:(NSMutableAttributedString *)str linkRange:(NSRange)linkRange rangeSet:(NSMutableSet *)rangeSet {
    [self handleAutoCheckWithLinkType:DWLinkTypeEmail str:str linkRange:linkRange rangeSet:rangeSet linkDic:self.autoCheckLinkDic attributeName:@"autoCheckLink"];
    [self handleAutoCheckWithLinkType:DWLinkTypeURL str:str linkRange:linkRange rangeSet:rangeSet linkDic:self.autoCheckLinkDic attributeName:@"autoCheckLink"];
    [self handleAutoCheckWithLinkType:DWLinkTypePhoneNo str:str linkRange:linkRange rangeSet:rangeSet linkDic:self.autoCheckLinkDic attributeName:@"autoCheckLink"];
    [self handleAutoCheckWithLinkType:DWLinkTypeNaturalNum str:str linkRange:linkRange rangeSet:rangeSet linkDic:self.autoCheckLinkDic attributeName:@"autoCheckLink"];
}

///根据类型处理自动链接
-(void)handleAutoCheckWithLinkType:(DWLinkType)linkType str:(NSMutableAttributedString *)str linkRange:(NSRange)linkRange rangeSet:(NSMutableSet *)rangeSet linkDic:(NSMutableDictionary *)linkDic attributeName:(NSString *)attributeName {
    
    NSString * pattern = @"";
    NSDictionary * tempAttributesDic = nil;
    NSDictionary * tempHighLightAttributesDic = nil;
    switch (linkType) {///根据type获取高亮属性及匹配正则
        case DWLinkTypeNaturalNum:
        {
            pattern = self.autoCheckConfig[@"naturalNum"];
            tempAttributesDic = self.naturalNumAttributes;
            tempHighLightAttributesDic = self.naturalNumHighlightAttributes;
        }
            break;
        case DWLinkTypePhoneNo:
        {
            pattern = self.autoCheckConfig[@"phoneNo"];
            tempAttributesDic = self.phoneNoAttributes;
            tempHighLightAttributesDic = self.phoneNoHighlightAttributes;
        }
            break;
        case DWLinkTypeEmail:
        {
            pattern = self.autoCheckConfig[@"email"];
            tempAttributesDic = self.emailAttributes;
            tempHighLightAttributesDic = self.emailHighlightAttributes;
        }
            break;
        case DWLinkTypeURL:
        {
            pattern = self.autoCheckConfig[@"URL"];
            tempAttributesDic = self.URLAttributes;
            tempHighLightAttributesDic = self.URLHighlightAttributes;
        }
            break;
        case DWLinkTypeCustom:
        {
            pattern = self.customLinkRegex.length?self.customLinkRegex:@"";
            tempAttributesDic = self.customLinkAttributes;
            tempHighLightAttributesDic = self.customLinkHighlightAttributes;
        }
            break;
        default:
        {
            pattern = self.autoCheckConfig[@"phoneNo"];
            tempAttributesDic = self.phoneNoAttributes;
            tempHighLightAttributesDic = self.phoneNoHighlightAttributes;
        }
            break;
    }
    if (pattern.length) {
        NSMutableArray * arrLink = nil;
        if (self.reCheck) {
            NSRegularExpression * regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:nil];
            ///获取匹配结果
            NSArray * arr = [regex matchesInString:str.string options:0 range:linkRange];
            ///处理匹配结果，排除已经匹配过的结果
            NSMutableArray * arrTemp = [NSMutableArray array];
            [arr enumerateObjectsUsingBlock:^(NSTextCheckingResult * result, NSUInteger idx, BOOL * _Nonnull stop) {
                __block BOOL contain = NO;
                NSMutableArray * replicateRangeArr = [NSMutableArray array];
                [rangeSet enumerateObjectsUsingBlock:^(NSValue * RValue, BOOL * _Nonnull stop) {
                    NSRange range = NSIntersectionRange([RValue rangeValue], result.range);
                    if (range.length > 0) {
                        contain = YES;
                        hanldeReplicateRange(result.range,RValue.rangeValue,str,pattern,replicateRangeArr);
                        *stop = YES;
                    }
                }];
                if (!contain) {
                    [arrTemp addObject:result];
                    [rangeSet addObject:[NSValue valueWithRange:result.range]];
                } else if (replicateRangeArr.count) {
                    [replicateRangeArr enumerateObjectsUsingBlock:^(NSTextCheckingResult * obj, NSUInteger idx, BOOL * _Nonnull stop) {
                        [arrTemp addObject:obj];
                        [rangeSet addObject:[NSValue valueWithRange:obj.range]];
                    }];
                }
            }];
            [linkDic setValue:arrTemp forKey:pattern];
            arrLink = arrTemp;
        } else {
            arrLink = linkDic[pattern];
        }
        ///添加高亮属性
        NSRange highLightRange = [self.highlightDic[@"range"] rangeValue];
        [arrLink enumerateObjectsUsingBlock:^(NSTextCheckingResult * obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSRange range = obj.range;
            NSDictionary * dic = @{@"link":[str.string substringWithRange:range],@"range":[NSValue valueWithRange:range],@"linkType":@(linkType),@"target":self,@"SEL":NSStringFromSelector(@selector(autoLinkClicked:))};
            [str addAttribute:attributeName value:dic range:range];
            if (self.linkClicked && self.highlightDic) {
                if (NSEqualRanges(range, highLightRange)) {
                    [str addAttributes:tempHighLightAttributesDic range:range];
                } else {
                    if (tempAttributesDic) {
                        [str addAttributes:tempAttributesDic range:range];
                    }
                }
            } else {
                if (tempAttributesDic) {
                    [str addAttributes:tempAttributesDic range:range];
                }
            }
        }];
    }
}

///处理文本高亮状态
-(void)handleStringHighlightAttributesWithRangeSet:(NSMutableSet *)rangeSet visibleRange:(CFRange)visibleRange {
    NSRange vRange = NSRangeFromCFRange(visibleRange);
    [self handleAutoCheckWithLinkType:DWLinkTypeCustom str:self.mAStr linkRange:vRange rangeSet:rangeSet linkDic:self.customLinkDic attributeName:@"customLink"];
    ///处理自动检测链接
    if (self.autoCheckLink) {
        [self handleAutoCheckLinkWithStr:self.mAStr linkRange:vRange rangeSet:rangeSet];
    }
}

///处理匹配结果中重复范围
static inline void hanldeReplicateRange(NSRange targetR,NSRange exceptR,NSMutableAttributedString * str,NSString * pattern,NSMutableArray * linkArr) {
    NSArray * arr = getRangeExcept(targetR, exceptR);
    [arr enumerateObjectsUsingBlock:^(NSValue * rangeValue, NSUInteger idx, BOOL * _Nonnull stop) {
        NSRegularExpression * regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:nil];
        NSArray * results = [regex matchesInString:str.string options:0 range:rangeValue.rangeValue];
        [linkArr addObjectsFromArray:results];
    }];
}

#pragma mark ---绘制相关---

///绘制富文本
-(void)drawTheTextWithContext:(CGContextRef)context isCanceled:(BOOL(^)(void))isCanceled {
    dispatch_barrier_sync(self.syncQueue, ^{
        CGContextSaveGState(context);
        CGContextSetTextMatrix(context, CGAffineTransformIdentity);
        CGContextTranslateCTM(context, 0, self.bounds.size.height);
        CGContextScaleCTM(context, 1.0, -1.0);
        
        ///计算绘制尺寸限制
        CGFloat limitWidth = (self.bounds.size.width - self.textInsets.left - self.textInsets.right) > 0 ? (self.bounds.size.width - self.textInsets.left - self.textInsets.right) : 0;
        CGFloat limitHeight = (self.bounds.size.height - self.textInsets.top - self.textInsets.bottom) > 0 ? (self.bounds.size.height - self.textInsets.top - self.textInsets.bottom) : 0;
        
        ///获取排除区域
        NSArray * exclusionPaths = [self handleExclusionPathsWithOffset:self.textInsets.bottom - self.textInsets.top];
        CGRect frame = CGRectMake(self.textInsets.left, self.textInsets.bottom, limitWidth, limitHeight);
        NSDictionary * exclusionConfig = getExclusionDic(exclusionPaths, frame);
        BOOL needDrawString = self.attributedText.length || self.text.length;
        
        DRAWCANCELED
        if (needDrawString) {///必须重新计算（防止设置高亮颜色未设置普通颜色时点击后不恢复的bug）
            ///获取要绘制的文本(初步处理，未处理插入图片、句尾省略号、高亮)
            self.mAStr = getMAStr(self,limitWidth,exclusionPaths);
        }
        CTFramesetterRef frameSetter4Cal = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)self.mAStr);
        CTFrameRef frame4Cal = CTFramesetterCreateFrame(frameSetter4Cal, CFRangeMake(0, 0), [UIBezierPath bezierPathWithRect:frame].CGPath, (__bridge_retained CFDictionaryRef)exclusionConfig);
        
        
        CFRange visibleRange = getRangeToDrawForVisibleString(frame4Cal);
        CFRange lastRange = getLastLineRange(frame4Cal, self.numberOfLines,visibleRange);
        visibleRange = getVisibleRangeFromLastRange(visibleRange, lastRange);
        DRAWCANCELEDWITHREALSE(frameSetter4Cal, frame4Cal)
        ///已添加事件、链接的集合
        ///处理插入图片
        if (needDrawString) {
            NSMutableArray * arrInsert = self.insertImageArr.copy;
            [self.arrLocationImgHasAdd removeAllObjects];
            if (arrInsert.count) {
                ///富文本插入图片占位符
                [self handleStr:self.mAStr withInsertImageArr:arrInsert arrLocationImgHasAdd:self.arrLocationImgHasAdd];
                ///插入图片后重新处理工厂及frame，添加插入图片后的字符串，消除插入图片影响
                CFSAFERELEASE(frameSetter4Cal)
                CFSAFERELEASE(frame4Cal)
                frameSetter4Cal = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)self.mAStr);
                frame4Cal = CTFramesetterCreateFrame(frameSetter4Cal, CFRangeMake(0, 0), [UIBezierPath bezierPathWithRect:frame].CGPath, (__bridge_retained CFDictionaryRef)exclusionConfig);
                visibleRange = getRangeToDrawForVisibleString(frame4Cal);
                lastRange = getLastLineRange(frame4Cal, self.numberOfLines,visibleRange);
                visibleRange = getVisibleRangeFromLastRange(visibleRange, lastRange);
            }
        }
        DRAWCANCELEDWITHREALSE(frameSetter4Cal, frame4Cal)
        
        NSMutableSet * rangeSet = [NSMutableSet set];
        ///添加活跃文本属性方法
        if (needDrawString) {
            [self handleActiveTextWithStr:self.mAStr visibleRange:NSRangeFromCFRange(visibleRange) rangeSet:rangeSet];
        }
        
        DRAWCANCELEDWITHREALSE(frameSetter4Cal, frame4Cal)
        ///处理文本高亮状态并获取可见绘制文本范围
        if (needDrawString) {
            [self handleStringHighlightAttributesWithRangeSet:rangeSet visibleRange:visibleRange];
        }
        
        lastRange = getLastLineRange(frame4Cal, self.numberOfLines,visibleRange);
        visibleRange = getVisibleRangeFromLastRange(visibleRange, lastRange);
        ///处理句尾省略号
        DRAWCANCELEDWITHREALSE(frameSetter4Cal, frame4Cal)
        if (needDrawString) {
            [self handleLastLineTruncateWithLastLineRange:lastRange attributeString:self.mAStr];
        }
        
        /***************************/
        /*  至此富文本绘制配置处理完毕  */
        /***************************/
        

        DRAWCANCELED
        ///计算drawFrame及drawPath
        if (self.reCalculate) {
            self.drawPath = [self handleDrawFrameAndPathWithLimitWidth:limitWidth limitHeight:limitHeight frameSetter:frameSetter4Cal rangeToDraw:visibleRange exclusionPaths:exclusionPaths exclusionConfig:exclusionConfig];
        }
        
        CFSAFERELEASE(frameSetter4Cal)
        CFSAFERELEASE(frame4Cal)
        
        /**********************/
        /*  至此绘制区域处理完毕  */
        /**********************/
        
        DRAWCANCELED
        ///绘制的工厂
        CTFramesetterRef frameSetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)self.mAStr);
        ///绘制范围为可见范围加1，防止末尾省略号失效（由于path为可见尺寸，故仅绘制可见范围时有的时候末尾的省略号会失效，同时不可超过字符串本身长度）
        CFRange drawRange = CFRangeMake(0, visibleRange.length < self.mAStr.length ? visibleRange.length + 1 : self.mAStr.length);
        CTFrameRef visibleFrame = CTFramesetterCreateFrame(frameSetter, drawRange, self.drawPath.CGPath, (__bridge_retained CFDictionaryRef)exclusionConfig);
        
        DRAWCANCELEDWITHREALSE(frameSetter, visibleFrame)
        if (self.reCalculate && needDrawString) {
            ///计算活跃文本及插入图片的frame
            [self handleFrameForActiveTextAndInsertImageWithCTFrame:visibleFrame];
        }
        
        /**********************/
        /*  至此点击区域处理完毕  */
        /**********************/
        
        DRAWCANCELEDWITHREALSE(frameSetter, visibleFrame)
        
        NSMutableArray * imageArr = [NSMutableArray array];
        [imageArr addObjectsFromArray:self.pathImageArr];
        [imageArr addObjectsFromArray:self.insertImageArr];
        ///绘制图片
        [imageArr enumerateObjectsUsingBlock:^(NSDictionary * dic, NSUInteger idx, BOOL * _Nonnull stop) {
            UIImage * image = dic[@"image"];
            CGRect frame = convertRect([dic[@"frame"] CGRectValue],self.bounds.size.height);
            CGContextDrawImage(context, frame, image.CGImage);
        }];
        
        self.reCalculate = NO;
        self.reCheck = NO;
        self.finishFirstDraw = YES;
        ///绘制上下文
        CTFrameDraw(visibleFrame, context);
        
        /*******************/
        /*  至此绘制处理完毕  */
        /*******************/
        
        ///内存管理
        CFSAFERELEASE(visibleFrame)
        CFSAFERELEASE(frameSetter)
        CGContextRestoreGState(context);
    });
}

///处理绘制path
-(UIBezierPath *)handleDrawFrameAndPathWithLimitWidth:(CGFloat)limitWidth limitHeight:(CGFloat)limitHeight  frameSetter:(CTFramesetterRef)frameSetter rangeToDraw:(CFRange)rangeToDraw exclusionPaths:(NSArray * )exclusionPaths exclusionConfig:(NSDictionary *)exclusionConfig {
    
    ///获取排除区域配置字典
    CGRect frameR = CGRectMake(self.textInsets.left, self.textInsets.bottom, limitWidth, limitHeight);
    
    if (exclusionPaths.count == 0) {
        ///若无排除区域处理对其方式方式
        CGSize suggestSize = getSuggestSize(frameSetter, rangeToDraw, limitWidth, self.numberOfLines);
        [self handleAlignmentWithFrame:&frameR suggestSize:suggestSize limitWidth:limitWidth];
    } else {
        CTFrameRef frame4Cal = CTFramesetterCreateFrame(frameSetter, rangeToDraw, [UIBezierPath bezierPathWithRect:frameR].CGPath, (__bridge_retained CFDictionaryRef)exclusionConfig);
        frameR = getDrawFrame(frame4Cal, self.bounds.size.height,NO);
        frameR = convertRect(frameR, self.bounds.size.height);
        frameR = CGRectMake(frameR.origin.x, frameR.origin.y, limitWidth, MIN(frameR.size.height, limitHeight));
        CFSAFERELEASE(frame4Cal)
    }
    
    ///创建绘制区域
    return [UIBezierPath bezierPathWithRect:frameR];
}

///处理对齐方式
-(void)handleAlignmentWithFrame:(CGRect *)frame suggestSize:(CGSize)suggestSize limitWidth:(CGFloat)limitWidth {
    if ((*frame).size.height > suggestSize.height) {///垂直对齐方式处理
        (*frame).size = suggestSize;
        CGPoint origin = (*frame).origin;
        if (self.textVerticalAlignment == DWTextVerticalAlignmentCenter) {
            origin.y = self.bounds.size.height / 2.0 - suggestSize.height / 2.0;
        }
        else if (self.textVerticalAlignment == DWTextVerticalAlignmentTop)
        {
            origin.y = self.bounds.size.height - suggestSize.height - self.textInsets.top;
        }
        (*frame).origin = origin;
    }
    if ((*frame).size.width < limitWidth) {///水平对齐方式处理
        CGPoint origin = (*frame).origin;
        if (self.textAlignment == NSTextAlignmentCenter) {
            origin.x = self.bounds.size.width / 2.0 - (*frame).size.width / 2.0;
        } else if (self.textAlignment == NSTextAlignmentRight) {
            origin.x = self.bounds.size.width - (*frame).size.width - self.textInsets.right;
        }
        (*frame).origin = origin;
    }
}

#pragma mark --- 重绘行为处理 ---
///自动重绘
-(void)handleAutoRedrawWithRecalculate:(BOOL)reCalculate reCheck:(BOOL)reCheck {
    [self handleAutoRedrawWithRecalculate:reCalculate reCheck:reCheck reDraw:YES];
}

///按需重绘
-(void)handleAutoRedrawWithRecalculate:(BOOL)reCalculate reCheck:(BOOL)reCheck reDraw:(BOOL)reDraw {
    if (self.finishFirstDraw) {
        if (!self.reCalculate && reCalculate) {//防止计算需求被抵消
            self.reCalculate = YES;
        }
        if (!self.reCheck && reCheck) {//防止链接检测需求被抵消
            self.reCheck = YES;
        }
    }
    if (reDraw) {
        [self setNeedsDisplay];
    }
}

///文本变化相关处理
-(void)handleTextChange {
    self.mAStr = nil;
    [self.insertImageArr removeAllObjects];
    [self.textRangeArr removeAllObjects];
    [self.arrLocationImgHasAdd removeAllObjects];
    [self handleAutoRedrawWithRecalculate:YES reCheck:YES reDraw:self.autoRedraw];
}

///处理图片环绕数组，绘制前调用
-(void)handleImageExclusion {
    [self.imageExclusion removeAllObjects];
    [self.pathImageArr enumerateObjectsUsingBlock:^(NSDictionary * dic, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([dic[@"drawMode"] integerValue] == DWTextImageDrawModeSurround) {
            UIBezierPath * newPath = [dic[@"drawPath"] copy];
            [self.imageExclusion addObject:newPath];
        }
    }];
}

///处理子视图环绕数组
-(NSArray *)handleSubviewsExclusionPaths {
    NSMutableArray * arr = [NSMutableArray array];
    [self.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (_selectionView && [obj isEqual:_selectionView]) {
            return ;
        }
        UIBezierPath * path = [UIBezierPath bezierPathWithRect:obj.frame];
        [arr addObject:path];
    }];
    return arr;
}

///获取排除区域数组（不校正为图片绘制区域，校正为文字环绕区域）
-(NSArray *)handleExclusionPathsWithOffset:(CGFloat)offset {
    ///处理图片排除区域
    [self handleImageExclusion];
    
    ///获取全部排除区域
    NSMutableArray * exclusion = [NSMutableArray array];
    handleExclusionPathArr(exclusion, self.exclusionP, offset);
    handleExclusionPathArr(exclusion, self.imageExclusion, offset);
    
    NSUInteger countLimit = 0;
    if (_selectionView) {
        countLimit ++;
    }
    
    if (self.excludeSubviews && self.subviews.count > countLimit) {
        NSArray * subViewPath = [self handleSubviewsExclusionPaths];
        handleExclusionPathArr(exclusion, subViewPath, offset);
    }
    return exclusion;
}

#pragma mark --- 点击事件相关 ---
///将所有插入图片和活跃文本字典中的frame补全，重绘前调用
-(void)handleFrameForActiveTextAndInsertImageWithCTFrame:(CTFrameRef)frame {
    _layout = [DWCoreTextLayout layoutWithCTFrame:frame convertHeight:self.bounds.size.height considerGlyphs:YES];
    [_layout handleActiveImageAndTextWithCustomLinkRegex:self.customLinkRegex autoCheckLink:self.autoCheckLink];
}

///自动链接事件
-(void)autoLinkClicked:(NSDictionary *)userInfo {
    if (self.delegate && [self.delegate respondsToSelector:@selector(coreTextLabel:didSelectLink:range:linkType:)]) {
        [self.delegate coreTextLabel:self didSelectLink:userInfo[@"link"] range:[userInfo[@"range"] rangeValue] linkType:[userInfo[@"linkType"] integerValue]];
    }
}

///处理点击事件
-(void)handleClickWithDic:(NSDictionary *)dic {
    [self cancelTouch];
    id target = dic[@"target"];
    SEL selector = NSSelectorFromString(dic[@"SEL"]);
    NSMethodSignature  *signature = [[target class] instanceMethodSignatureForSelector:selector];
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
    invocation.target = target;
    invocation.selector = selector;
    if ([target isEqual:self]) {
        [invocation setArgument:&dic atIndex:2];
    }
    [invocation invoke];
}

-(void)cancelTouch {
    self.hasActionToDo = NO;
    self.highlightDic = nil;
}

///处理点击高亮
-(void)handleHighlightClickWithDic:(NSDictionary *)dic isLink:(BOOL)link {
    self.highlightDic = dic;
    if (!link && self.activeTextHighlightAttributes) {
        self.textClicked = YES;
        [self setNeedsDisplay];
        return;
    }
    if (link && (self.customLinkRegex.length || self.autoCheckLink)) {
        self.linkClicked = YES;
        [self setNeedsDisplay];
    }
}

///处理具有响应事件状态
-(NSDictionary *)handleHasActionStatusWithPoint:(CGPoint)point {
    self.hasActionToDo = NO;
    NSDictionary * dic = [self handleHasActionImageWithPoint:point];
    if (dic) {
        self.hasActionToDo = YES;
        return nil;
    }
    DWCTRunWrapper * run = [_layout runAtPoint:point];
    dic = run.activeAttributes;
    if (dic) {
        self.hasActionToDo = YES;
        return dic;
    }
    return nil;
}

///返回具有响应事件的图片配置字典
-(NSDictionary *)handleHasActionImageWithPoint:(CGPoint)point {
    NSMutableDictionary * dic = getImageDic(_layout.activeImageConfigs, point);
    if (!dic) {
        dic = getImageDic(self.pathImageArr, point);
    }
    return dic;
}

#pragma mark --- 处理选中事件 ---
-(NSRange)selectAtGlyphA:(DWGlyphWrapper *)gA glyphB:(DWGlyphWrapper *)gB {
    if (gA.index > gB.index) {
        DWSwapoAB(gA, gB);
    }
    NSArray * rects = [_layout selectedRectsBetweenLocationA:gA.index andLocationB:(gB.index + 1)];
    BOOL success = [self.selectionView updateSelectedRects:rects startGrabberPosition:gA.startPosition endGrabberPosition:gB.endPosition];
    if (success) {
        return NSMakeRange(gA.index, gB.index - gA.index + 1);
    }
    return NSRangeNull;
}

-(void)selectAtRange:(NSRange)range {
    if (NSEqualRanges(self.seletedRange, range)) {
        return;
    }
    DWGlyphWrapper * gA = [_layout glyphAtLocation:range.location];
    if (!gA) {
        return;
    }
    DWGlyphWrapper * gB = [_layout glyphAtLocation:NSMaxRange(range) - 1];
    if (!gB) {
        return;
    }
    if (gA.index > gB.index) {
        DWSwapoAB(gA, gB);
    }
    NSArray * rects = [_layout selectedRectsBetweenLocationA:gA.index andLocationB:(gB.index + 1)];
    BOOL success = [self.selectionView updateSelectedRects:rects startGrabberPosition:gA.startPosition endGrabberPosition:gB.endPosition];
    if (success) {
        self.seletedRange = NSMakeRange(gA.index, gB.index - gA.index + 1);
    } else {
        self.seletedRange = NSRangeNull;
    }
}

-(void)selectAll {
    [self selectAtRange:_layout.maxRange];
    [self showMenu];
}
-(void)cancelSelected {
    [_selectionView updateSelectedRects:nil startGrabberPosition:DWPositionZero endGrabberPosition:DWPositionZero];
    self.seletedRange = NSRangeNull;
    [self hideMenu];
}

-(void)showMenu {
    [_selectionView showSelectMenu];
}

-(void)hideMenu {
    [_selectionView hideSelectMenu];
}

#pragma mark --- 获取点击行为 ---
-(void)doubleClickAction:(UILongPressGestureRecognizer *)sender {
    CGPoint point = [sender locationInView:self];
    DWGlyphWrapper * glyph = [_layout glyphAtPoint:point];
    if (!glyph) {
        return;
    }
    [self selectAtRange:NSMakeRange(glyph.index, 1)];
    [self showMenu];
    if (NSEqualRanges(self.seletedRange, NSRangeNull)) {
        return;
    }
    [self cancelTouch];
    [self setNeedsDisplay];
    _selectingMode = YES;
    _selectGes.enabled = NO;
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    CGPoint point = [[touches anyObject] locationInView:self];
    if (!self.selectingMode) {
        NSDictionary * dic = [self handleHasActionStatusWithPoint:point];
        BOOL autoLink = [dic[@"link"] length];
        if (dic) {
            [self handleHighlightClickWithDic:dic isLink:autoLink];
            return;
        }
    } else {
        if (!NSEqualRanges(self.seletedRange, NSRangeNull)) {
            DWGlyphWrapper * g = [_layout glyphAtLocation:self.seletedRange.location];
            CGRect r = CGRectOffset(CGRectFromPosition(g.startPosition, 10), -5, 0);
            r = CGRectInset(r, 0, -5);
            if (CGRectContainsPoint(r, point)) {
                _grabbing = YES;
                _stableLoc = NSMaxRange(self.seletedRange);
            } else {
                g = [_layout glyphAtLocation:NSMaxRange(self.seletedRange) - 1];
                r = CGRectOffset(CGRectFromPosition(g.endPosition, 10), -5, 0);
                r = CGRectInset(r, 0, -5);
                if (CGRectContainsPoint(r, point)) {
                    _grabbing = YES;
                    _stableLoc = self.seletedRange.location;
                }
            }
            if (!_grabbing) {///拖动开始
                [self cancelSelected];
            }
            return;
        }
    }
    [super touchesBegan:touches withEvent:event];
}

-(void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    CGPoint point = [[touches anyObject] locationInView:self];
    if (!self.selectingMode) {
        if (self.hasActionToDo) {
            NSDictionary * dic = [self handleHasActionStatusWithPoint:point];
            if (!self.hasActionToDo || ![self.highlightDic isEqualToDictionary:dic]) {
                if (self.textClicked) {
                    self.textClicked = NO;
                    self.highlightDic = nil;
                    [self setNeedsDisplay];
                } else if (self.linkClicked) {
                    self.linkClicked = NO;
                    self.highlightDic = nil;
                    [self setNeedsDisplay];
                }
            }
            return;
        }
    } else {
        if (_grabbing) {
            NSUInteger loc = [_layout closestLocFromPoint:point];
            NSRange r = NSMakeRangeBetweenLocation(loc, self.stableLoc);
            [self selectAtRange:r];
            return;
        }
    }
    
    [super touchesMoved:touches withEvent:event];
}

-(void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if (!self.selectingMode) {
        if (self.hasActionToDo) {
            CGPoint point = [[touches anyObject] locationInView:self];
            NSDictionary * dic = [self handleHasActionImageWithPoint:point];
            if (dic) {
                [self handleClickWithDic:dic];
                return;
            }
            dic = self.highlightDic;
            if (dic) {
                if (self.textClicked) {
                    self.textClicked = NO;
                    [self setNeedsDisplay];
                } else if (self.linkClicked) {
                    self.linkClicked = NO;
                    [self setNeedsDisplay];
                }
                [self handleClickWithDic:dic];
                return;
            }
        }
    } else {
        if (_grabbing) {
            _grabbing = NO;
            [self showMenu];
        } else {
            _selectingMode = NO;
            _selectGes.enabled = YES;
        }
        return;
    }
    [super touchesEnded:touches withEvent:event];
}

#pragma mark ---CTRun 代理---
static CGFloat ascentCallBacks(void * ref) {
    NSDictionary * dic = (__bridge NSDictionary *)ref;
    CGSize size = [dic[@"size"] CGSizeValue];
    CGFloat descent = [dic[@"descent"] floatValue];
    return size.height - descent;
}

static CGFloat descentCallBacks(void * ref) {
    NSDictionary * dic = (__bridge NSDictionary *)ref;
    CGFloat descent = [dic[@"descent"] floatValue];
    return descent;
}

static CGFloat widthCallBacks(void * ref) {
    NSDictionary * dic = (__bridge NSDictionary *)ref;
    CGSize size = [dic[@"size"] CGSizeValue];
    return size.width;
}

#pragma mark ---method override---

+(Class)layerClass {
    return [DWAsyncLayer class];
}

-(instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _lineSpacing = - 65536;
        _lineBreakMode = NSLineBreakByCharWrapping;
        _reCalculate = YES;
        _reCheck = YES;
        _excludeSubviews = YES;
        _allowSelect = YES;
        _seletedRange = NSRangeNull;
        self.backgroundColor = [UIColor clearColor];
        DWAsyncLayer * layer = (DWAsyncLayer *)self.layer;
        layer.contentsScale = [UIScreen mainScreen].scale;
        __weak typeof(self)weakSelf = self;
        layer.displayBlock = ^(CGContextRef context,BOOL(^isCanceled)(void)){
            [weakSelf drawTheTextWithContext:context isCanceled:isCanceled];
        };
        UITapGestureRecognizer * doubleClick = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleClickAction:)];
        doubleClick.numberOfTapsRequired = 2;
        _selectGes = doubleClick;
        [self addGestureRecognizer:doubleClick];
    }
    return self;
}

-(void)setNeedsDisplay {
    [super setNeedsDisplay];
    [self.layer setNeedsDisplay];
}

-(void)sizeToFit {
    CGRect frame = self.frame;
    frame.size = [self sizeThatFits:CGSizeMake(self.bounds.size.width, 10000)];
    self.frame = frame;
}

-(CGSize)sizeThatFits:(CGSize)size {
    ///计算绘制尺寸限制
    CGFloat limitWidth = (size.width - self.textInsets.left - self.textInsets.right) > 0 ? (size.width - self.textInsets.left - self.textInsets.right) : 0;
    CGFloat limitHeight = (size.height - self.textInsets.top - self.textInsets.bottom) > 0 ? (size.height - self.textInsets.top - self.textInsets.bottom) : 0;
    
    ///获取排除区域（考虑偏移矫正，保证正确绘制）
    NSArray * exclusionPaths = [self handleExclusionPathsWithOffset:self.textInsets.bottom - self.textInsets.top];
    CGRect frame = CGRectMake(self.textInsets.left, self.textInsets.bottom, limitWidth, limitHeight);
    NSDictionary * exclusionConfig = getExclusionDic(exclusionPaths, frame);
    BOOL needDrawString = self.attributedText.length || self.text.length;
    
    NSMutableAttributedString * mAStr = nil;
    if (needDrawString) {
        ///获取要绘制的文本(初步处理，未处理插入图片、句尾省略号、高亮)
        mAStr = getMAStr(self,limitWidth,exclusionPaths);
    }
    CTFramesetterRef frameSetter4Cal = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)mAStr);
    CTFrameRef frame4Cal = CTFramesetterCreateFrame(frameSetter4Cal, CFRangeMake(0, 0), [UIBezierPath bezierPathWithRect:frame].CGPath, (__bridge_retained CFDictionaryRef)exclusionConfig);
    
    CFRange visibleRange = getRangeToDrawForVisibleString(frame4Cal);
    
    ///处理插入图片
    if (needDrawString) {
        NSMutableArray * arrInsert = self.insertImageArr.copy;
        if (arrInsert.count) {
            ///富文本插入图片占位符
            [self handleStr:mAStr withInsertImageArr:arrInsert arrLocationImgHasAdd:[NSMutableArray array]];
            ///插入图片后重新处理工厂及frame，添加插入图片后的字符串，消除插入图片影响
            CFSAFERELEASE(frameSetter4Cal)
            CFSAFERELEASE(frame4Cal)
            frameSetter4Cal = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)mAStr);
            frame4Cal = CTFramesetterCreateFrame(frameSetter4Cal, CFRangeMake(0, 0), [UIBezierPath bezierPathWithRect:frame].CGPath, (__bridge_retained CFDictionaryRef)exclusionConfig);
            visibleRange = getRangeToDrawForVisibleString(frame4Cal);
        }
    }
    
    if (exclusionPaths.count == 0) {///如果没有排除区域则使用系统计算函数
        CGSize restrictSize = CGSizeMake(limitWidth, MAXFLOAT);
        if (self.numberOfLines == 1) {
            restrictSize = CGSizeMake(MAXFLOAT, MAXFLOAT);
        }
        CGSize suggestSize = CTFramesetterSuggestFrameSizeWithConstraints(frameSetter4Cal, visibleRange, nil, restrictSize, nil);
        CFSAFERELEASE(frameSetter4Cal);
        CFSAFERELEASE(frame4Cal);
        return CGSizeMake(suggestSize.width + self.textInsets.left + self.textInsets.right, suggestSize.height + self.textInsets.top + self.textInsets.bottom);
    }
    
    ///计算drawFrame及drawPath
    UIBezierPath * drawP = [self handleDrawFrameAndPathWithLimitWidth:limitWidth limitHeight:limitHeight frameSetter:frameSetter4Cal rangeToDraw:visibleRange exclusionPaths:exclusionPaths exclusionConfig:exclusionConfig];
    
    CFSAFERELEASE(frameSetter4Cal)
    CFSAFERELEASE(frame4Cal)
    
    ///绘制的工厂
    CTFramesetterRef frameSetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)mAStr);
    ///绘制范围为可见范围加1，防止末尾省略号失效（由于path为可见尺寸，故仅绘制可见范围时有的时候末尾的省略号会失效，同时不可超过字符串本身长度）
    CFRange drawRange = CFRangeMake(0, visibleRange.length < mAStr.length ? visibleRange.length + 1 : mAStr.length);
    CTFrameRef visibleFrame = CTFramesetterCreateFrame(frameSetter, drawRange, drawP.CGPath, (__bridge_retained CFDictionaryRef)exclusionConfig);
    
    __block CGRect desFrame = getDrawFrame(visibleFrame,size.height,YES);
    CFSAFERELEASE(frameSetter)
    CFSAFERELEASE(visibleFrame)
    
    desFrame = CGRectMake(0, 0, ceil(desFrame.origin.x + desFrame.size.width + self.textInsets.right), ceil(desFrame.origin.y + desFrame.size.height + self.textInsets.bottom));
    
    ///重新获取为矫正偏移的图片实际绘制Path
    exclusionPaths = [self handleExclusionPathsWithOffset:0];
    [exclusionPaths enumerateObjectsUsingBlock:^(UIBezierPath * obj, NSUInteger idx, BOOL * _Nonnull stop) {
        desFrame = CGRectUnion(obj.bounds, desFrame);
    }];
    
    CGRect limitRect = CGRectMake(0, 0, size.width, size.height);
    desFrame = CGRectIntersection(limitRect, desFrame);
    return desFrame.size;
}

-(void)setFrame:(CGRect)frame {
    if (!CGRectEqualToRect(self.frame, frame)) {
        [super setFrame:frame];
        if (_selectionView) {
            _selectionView.frame = self.bounds;
        }
        [self handleAutoRedrawWithRecalculate:YES reCheck:NO reDraw:self.autoRedraw];
    }
}

#pragma mark ---setter、getter---
-(void)setText:(NSString *)text {
    if (![_text isEqualToString:text]) {
        _text = text;
        [self handleTextChange];
    }
}

-(void)setTextAlignment:(NSTextAlignment)textAlignment {
    if ((self.exclusionPaths.count == 0) && (_textAlignment != textAlignment)) {
        _textAlignment = textAlignment;
        [self handleAutoRedrawWithRecalculate:YES reCheck:NO reDraw:self.autoRedraw];
    }
}

-(void)setTextVerticalAlignment:(DWTextVerticalAlignment)textVerticalAlignment {
    if ((self.exclusionPaths.count == 0) && (_textVerticalAlignment != textVerticalAlignment)) {
        _textVerticalAlignment = textVerticalAlignment;
        [self handleAutoRedrawWithRecalculate:YES reCheck:NO reDraw:self.autoRedraw];
    }
}

-(UIFont *)font {
    if (!_font) {
        _font = [UIFont systemFontOfSize:17];
    }
    return _font;
}

-(void)setFont:(UIFont *)font {
    _font = font;
    [self handleAutoRedrawWithRecalculate:YES reCheck:NO reDraw:self.autoRedraw];
}

-(void)setTextInsets:(UIEdgeInsets)textInsets {
    if (!UIEdgeInsetsEqualToEdgeInsets(_textInsets, textInsets)) {
        _textInsets = textInsets;
        [self handleAutoRedrawWithRecalculate:YES reCheck:NO reDraw:self.autoRedraw];
    }
}

-(void)setAttributedText:(NSAttributedString *)attributedText {
    if (![_attributedText isEqualToAttributedString:attributedText]) {
        _attributedText = attributedText;
        [self handleTextChange];
    }
}

-(void)setTextColor:(UIColor *)textColor {
    if (!CGColorEqualToColor(_textColor.CGColor,textColor.CGColor)) {
        _textColor = textColor;
        [self handleAutoRedrawWithRecalculate:NO reCheck:NO reDraw:self.autoRedraw];
    }
}

-(UIColor *)textColor {
    if (!_textColor) {
        _textColor = [UIColor blackColor];
    }
    return _textColor;
}

-(void)setLineSpacing:(CGFloat)lineSpacing {
    if (_lineSpacing != lineSpacing) {
        _lineSpacing = lineSpacing;
        [self handleAutoRedrawWithRecalculate:YES reCheck:NO reDraw:self.autoRedraw];
    }
}

-(CGFloat)lineSpacing {
    if (_lineSpacing == -65536) {
        return 5.5;
    }
    return _lineSpacing;
}

-(NSArray<UIBezierPath *> *)exclusionPaths {
    if (!_exclusionPaths) {
        _exclusionPaths = [NSArray array];
    }
    return _exclusionPaths;
}

-(void)setExclusionPaths:(NSArray<UIBezierPath *> *)exclusionPaths {
    _exclusionPaths = exclusionPaths;
    [self handleAutoRedrawWithRecalculate:YES reCheck:NO reDraw:self.autoRedraw];
}

-(void)setExcludeSubviews:(BOOL)excludeSubviews {
    if (_excludeSubviews != excludeSubviews) {
        _excludeSubviews = excludeSubviews;
        [self handleAutoRedrawWithRecalculate:YES reCheck:NO reDraw:self.autoRedraw];
    }
}

-(void)setNumberOfLines:(NSUInteger)numberOfLines {
    if (_numberOfLines != numberOfLines) {
        _numberOfLines = numberOfLines;
        [self handleAutoRedrawWithRecalculate:YES reCheck:NO reDraw:self.autoRedraw];
    }
}

-(void)setLineBreakMode:(NSLineBreakMode)lineBreakMode {
    if (_lineBreakMode != lineBreakMode) {
        _lineBreakMode = lineBreakMode;
        [self handleAutoRedrawWithRecalculate:YES reCheck:YES reDraw:self.autoRedraw];
    }
}

-(void)setAutoCheckLink:(BOOL)autoCheckLink {
    if (_autoCheckLink != autoCheckLink) {
        _autoCheckLink = autoCheckLink;
        self.reCalculate = YES;
        self.reCheck = YES;
        [self setNeedsDisplay];
    }
}

-(void)setAutoCheckConfig:(NSMutableDictionary *)autoCheckConfig {
    _autoCheckConfig = autoCheckConfig;
    if (self.autoCheckLink) {
        [self handleAutoRedrawWithRecalculate:YES reCheck:YES reDraw:self.autoRedraw];
    }
}

-(NSMutableDictionary *)autoCheckConfig {
    return self.autoCheckLink?(_autoCheckConfig?_autoCheckConfig:[NSMutableDictionary dictionaryWithDictionary:@{@"phoneNo":@"(1[34578]\\d{9}|(0[\\d]{2,3}-)?([2-9][\\d]{6,7})(-[\\d]{1,4})?)",@"email":@"[A-Za-z\\d]+([-_.][A-Za-z\\d]+)*@([A-Za-z\\d]+[-.])*([A-Za-z\\d]+[.])+[A-Za-z\\d]{2,5}",@"URL":@"((http|ftp|https)://)?((([a-zA-Z0-9]+[a-zA-Z0-9_-]*\\.)+[a-zA-Z]{2,6})|(([0-9]{1,3}\\.){3}[0-9]{1,3}(:[0-9]{1,4})?))((/[a-zA-Z\\d_]+)*(\\?([a-zA-Z\\d_]+=[a-zA-Z\\d\\u4E00-\\u9FA5\\s\\+%#_-]+&)*([a-zA-Z\\d_]+=[a-zA-Z\\d\\u4E00-\\u9FA5\\s\\+%#_-]+))?)?",@"naturalNum":@"\\d+(\\.\\d+)?"}]):nil;
}

-(void)setCustomLinkRegex:(NSString *)customLinkRegex {
    if (![_customLinkRegex isEqualToString:customLinkRegex]) {
        _customLinkRegex = customLinkRegex;
        [self handleAutoRedrawWithRecalculate:YES reCheck:YES reDraw:self.autoRedraw];
    }
}

-(void)setAllowSelect:(BOOL)allowSelect {
    if (_allowSelect != allowSelect) {
        _allowSelect = allowSelect;
        _selectGes.enabled = allowSelect;
    }
}

-(DWCoreTextSelectionView *)selectionView {
    if (!_selectionView) {
        _selectionView = [[DWCoreTextSelectionView alloc] initWithFrame:self.bounds];
        _selectionView.selectAction = DWSelectActionCopy | DWSelectActionSelectAll;
        __weak typeof(self)weakSelf = self;
        _selectionView.selectActionCallBack = ^(DWSelectAction action) {
            if (action & DWSelectActionCopy) {
                [UIPasteboard generalPasteboard].string = [weakSelf.mAStr.string substringWithRange:weakSelf.seletedRange];
            } else if (action & DWSelectActionSelectAll) {
                [weakSelf selectAll];
            }
        };
        [self addSubview:_selectionView];
    }
    return _selectionView;
}
#pragma mark ---链接属性setter、getter---
-(void)setActiveTextAttributes:(NSDictionary *)activeTextAttributes {
    _activeTextAttributes = activeTextAttributes;
    [self handleAutoRedrawWithRecalculate:YES reCheck:NO reDraw:self.autoRedraw];
}

-(void)setActiveTextHighlightAttributes:(NSDictionary *)activeTextHighlightAttributes {
    _activeTextHighlightAttributes = activeTextHighlightAttributes;
    [self handleAutoRedrawWithRecalculate:YES reCheck:NO reDraw:self.autoRedraw];
}

-(void)setNaturalNumAttributes:(NSDictionary *)naturalNumAttributes {
    _naturalNumAttributes = naturalNumAttributes;
    if (self.autoCheckLink) {
        [self handleAutoRedrawWithRecalculate:YES reCheck:NO reDraw:self.autoRedraw];
    }
}

-(NSDictionary *)naturalNumAttributes {
    return self.autoCheckLink?(_naturalNumAttributes?_naturalNumAttributes:DWDefaultAttributes):nil;
}

-(void)setNaturalNumHighlightAttributes:(NSDictionary *)naturalNumHighlightAttributes {
    _naturalNumHighlightAttributes = naturalNumHighlightAttributes;
    if (self.autoCheckLink) {
        [self handleAutoRedrawWithRecalculate:YES reCheck:NO reDraw:self.autoRedraw];
    }
}

-(NSDictionary *)naturalNumHighlightAttributes {
    return self.autoCheckLink?(_naturalNumHighlightAttributes?_naturalNumHighlightAttributes:DWDefaultHighlightAttributes):nil;
}

-(void)setPhoneNoAttributes:(NSDictionary *)phoneNoAttributes {
    _phoneNoAttributes = phoneNoAttributes;
    if (self.autoCheckLink) {
        [self handleAutoRedrawWithRecalculate:YES reCheck:NO reDraw:self.autoRedraw];
    }
}

-(NSDictionary *)phoneNoAttributes {
    return self.autoCheckLink?(_phoneNoAttributes?_phoneNoAttributes:DWDefaultAttributes):nil;
}

-(void)setPhoneNoHighlightAttributes:(NSDictionary *)phoneNoHighlightAttributes {
    _phoneNoHighlightAttributes = phoneNoHighlightAttributes;
    if (self.autoCheckLink) {
        [self handleAutoRedrawWithRecalculate:YES reCheck:NO reDraw:self.autoRedraw];
    }
}

-(NSDictionary *)phoneNoHighlightAttributes {
    return self.autoCheckLink?(_phoneNoHighlightAttributes?_phoneNoHighlightAttributes:DWDefaultHighlightAttributes):nil;
}

-(void)setURLAttributes:(NSDictionary *)URLAttributes {
    _URLAttributes = URLAttributes;
    if (self.autoCheckLink) {
        [self handleAutoRedrawWithRecalculate:YES reCheck:NO reDraw:self.autoRedraw];
    }
}

-(NSDictionary *)URLAttributes {
    return self.autoCheckLink?(_URLAttributes?_URLAttributes:DWDefaultAttributes):nil;
}

-(void)setURLHighlightAttributes:(NSDictionary *)URLHighlightAttributes {
    _URLHighlightAttributes = URLHighlightAttributes;
    if (self.autoCheckLink) {
        [self handleAutoRedrawWithRecalculate:YES reCheck:NO reDraw:self.autoRedraw];
    }
}

-(NSDictionary *)URLHighlightAttributes {
    return self.autoCheckLink?(_URLHighlightAttributes?_URLHighlightAttributes:DWDefaultHighlightAttributes):nil;
}


-(void)setEmailAttributes:(NSDictionary *)emailAttributes {
    _emailAttributes = emailAttributes;
    if (self.autoCheckLink) {
        [self handleAutoRedrawWithRecalculate:YES reCheck:NO reDraw:self.autoRedraw];
    }
}

-(NSDictionary *)emailAttributes {
    return self.autoCheckLink?(_emailAttributes?_emailAttributes:DWDefaultAttributes):nil;
}

-(void)setEmailHighlightAttributes:(NSDictionary *)emailHighlightAttributes {
    _emailHighlightAttributes = emailHighlightAttributes;
    if (self.autoCheckLink) {
        [self handleAutoRedrawWithRecalculate:YES reCheck:NO reDraw:self.autoRedraw];
    }
}

-(NSDictionary *)emailHighlightAttributes {
    return self.autoCheckLink?(_emailHighlightAttributes?_emailHighlightAttributes:DWDefaultHighlightAttributes):nil;
}

-(void)setCustomLinkAttributes:(NSDictionary *)customLinkAttributes {
    _customLinkAttributes = customLinkAttributes;
    [self handleAutoRedrawWithRecalculate:YES reCheck:NO reDraw:self.autoRedraw];
}

-(NSDictionary *)customLinkAttributes {
    return (self.customLinkRegex.length > 0)?(_customLinkAttributes?_customLinkAttributes:DWDefaultAttributes):nil;
}

-(void)setCustomLinkHighlightAttributes:(NSDictionary *)customLinkHighlightAttributes {
    _customLinkHighlightAttributes = customLinkHighlightAttributes;
    [self handleAutoRedrawWithRecalculate:YES reCheck:NO reDraw:self.autoRedraw];
}

-(NSDictionary *)customLinkHighlightAttributes {
    return (self.customLinkRegex.length > 0)?(_customLinkHighlightAttributes?_customLinkHighlightAttributes:DWDefaultHighlightAttributes):nil;
}

-(dispatch_queue_t)syncQueue {
    if (!_syncQueue) {
        _syncQueue = dispatch_queue_create("com.syncQueue.DWCoreTextLabel", DISPATCH_QUEUE_CONCURRENT);
    }
    return _syncQueue;
}

#pragma mark ---中间容器属性setter、getter---
-(NSMutableArray *)pathImageArr {
    if (!_pathImageArr) {
        _pathImageArr = [NSMutableArray array];
    }
    return _pathImageArr;
}

-(NSMutableArray *)insertImageArr {
    if (!_insertImageArr) {
        _insertImageArr = [NSMutableArray array];
    }
    return _insertImageArr;
}
    
-(NSMutableDictionary<NSString *,NSMutableArray *> *)placeHolderDic {
    if (!_placeHolderDic) {
        _placeHolderDic = [NSMutableDictionary dictionary];
    }
    return _placeHolderDic;
}

-(NSMutableArray *)imageExclusion
{
    if (!_imageExclusion) {
        _imageExclusion = [NSMutableArray array];
    }
    return _imageExclusion;
}

-(NSMutableArray *)arrLocationImgHasAdd
{
    if (!_arrLocationImgHasAdd) {
        _arrLocationImgHasAdd = [NSMutableArray array];
    }
    return _arrLocationImgHasAdd;
}

-(NSMutableArray *)textRangeArr
{
    if (!_textRangeArr) {
        _textRangeArr = [NSMutableArray array];
    }
    return _textRangeArr;
}

-(NSMutableArray *)exclusionP
{
    return [[NSMutableArray alloc] initWithArray:self.exclusionPaths copyItems:YES];
}


-(NSMutableDictionary *)autoCheckLinkDic
{
    if (!_autoCheckLinkDic) {
        _autoCheckLinkDic = [NSMutableDictionary dictionary];
    }
    return _autoCheckLinkDic;
}

-(NSMutableDictionary *)customLinkDic
{
    if (!_customLinkDic) {
        _customLinkDic = [NSMutableDictionary dictionary];
    }
    return _customLinkDic;
}

@end
