
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

#define CFSAFERELEASE(a)\
do {\
if(a != NULL) {\
CFRelease(a);\
}\
} while(0)

@interface DWCoreTextLabel ()

///绘制文本
@property (nonatomic ,strong) NSMutableAttributedString * mAStr;

///绘制图片数组
@property (nonatomic ,strong) NSMutableArray * imageArr;

///活跃文本数组
@property (nonatomic ,strong) NSMutableArray * activeTextArr;

///自动链接数组
@property (nonatomic ,strong) NSMutableArray * autoLinkArr;

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

///具有响应事件
@property (nonatomic ,assign) BOOL hasActionToDo;

///高亮范围字典
@property (nonatomic ,strong) NSMutableDictionary * highlightDic;

///重新计算
@property (nonatomic ,assign) BOOL reCalculate;

///绘制尺寸
@property (nonatomic ,assign) CGRect drawFrame;

///绘制范围
@property (nonatomic ,strong) UIBezierPath * drawPath;

///适应尺寸
@property (nonatomic ,assign) CGSize suggestSize;

///首次绘制
@property (nonatomic ,assign) BOOL finishFirstDraw;

///自动链接检测结果字典
@property (nonatomic ,strong) NSMutableDictionary * autoCheckLinkDic;

///自定制链接检测结果字典
@property (nonatomic ,strong) NSMutableDictionary * customLinkDic;

///重新自动检测
@property (nonatomic ,assign) BOOL reCheck;

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

#pragma mark ---接口方法---

///以指定模式绘制图片
-(void)dw_DrawImage:(UIImage *)image atFrame:(CGRect)frame margin:(CGFloat)margin drawMode:(DWTextImageDrawMode)mode target:(id)target selector:(SEL)selector
{
    if (!image) {
        return;
    }
    if (CGRectEqualToRect(frame, CGRectZero)) {
        return;
    }
    CGRect drawFrame = CGRectInset(frame, margin, margin);
    UIBezierPath * drawPath = [UIBezierPath bezierPathWithRect:frame];
    UIBezierPath * activePath = getImageAcitvePath(drawPath,margin);
    NSMutableDictionary * dic = [NSMutableDictionary dictionaryWithDictionary:@{@"image":image,@"drawPath":drawPath,@"activePath":activePath,@"frame":[NSValue valueWithCGRect:drawFrame],@"margin":@(margin),@"drawMode":@(mode)}];
    if (target && selector) {
        [dic setValue:target forKey:@"target"];
        [dic setValue:NSStringFromSelector(selector) forKey:@"SEL"];
    }
    [self.imageArr addObject:dic];
    [self handleAutoRedrawWithRecalculate:YES reCheck:NO];
}

-(void)dw_DrawImageWithUrl:(NSString *)url atFrame:(CGRect)frame margin:(CGFloat)margin drawMode:(DWTextImageDrawMode)mode target:(id)target selector:(SEL)selector
{
    [[DWWebImageManager shareManager] downloadImageWithUrl:url completion:^(UIImage *image) {
        [self dw_DrawImage:image atFrame:frame margin:margin drawMode:mode target:target selector:selector];
    }];
}

///以路径绘制图片
-(void)dw_DrawImage:(UIImage *)image WithPath:(UIBezierPath *)path margin:(CGFloat)margin drawMode:(DWTextImageDrawMode)mode target:(id)target selector:(SEL)selector
{
    if (!image) {
        return;
    }
    if (!path) {
        return;
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
    [self.imageArr addObject:dic];
    [self handleAutoRedrawWithRecalculate:YES reCheck:NO];
}

-(void)dw_DrawImageWithUrl:(NSString *)url WithPath:(UIBezierPath *)path margin:(CGFloat)margin drawMode:(DWTextImageDrawMode)mode target:(id)target selector:(SEL)selector
{
    [[DWWebImageManager shareManager] downloadImageWithUrl:url completion:^(UIImage *image) {
        [self dw_DrawImage:image WithPath:path margin:margin drawMode:mode target:target selector:selector];
    }];
}

///在字符串指定位置插入图片
-(void)dw_InsertImage:(UIImage *)image size:(CGSize)size padding:(CGFloat)padding descent:(CGFloat)descent atLocation:(NSUInteger)location target:(id)target selector:(SEL)selector
{
    if (!image) {
        return;
    }
    if (padding != 0) {
        size = CGSizeMake(size.width + padding * 2, size.height);
    }
    NSMutableDictionary * dic = [NSMutableDictionary dictionaryWithDictionary:@{@"image":image,@"size":[NSValue valueWithCGSize:size],@"padding":@(padding),@"location":@(location),@"descent":@(descent),@"drawMode":@(DWTextImageDrawModeInsert)}];
    if (target && selector) {
        [dic setValue:target forKey:@"target"];
        [dic setValue:NSStringFromSelector(selector) forKey:@"SEL"];
    }
    [self.imageArr addObject:dic];
    [self handleAutoRedrawWithRecalculate:YES reCheck:YES];
}

-(void)dw_InsertImageWithUrl:(NSString *)url size:(CGSize)size padding:(CGFloat)padding descent:(CGFloat)descent atLocation:(NSUInteger)location target:(id)target selector:(SEL)selector
{
    [[DWWebImageManager shareManager] downloadImageWithUrl:url completion:^(UIImage *image) {
        [self dw_InsertImage:image size:size padding:padding descent:descent atLocation:location target:target selector:selector];
    }];
}

///给指定范围添加响应事件
-(void)dw_AddTarget:(id)target selector:(SEL)selector toRange:(NSRange)range
{
    if (target && selector && range.length > 0) {
        NSMutableDictionary * dic = [NSMutableDictionary dictionaryWithDictionary:@{@"target":target,@"SEL":NSStringFromSelector(selector),@"range":[NSValue valueWithRange:range]}];
        [self.textRangeArr addObject:dic];
        [self handleAutoRedrawWithRecalculate:YES reCheck:YES];
    }
}

///返回指定路径的图片
+(UIImage *)dw_ClipImage:(UIImage *)image withPath:(UIBezierPath *)path mode:(DWImageClipMode)mode
{
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

+(void)dw_ClipImageWithUrl:(NSString *)url withPath:(UIBezierPath *)path mode:(DWImageClipMode)mode completion:(void(^)(UIImage * image))completion
{
    [[DWWebImageManager shareManager] downloadImageWithUrl:url completion:^(UIImage *image) {
        image = [DWCoreTextLabel dw_ClipImage:image withPath:path mode:mode];
        completion(image);
    }];
}

#pragma mark ---插入图片相关---

///将所有插入图片插入字符串
-(void)handleStr:(NSMutableAttributedString *)str withInsertImageArr:(NSMutableArray *)arr
{
    [self.arrLocationImgHasAdd removeAllObjects];
    [arr enumerateObjectsUsingBlock:^(NSMutableDictionary * dic, NSUInteger idx, BOOL * _Nonnull stop) {
        handleInsertPic(self,dic,str);
    }];
}

///将图片设置代理后插入富文本
static inline void handleInsertPic(DWCoreTextLabel * label,NSMutableDictionary * dic,NSMutableAttributedString * str)
{
    NSInteger location = [dic[@"location"] integerValue];
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
    NSInteger offset = getInsertOffset(label,location);
    [str insertAttributedString:placeHolderAttrStr atIndex:location + offset];
}

#pragma mark ---文本相关---

///处理对齐方式
-(void)handleAlignmentWithFrame:(CGRect *)frame
                    suggestSize:(CGSize)suggestSize
                     limitWidth:(CGFloat)limitWidth
{
    if ((self.exclusionPaths.count + self.imageExclusion.count) == 0) {///若无排除区域按对齐方式处理
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
            }
            else if (self.textAlignment == NSTextAlignmentRight)
            {
                origin.x = self.bounds.size.width - (*frame).size.width - self.textInsets.right;
            }
            (*frame).origin = origin;
        }
    }
}

///添加活跃文本属性方法
-(void)handleActiveTextWithStr:(NSMutableAttributedString *)str rangeSet:(NSMutableSet *)rangeSet withImage:(BOOL)withImage
{
    [self.textRangeArr enumerateObjectsUsingBlock:^(NSMutableDictionary * dic  , NSUInteger idx, BOOL * _Nonnull stop) {
        NSRange range = [dic[@"range"] rangeValue];
        if (withImage) {
            range = handleRangeOffset(range,self.arrLocationImgHasAdd);
        }
        [rangeSet addObject:[NSValue valueWithRange:range]];
        [str addAttribute:@"clickAttribute" value:dic range:range];
        if (self.textClicked && self.highlightDic) {
            if (NSEqualRanges([dic[@"range"] rangeValue], [self.highlightDic[@"range"] rangeValue])) {
                [str addAttributes:self.activeTextHighlightAttributes range:range];
            }
            else
            {
                if (self.activeTextAttributes) {
                    [str addAttributes:self.activeTextAttributes range:range];
                }
            }
        }
        else
        {
            if (self.activeTextAttributes) {
                [str addAttributes:self.activeTextAttributes range:range];
            }
        }
    }];
}

///矫正range偏移量
static inline NSRange handleRangeOffset(NSRange range,NSMutableArray * arrLocationImgHasAdd)
{
    __block NSRange newRange = range;
    [arrLocationImgHasAdd enumerateObjectsUsingBlock:^(NSNumber * location, NSUInteger idx, BOOL * _Nonnull stop) {
        if (location.integerValue <= range.location) {
            newRange.location ++;
        }
        else if (location.integerValue <= (range.location + range.length - 1)){
            newRange.length ++;
        }
    }];
    return newRange;
}

#pragma mark ---自动检测链接相关---
///自动检测链接方法
-(void)handleAutoCheckLinkWithStr:(NSMutableAttributedString *)str linkRange:(NSRange)linkRange rangeSet:(NSMutableSet *)rangeSet
{
    [self handleAutoCheckWithLinkType:DWLinkTypeEmail str:str linkRange:linkRange rangeSet:rangeSet linkDic:self.autoCheckLinkDic attributeName:@"autoCheckLink"];
    [self handleAutoCheckWithLinkType:DWLinkTypeURL str:str linkRange:linkRange rangeSet:rangeSet linkDic:self.autoCheckLinkDic attributeName:@"autoCheckLink"];
    [self handleAutoCheckWithLinkType:DWLinkTypePhoneNo str:str linkRange:linkRange rangeSet:rangeSet linkDic:self.autoCheckLinkDic attributeName:@"autoCheckLink"];
    [self handleAutoCheckWithLinkType:DWLinkTypeNaturalNum str:str linkRange:linkRange rangeSet:rangeSet linkDic:self.autoCheckLinkDic attributeName:@"autoCheckLink"];
}

///根据类型处理自动链接
-(void)handleAutoCheckWithLinkType:(DWLinkType)linkType str:(NSMutableAttributedString *)str linkRange:(NSRange)linkRange rangeSet:(NSMutableSet *)rangeSet linkDic:(NSMutableDictionary *)linkDic attributeName:(NSString *)attributeName
{
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
        }
        else
        {
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
                }
                else
                {
                    if (tempAttributesDic) {
                        [str addAttributes:tempAttributesDic range:range];
                    }
                }
            }
            else
            {
                if (tempAttributesDic) {
                    [str addAttributes:tempAttributesDic range:range];
                }
            }
        }];
    }
}

///处理文本高亮状态
-(NSRange)handleStringHighlightAttributesWithRangeSet:(NSMutableSet *)rangeSet
{
    NSRange linkRange = getRangeToDrawForVisibleString(self);
    [self handleAutoCheckWithLinkType:DWLinkTypeCustom str:self.mAStr linkRange:linkRange rangeSet:rangeSet linkDic:self.customLinkDic attributeName:@"customLink"];
    ///处理自动检测链接
    if (self.autoCheckLink) {
        [self handleAutoCheckLinkWithStr:self.mAStr linkRange:linkRange rangeSet:rangeSet];
    }
    return linkRange;
}

///处理匹配结果中重复范围
static inline void hanldeReplicateRange(NSRange targetR,NSRange exceptR,NSMutableAttributedString * str,NSString * pattern,NSMutableArray * linkArr){
    NSArray * arr = DWRangeExcept(targetR, exceptR);
    [arr enumerateObjectsUsingBlock:^(NSValue * rangeValue, NSUInteger idx, BOOL * _Nonnull stop) {
        NSRegularExpression * regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:nil];
        NSArray * results = [regex matchesInString:str.string options:0 range:rangeValue.rangeValue];
        [linkArr addObjectsFromArray:results];
    }];
}

///返回目标范围排除指定范围后的结果数组
static inline NSArray * DWRangeExcept(NSRange targetRange,NSRange exceptRange){
    NSRange interRange = NSIntersectionRange(targetRange, exceptRange);
    if (interRange.length == 0) {
        return nil;
    }
    else if (NSEqualRanges(targetRange, interRange))
    {
        return nil;
    }
    NSMutableArray * arr = [NSMutableArray array];
    
    if (interRange.location > targetRange.location) {
        [arr addObject:[NSValue valueWithRange:NSMakeRange(targetRange.location, interRange.location - targetRange.location)]];
    }
    if (NSMaxRange(targetRange) > NSMaxRange(interRange)) {
        [arr addObject:[NSValue valueWithRange:NSMakeRange(NSMaxRange(interRange), NSMaxRange(targetRange) - NSMaxRange(interRange))]];
    }
    return arr.copy;
};

#pragma mark ---绘制相关---
///绘制富文本
-(void)drawTheTextWithContext:(CGContextRef)context isCanceled:(BOOL(^)())isCanceled{
    
    CGContextSaveGState(context);
    CGContextSetTextMatrix(context, CGAffineTransformIdentity);
    CGContextTranslateCTM(context, 0, self.bounds.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    
    ///计算绘制尺寸限制
    CGFloat limitWidth = (self.bounds.size.width - self.textInsets.left - self.textInsets.right) > 0 ? (self.bounds.size.width - self.textInsets.left - self.textInsets.right) : 0;
    CGFloat limitHeight = (self.bounds.size.height - self.textInsets.top - self.textInsets.bottom) > 0 ? (self.bounds.size.height - self.textInsets.top - self.textInsets.bottom) : 0;
    if (isCanceled()) return;
    if (self.reCalculate || !self.mAStr) {
        ///获取要绘制的文本
        self.mAStr = getMAStr(self,limitWidth);
    }
    
    if (isCanceled()) return;
    ///已添加事件、链接的集合
    NSMutableSet * rangeSet = [NSMutableSet set];
    ///添加活跃文本属性方法
    [self handleActiveTextWithStr:self.mAStr rangeSet:rangeSet withImage:!self.reCalculate];
    
    if (isCanceled()) return;
    ///处理插入图片
    if (self.reCalculate) {
        NSMutableArray * arrInsert = [NSMutableArray array];
        [self.imageArr enumerateObjectsUsingBlock:^(NSDictionary * dic, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([dic[@"drawMode"] integerValue] == DWTextImageDrawModeInsert) {
                [arrInsert addObject:dic];
            }
        }];
        ///富文本插入图片占位符
        [self handleStr:self.mAStr withInsertImageArr:arrInsert];
    }
    
    if (isCanceled()) return;
    ///计算drawFrame及drawPath
    if (self.reCalculate) {
        [self handleDrawFrameAndPathWithLimitWidth:limitWidth limitHeight:limitHeight];
    }
    
    if (isCanceled()) return;
    ///处理文本高亮状态并获取可见绘制文本范围
    NSRange visibleRange = [self handleStringHighlightAttributesWithRangeSet:rangeSet];
    
    if (isCanceled()) return;
    ///绘制的工厂
    CTFramesetterRef frameSetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)self.mAStr);
    CTFrameRef visibleFrame = CTFramesetterCreateFrame(frameSetter, CFRangeMake(0,visibleRange.length), self.drawPath.CGPath, NULL);
    
    if (isCanceled()){
        CFSAFERELEASE(visibleFrame);
        CFSAFERELEASE(frameSetter);
        return;
    }
    if (self.reCalculate) {
        ///计算活跃文本及插入图片的frame
        [self handleFrameForActiveTextAndInsertImageWithCTFrame:visibleFrame];
    }
    
    if (isCanceled()){
        CFSAFERELEASE(visibleFrame);
        CFSAFERELEASE(frameSetter);
        return;
    }
    ///绘制图片
    [self.imageArr enumerateObjectsUsingBlock:^(NSDictionary * dic, NSUInteger idx, BOOL * _Nonnull stop) {
        UIImage * image = dic[@"image"];
        CGRect frame = convertRect([dic[@"frame"] CGRectValue],self.bounds.size.height);
        CGContextDrawImage(context, frame, image.CGImage);
    }];
    
    self.reCalculate = NO;
    self.reCheck = NO;
    self.finishFirstDraw = YES;
    ///绘制上下文
    CTFrameDraw(visibleFrame, context);
    
    ///内存管理
    CFSAFERELEASE(visibleFrame);
    CFSAFERELEASE(frameSetter);
    
    CGContextRestoreGState(context);
}

///自动重绘
-(void)handleAutoRedrawWithRecalculate:(BOOL)reCalculate
                               reCheck:(BOOL)reCheck
{
    [self handleAutoRedrawWithRecalculate:reCalculate reCheck:reCheck reDraw:YES];
}

///按需重绘
-(void)handleAutoRedrawWithRecalculate:(BOOL)reCalculate
                               reCheck:(BOOL)reCheck
                                reDraw:(BOOL)reDraw
{
    if (self.finishFirstDraw) {
        self.reCalculate = reCalculate;
        self.reCheck = reCheck;
    }
    if (reDraw) {
        [self setNeedsDisplay];
    }
}

///处理绘制frame及path
-(void)handleDrawFrameAndPathWithLimitWidth:(CGFloat)limitWidth
                                limitHeight:(CGFloat)limitHeight
{
    CTFramesetterRef frameSetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)self.mAStr);
    ///生成绘制尺寸
    CGSize suggestSize = getSuggestSize(frameSetter,limitWidth,self.mAStr,self.numberOfLines);
    CFSAFERELEASE(frameSetter);
    self.suggestSize = CGSizeMake(suggestSize.width + self.textInsets.left + self.textInsets.right, suggestSize.height + self.textInsets.top + self.textInsets.bottom);
    CGRect frame = CGRectMake(self.textInsets.left, self.textInsets.bottom, limitWidth, limitHeight);
    
    ///处理图片排除区域
    [self handleImageExclusion];
    
    ///处理对其方式方式
    [self handleAlignmentWithFrame:&frame suggestSize:suggestSize limitWidth:limitWidth];
    
    self.drawFrame = frame;
    
    ///创建绘制区域
    UIBezierPath * path = [UIBezierPath bezierPathWithRect:self.drawFrame];
    ///排除区域处理
    if (self.exclusionPaths.count) {
        [self handleDrawPath:path frame:self.drawFrame exclusionArray:self.exclusionP];
    }
    
    ///图片环绕区域处理
    if (self.imageExclusion.count) {
        [self handleDrawPath:path frame:self.drawFrame exclusionArray:self.imageExclusion];
    }
    self.drawPath = path;
}

///文本变化相关处理
-(void)handleTextChange
{
    [self.imageArr removeAllObjects];
    [self.activeTextArr removeAllObjects];
    [self.autoLinkArr removeAllObjects];
    [self.textRangeArr removeAllObjects];
    [self.arrLocationImgHasAdd removeAllObjects];
    [self handleAutoRedrawWithRecalculate:YES reCheck:YES reDraw:self.autoRedraw];
}

///处理图片环绕数组，绘制前调用
-(void)handleImageExclusion
{
    [self.imageExclusion removeAllObjects];
    [self.imageArr enumerateObjectsUsingBlock:^(NSDictionary * dic, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([dic[@"drawMode"] integerValue] == DWTextImageDrawModeSurround) {
            UIBezierPath * newPath = [dic[@"drawPath"] copy];
            [self.imageExclusion addObject:newPath];
        }
    }];
}

///处理绘制Path，绘制前调用
-(void)handleDrawPath:(UIBezierPath *)path frame:(CGRect)frame exclusionArray:(NSMutableArray *)array
{
    [array enumerateObjectsUsingBlock:^(UIBezierPath * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (CGRectContainsRect(path.bounds, obj.bounds)) {
            convertPath(obj,frame);
            [path appendPath:obj];
        }
    }];
}

///将所有插入图片和活跃文本字典中的frame补全，重绘前调用
-(void)handleFrameForActiveTextAndInsertImageWithCTFrame:(CTFrameRef)frame
{
    [self.activeTextArr removeAllObjects];
    [self.autoLinkArr removeAllObjects];
    [self enumerateCTRunInFrame:frame handler:^(CTLineRef line, CTRunRef run,CGPoint origin,BOOL * stop) {
        CGRect deleteBounds = getCTRunBounds(frame,line,origin,run);
        if (CGRectEqualToRect(deleteBounds,CGRectNull)) {///无活动范围跳过
            return ;
        }
        deleteBounds = convertRect(deleteBounds,self.bounds.size.height);
        
        NSDictionary * attributes = (NSDictionary *)CTRunGetAttributes(run);
        CTRunDelegateRef delegate = (__bridge CTRunDelegateRef)[attributes valueForKey:(id)kCTRunDelegateAttributeName];
        
        if (delegate == nil) {///检测图片，不是图片检测文字
            NSMutableDictionary * dic = attributes[@"clickAttribute"];
            if (!dic) {///不是活动文字检测自动链接及定制链接
                if (self.customLinkRegex.length) {
                    dic = attributes[@"customLink"];
                }
                
                if (!dic && self.autoCheckLink) {
                    dic = attributes[@"autoCheckLink"];
                }
                if (!dic) {
                    return;
                }
                handleFrame(self.autoLinkArr,dic,deleteBounds);
                return;
            }
            handleFrame(self.activeTextArr,dic,deleteBounds);
            return;
        }
        NSMutableDictionary * dic = CTRunDelegateGetRefCon(delegate);
        if (![dic isKindOfClass:[NSMutableDictionary class]]) {
            return;
        }
        UIImage * image = dic[@"image"];
        if (!image) {///检测图片，不是图片跳过
            return;
        }
        dic[@"drawPath"] = [UIBezierPath bezierPathWithRect:deleteBounds];
        CGFloat padding = [dic[@"padding"] floatValue];
        if (padding != 0) {
            deleteBounds = CGRectInset(deleteBounds, padding, 0);
        }
        if (!CGRectEqualToRect(deleteBounds, CGRectZero)) {
            dic[@"frame"] = [NSValue valueWithCGRect:deleteBounds];
            dic[@"activePath"] = [UIBezierPath bezierPathWithRect:deleteBounds];
        }
    }];
}

///遍历CTRun
-(void)enumerateCTRunInFrame:(CTFrameRef)frame
                     handler:(void(^)(CTLineRef line,CTRunRef run,CGPoint origin,BOOL * stop))handler{
    NSArray * arrLines = (NSArray *)CTFrameGetLines(frame);
    NSInteger count = [arrLines count];
    CGPoint points[count];
    CTFrameGetLineOrigins(frame, CFRangeMake(0, 0), points);
    BOOL stop = NO;
    for (int i = 0; i < count; i ++) {
        CTLineRef line = (__bridge CTLineRef)arrLines[i];
        NSArray * arrRuns = (NSArray *)CTLineGetGlyphRuns(line);
        for (int j = 0; j < arrRuns.count; j ++) {
            CTRunRef run = (__bridge CTRunRef)arrRuns[j];
            handler(line,run,points[i],&stop);
            if (stop) {
                break;
            }
        }
    }
}

///补全frame
static inline void handleFrame(NSMutableArray * arr,NSDictionary *dic,CGRect deleteBounds)
{
    NSValue * boundsValue = [NSValue valueWithCGRect:deleteBounds];
    NSMutableDictionary * dicWithFrame = [NSMutableDictionary dictionaryWithDictionary:dic];
    dicWithFrame[@"frame"] = boundsValue;
    [arr addObject:dicWithFrame];
}

#pragma mark ---获取相关数据方法---

///获取当前需要绘制的文本
static inline NSMutableAttributedString * getMAStr(DWCoreTextLabel * label,CGFloat limitWidth)
{
    NSMutableAttributedString * mAStr = [[NSMutableAttributedString alloc] initWithAttributedString:label.attributedText];
    NSUInteger length = label.attributedText?label.attributedText.length:label.text.length;
    NSMutableParagraphStyle * paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    NSRange totalRange = NSMakeRange(0, length);
    if (!label.attributedText) {
        [paragraphStyle setLineBreakMode:label.lineBreakMode];
        [paragraphStyle setLineSpacing:label.lineSpacing];
        paragraphStyle.alignment = (label.exclusionPaths.count == 0)?label.textAlignment:NSTextAlignmentLeft;
        NSMutableAttributedString * attributeStr = [[NSMutableAttributedString alloc] initWithString:label.text];
        [attributeStr addAttribute:NSFontAttributeName value:label.font range:totalRange];
        [attributeStr addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:totalRange];
        [attributeStr addAttribute:NSForegroundColorAttributeName value:label.textColor range:totalRange];
        mAStr = attributeStr;
    }
    else
    {
        [paragraphStyle setLineBreakMode:label.lineBreakMode];
        paragraphStyle.alignment = (label.exclusionPaths.count == 0)?label.textAlignment:NSTextAlignmentLeft;
        [mAStr addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:totalRange];
    }
    
    CTFramesetterRef frameSetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)mAStr);
    CFRange range = getLastLineRange(frameSetter,limitWidth,label.numberOfLines);
    NSMutableParagraphStyle * newPara = [paragraphStyle mutableCopy];
    newPara.lineBreakMode = NSLineBreakByTruncatingTail;
    [mAStr addAttribute:NSParagraphStyleAttributeName value:newPara range:NSMakeRange(range.location, range.length)];
    CFSAFERELEASE(frameSetter);
    return mAStr;
}

///获取插入图片偏移量
static inline NSInteger getInsertOffset(DWCoreTextLabel * label,NSInteger location)
{
    NSNumber * loc = [NSNumber numberWithInteger:location];
    if (label.arrLocationImgHasAdd.count == 0) {//如果数组是空的，直接添加位置，并返回0
        [label.arrLocationImgHasAdd addObject:loc];
        return 0;
    }
    [label.arrLocationImgHasAdd addObject:loc];//否则先插入，再排序
    [label.arrLocationImgHasAdd sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {//升序排序方法
        if ([obj1 integerValue] > [obj2 integerValue]) {
            return (NSComparisonResult)NSOrderedDescending;
        }
        
        if ([obj1 integerValue] < [obj2 integerValue]) {
            return (NSComparisonResult)NSOrderedAscending;
        }
        return (NSComparisonResult)NSOrderedSame;
    }];
    return [label.arrLocationImgHasAdd indexOfObject:loc];//返回本次插入图片的偏移量
}

///获取绘制尺寸
static inline CGSize getSuggestSize(CTFramesetterRef frameSetter,CGFloat limitWidth,NSMutableAttributedString * str,NSUInteger numberOfLines)
{
    CGSize restrictSize = CGSizeMake(limitWidth, MAXFLOAT);
    if (numberOfLines == 1) {
        restrictSize = CGSizeMake(MAXFLOAT, MAXFLOAT);
    }
    CFRange rangeToDraw = getRangeToDraw(frameSetter,limitWidth,str,numberOfLines);
    CGSize suggestSize = CTFramesetterSuggestFrameSizeWithConstraints(frameSetter, rangeToDraw, nil, restrictSize, nil);
    return CGSizeMake(MIN(suggestSize.width, limitWidth), suggestSize.height);
}

///获取计算绘制可见文本范围
static inline NSRange getRangeToDrawForVisibleString(DWCoreTextLabel * label)
{
    CTFramesetterRef tempFrameSetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)label.mAStr);
    CTFrameRef tempFrame = CTFramesetterCreateFrame(tempFrameSetter, CFRangeMake(0, label.mAStr.length), label.drawPath.CGPath, NULL);
    CFRange range = CTFrameGetVisibleStringRange(tempFrame);
    CFSAFERELEASE(tempFrame);
    CFSAFERELEASE(tempFrameSetter);
    return NSMakeRange(range.location, range.length);
}

///获取绘制Frame范围
static inline CFRange getRangeToDraw(CTFramesetterRef frameSetter,CGFloat limitWidth,NSMutableAttributedString * str,NSUInteger numberOfLines)
{
    CFRange rangeToDraw = CFRangeMake(0, str.length);
    CFRange range = getLastLineRange(frameSetter,limitWidth,numberOfLines);
    if (range.length > 0) {
        rangeToDraw = CFRangeMake(0, range.location + range.length);
    }
    return rangeToDraw;
}

///获取最后一行绘制范围
static inline CFRange getLastLineRange(CTFramesetterRef frameSetter,CGFloat limitWidth,NSUInteger numberOfLines)
{
    CFRange range = CFRangeMake(0, 0);
    if (numberOfLines > 0) {
        CGMutablePathRef path = CGPathCreateMutable();
        CGPathAddRect(path, NULL, CGRectMake(0.0f, 0.0f, limitWidth, MAXFLOAT));
        CTFrameRef frame = CTFramesetterCreateFrame(frameSetter, CFRangeMake(0, 0), path, NULL);
        CFArrayRef lines = CTFrameGetLines(frame);
        if (CFArrayGetCount(lines) > 0) {
            NSUInteger lineNum = MIN(numberOfLines, CFArrayGetCount(lines));
            CTLineRef line = CFArrayGetValueAtIndex(lines, lineNum - 1);
            range = CTLineGetStringRange(line);
        }
        CFSAFERELEASE(path);
        CFSAFERELEASE(frame);
    }
    return range;
}

///获取按照margin缩放的frame
static inline UIBezierPath * getImageAcitvePath(UIBezierPath * path,CGFloat margin)
{
    UIBezierPath * newPath = [path copy];
    if (margin == 0) {
        return newPath;
    }
    CGFloat widthScale = 1 - margin * 2 / newPath.bounds.size.width;
    CGFloat heightScale = 1 - margin * 2 / newPath.bounds.size.height;
    CGFloat offsetX = newPath.bounds.origin.x * (1 - widthScale) + margin;
    CGFloat offsetY = newPath.bounds.origin.y * (1 -heightScale) + margin;
    [newPath applyTransform:CGAffineTransformMakeScale(widthScale, heightScale)];
    [newPath applyTransform:CGAffineTransformMakeTranslation(offsetX, offsetY)];
    return newPath;
}

///获取CTRun的frame
static inline CGRect getCTRunBounds(CTFrameRef frame,CTLineRef line,CGPoint origin,CTRunRef run)
{
    CGFloat ascent;
    CGFloat descent;
    CGRect boundsRun = CGRectZero;
    boundsRun.size.width = CTRunGetTypographicBounds(run, CFRangeMake(0, 0), &ascent, &descent, NULL);
    boundsRun.size.height = ascent + descent;
    CGFloat xOffset = CTLineGetOffsetForStringIndex(line, CTRunGetStringRange(run).location, NULL);
    boundsRun.origin.x = origin.x + xOffset;
    boundsRun.origin.y = origin.y - descent;
    CGPathRef path = CTFrameGetPath(frame);
    CGRect colRect = CGPathGetBoundingBox(path);
    return CGRectOffset(boundsRun, colRect.origin.x, colRect.origin.y);
}

///获取活动图片中包含点的字典
static inline NSMutableDictionary * getImageDic(NSMutableArray * arr,CGPoint point)
{
    __block NSMutableDictionary * dicClicked = nil;
    [arr enumerateObjectsUsingBlock:^(NSMutableDictionary * dic, NSUInteger idx, BOOL * _Nonnull stop) {
        UIBezierPath * path = dic[@"activePath"];
        if ([path containsPoint:point]) {
            if (dic[@"target"] && dic[@"SEL"]) {
                dicClicked = dic;
            }
            *stop = YES;
        }
    }];
    return dicClicked;
}

///从对应数组中获取字典
static inline NSMutableDictionary * getGivenDic(CGPoint point,NSMutableArray * arr)
{
    __block NSMutableDictionary * dicClicked = nil;
    [arr enumerateObjectsUsingBlock:^(NSMutableDictionary * dic, NSUInteger idx, BOOL * _Nonnull stop) {
        CGRect frame = [dic[@"frame"] CGRectValue];
        if (CGRectContainsPoint(frame, point)) {
            if (dic[@"target"] && dic[@"SEL"]) {
                dicClicked = dic;
            }
            *stop = YES;
        }
    }];
    return dicClicked;
}

///获取活动文字中包含点的字典
static inline NSMutableDictionary * getActiveTextDic(NSMutableArray * arr,CGPoint point)
{
    return getGivenDic(point,arr);
}

///获取自动链接中包含点的字典
static inline NSMutableDictionary * getAutoLinkDic(NSMutableArray * arr,CGPoint point)
{
    return getGivenDic(point,arr);
}

#pragma mark ---镜像转换方法---
///获取镜像path
static inline void convertPath(UIBezierPath * path,CGRect bounds)
{
    [path applyTransform:CGAffineTransformMakeScale(1, -1)];
    [path applyTransform:CGAffineTransformMakeTranslation(0, 2 * bounds.origin.y + bounds.size.height)];
}

///获取镜像frame
static inline CGRect convertRect(CGRect rect,CGFloat height)
{
    return CGRectMake(rect.origin.x, height - rect.origin.y - rect.size.height, rect.size.width, rect.size.height);
}

#pragma mark ---获取点击行为---
-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    CGPoint point = [[touches anyObject] locationInView:self];
    
    NSMutableDictionary * dic = [self handleHasActionStatusWithPoint:point];
    BOOL autoLink = [dic[@"link"] length];
    if (dic) {
        [self handleHighlightClickWithDic:dic isLink:autoLink];
        return;
    }
    [super touchesBegan:touches withEvent:event];
}

-(void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    if (self.hasActionToDo) {
        CGPoint point = [[touches anyObject] locationInView:self];
        NSMutableDictionary * dic = [self handleHasActionStatusWithPoint:point];
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
    [super touchesMoved:touches withEvent:event];
}

-(void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    if (self.hasActionToDo) {
        CGPoint point = [[touches anyObject] locationInView:self];
        NSMutableDictionary * dic = getImageDic(self.imageArr,point);
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
    [super touchesEnded:touches withEvent:event];
}

-(void)autoLinkClicked:(NSDictionary *)userInfo
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(coreTextLabel:didSelectLink:range:linkType:)]) {
        [self.delegate coreTextLabel:self didSelectLink:userInfo[@"link"] range:[userInfo[@"range"] rangeValue] linkType:[userInfo[@"linkType"] integerValue]];
    }
}

///处理点击事件
-(void)handleClickWithDic:(NSDictionary *)dic
{
    self.hasActionToDo = NO;
    self.highlightDic = nil;
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

///处理点击高亮
-(void)handleHighlightClickWithDic:(NSMutableDictionary *)dic isLink:(BOOL)link
{
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
-(NSMutableDictionary *)handleHasActionStatusWithPoint:(CGPoint)point
{
    self.hasActionToDo = NO;
    NSMutableDictionary * imgDic = getImageDic(self.imageArr, point);
    if (imgDic) {
        self.hasActionToDo = YES;
        return nil;
    }
    NSMutableDictionary * activeTextDic = getActiveTextDic(self.activeTextArr, point);
    if (activeTextDic) {
        self.hasActionToDo = YES;
        return activeTextDic;
    }
    NSMutableDictionary * autoLinkDic = getAutoLinkDic(self.autoLinkArr, point);
    if (autoLinkDic) {
        self.hasActionToDo = YES;
        return autoLinkDic;
    }
    return nil;
}

#pragma mark ---CTRun 代理---
static CGFloat ascentCallBacks(void * ref)
{
    NSDictionary * dic = (__bridge NSDictionary *)ref;
    CGSize size = [dic[@"size"] CGSizeValue];
    CGFloat descent = [dic[@"descent"] floatValue];
    return size.height - descent;
}

static CGFloat descentCallBacks(void * ref)
{
    NSDictionary * dic = (__bridge NSDictionary *)ref;
    CGFloat descent = [dic[@"descent"] floatValue];
    return descent;
}

static CGFloat widthCallBacks(void * ref)
{
    NSDictionary * dic = (__bridge NSDictionary *)ref;
    CGSize size = [dic[@"size"] CGSizeValue];
    return size.width;
}

#pragma mark ---method override---

+(Class)layerClass
{
    return [DWAsyncLayer class];
}

-(instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _lineSpacing = - 65536;
        _lineBreakMode = NSLineBreakByCharWrapping;
        _reCalculate = YES;
        _reCheck = YES;
        self.backgroundColor = [UIColor clearColor];
        DWAsyncLayer * layer = (DWAsyncLayer *)self.layer;
        layer.contentsScale = [UIScreen mainScreen].scale;
        __weak typeof(self)weakSelf = self;
        layer.displayBlock = ^(CGContextRef context,BOOL(^isCanceled)()){
            [weakSelf drawTheTextWithContext:context isCanceled:isCanceled];
        };
    }
    return self;
}

-(void)setNeedsDisplay
{
    [super setNeedsDisplay];
    [self.layer setNeedsDisplay];
}

-(void)sizeToFit
{
    CGRect frame = self.frame;
    frame.size = [self sizeThatFits:CGSizeMake(self.bounds.size.width, 0)];
    self.frame = frame;
}

-(CGSize)sizeThatFits:(CGSize)size
{
    if (!CGSizeEqualToSize(self.suggestSize, CGSizeZero)) {
        return self.suggestSize;
    }
    CGFloat limitWidth = (size.width - self.textInsets.left - self.textInsets.right) > 0 ? (size.width - self.textInsets.left - self.textInsets.right) : 0;
    
    NSMutableAttributedString * mAStr = getMAStr(self,limitWidth);
    
    NSMutableArray * arrInsert = [NSMutableArray array];
    [self.imageArr enumerateObjectsUsingBlock:^(NSDictionary * dic, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([dic[@"drawMode"] integerValue] == DWTextImageDrawModeInsert) {
            [arrInsert addObject:dic];
        }
    }];
    [self handleStr:mAStr withInsertImageArr:arrInsert];
    
    CTFramesetterRef frameSetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)mAStr);
    CGSize suggestSize = getSuggestSize(frameSetter,limitWidth,self.mAStr,self.numberOfLines);
    CFSAFERELEASE(frameSetter);
    return CGSizeMake(suggestSize.width + self.textInsets.left + self.textInsets.right, suggestSize.height + self.textInsets.top + self.textInsets.bottom);
}

#pragma mark ---setter、getter---
-(void)setText:(NSString *)text
{
    if (![_text isEqualToString:text]) {
        _text = text;
        [self handleTextChange];
    }
}

-(void)setTextAlignment:(NSTextAlignment)textAlignment
{
    if ((self.exclusionPaths.count == 0) && (_textAlignment != textAlignment)) {
        _textAlignment = textAlignment;
        [self handleAutoRedrawWithRecalculate:YES reCheck:NO reDraw:self.autoRedraw];
    }
}

-(void)setTextVerticalAlignment:(DWTextVerticalAlignment)textVerticalAlignment
{
    if ((self.exclusionPaths.count == 0) && (_textVerticalAlignment != textVerticalAlignment)) {
        _textVerticalAlignment = textVerticalAlignment;
        [self handleAutoRedrawWithRecalculate:YES reCheck:NO reDraw:self.autoRedraw];
    }
}

-(UIFont *)font
{
    if (!_font) {
        _font = [UIFont systemFontOfSize:17];
    }
    return _font;
}

-(void)setFont:(UIFont *)font
{
    _font = font;
    [self handleAutoRedrawWithRecalculate:YES reCheck:NO reDraw:self.autoRedraw];
}

-(void)setTextInsets:(UIEdgeInsets)textInsets
{
    if (!UIEdgeInsetsEqualToEdgeInsets(_textInsets, textInsets)) {
        _textInsets = textInsets;
        [self handleAutoRedrawWithRecalculate:YES reCheck:NO reDraw:self.autoRedraw];
    }
}

-(void)setAttributedText:(NSAttributedString *)attributedText
{
    if (![_attributedText isEqualToAttributedString:attributedText]) {
        _attributedText = attributedText;
        [self handleTextChange];
    }
}

-(void)setTextColor:(UIColor *)textColor
{
    if (!CGColorEqualToColor(_textColor.CGColor,textColor.CGColor)) {
        _textColor = textColor;
        [self handleAutoRedrawWithRecalculate:YES reCheck:NO reDraw:self.autoRedraw];
    }
}

-(UIColor *)textColor
{
    if (!_textColor) {
        _textColor = [UIColor blackColor];
    }
    return _textColor;
}

-(void)setLineSpacing:(CGFloat)lineSpacing
{
    if (_lineSpacing != lineSpacing) {
        _lineSpacing = lineSpacing;
        [self handleAutoRedrawWithRecalculate:YES reCheck:NO reDraw:self.autoRedraw];
    }
}

-(CGFloat)lineSpacing
{
    if (_lineSpacing == -65536) {
        return 5.5;
    }
    return _lineSpacing;
}

-(NSMutableArray<UIBezierPath *> *)exclusionPaths
{
    if (!_exclusionPaths) {
        _exclusionPaths = [NSMutableArray array];
    }
    return _exclusionPaths;
}

-(void)setExclusionPaths:(NSMutableArray<UIBezierPath *> *)exclusionPaths
{
    _exclusionPaths = exclusionPaths;
    [self handleAutoRedrawWithRecalculate:YES reCheck:NO reDraw:self.autoRedraw];
}

-(void)setNumberOfLines:(NSUInteger)numberOfLines
{
    if (_numberOfLines != numberOfLines) {
        _numberOfLines = numberOfLines;
        [self handleAutoRedrawWithRecalculate:YES reCheck:NO reDraw:self.autoRedraw];
    }
}

-(void)setLineBreakMode:(NSLineBreakMode)lineBreakMode
{
    if (_lineBreakMode != lineBreakMode) {
        _lineBreakMode = lineBreakMode;
        [self handleAutoRedrawWithRecalculate:YES reCheck:YES reDraw:self.autoRedraw];
    }
}

-(void)setAutoCheckLink:(BOOL)autoCheckLink
{
    if (_autoCheckLink != autoCheckLink) {
        _autoCheckLink = autoCheckLink;
        self.reCalculate = YES;
        self.reCheck = YES;
        [self setNeedsDisplay];
    }
}

-(void)setAutoCheckConfig:(NSMutableDictionary *)autoCheckConfig
{
    _autoCheckConfig = autoCheckConfig;
    if (self.autoCheckLink) {
        [self handleAutoRedrawWithRecalculate:YES reCheck:YES reDraw:self.autoRedraw];
    }
}

-(NSMutableDictionary *)autoCheckConfig
{
    return self.autoCheckLink?(_autoCheckConfig?_autoCheckConfig:[NSMutableDictionary dictionaryWithDictionary:@{@"phoneNo":@"(1[34578]\\d{9}|(0[\\d]{2,3}-)?([2-9][\\d]{6,7})(-[\\d]{1,4})?)",@"email":@"[A-Za-z\\d]+([-_.][A-Za-z\\d]+)*@([A-Za-z\\d]+[-.])*([A-Za-z\\d]+[.])+[A-Za-z\\d]{2,5}",@"URL":@"((http|ftp|https)://)?((([a-zA-Z0-9]+[a-zA-Z0-9_-]*\\.)+[a-zA-Z]{2,6})|(([0-9]{1,3}\\.){3}[0-9]{1,3}(:[0-9]{1,4})?))((/[a-zA-Z\\d_]+)*(\\?([a-zA-Z\\d_]+=[a-zA-Z\\d\\u4E00-\\u9FA5\\s\\+%#_-]+&)*([a-zA-Z\\d_]+=[a-zA-Z\\d\\u4E00-\\u9FA5\\s\\+%#_-]+))?)?",@"naturalNum":@"\\d+(\\.\\d+)?"}]):nil;
}

-(void)setCustomLinkRegex:(NSString *)customLinkRegex
{
    if (![_customLinkRegex isEqualToString:customLinkRegex]) {
        _customLinkRegex = customLinkRegex;
        [self handleAutoRedrawWithRecalculate:YES reCheck:YES reDraw:self.autoRedraw];
    }
}

-(void)setFrame:(CGRect)frame
{
    if (!CGRectEqualToRect(self.frame, frame)) {
        [super setFrame:frame];
        [self handleAutoRedrawWithRecalculate:YES reCheck:NO reDraw:self.autoRedraw];
    }
}

#pragma mark ---链接属性setter、getter---
-(void)setActiveTextAttributes:(NSDictionary *)activeTextAttributes
{
    _activeTextAttributes = activeTextAttributes;
    [self handleAutoRedrawWithRecalculate:NO reCheck:NO reDraw:self.autoRedraw];
}

-(void)setActiveTextHighlightAttributes:(NSDictionary *)activeTextHighlightAttributes
{
    _activeTextHighlightAttributes = activeTextHighlightAttributes;
    [self handleAutoRedrawWithRecalculate:NO reCheck:NO reDraw:self.autoRedraw];
}

-(void)setNaturalNumAttributes:(NSDictionary *)naturalNumAttributes
{
    _naturalNumAttributes = naturalNumAttributes;
    if (self.autoCheckLink) {
        [self handleAutoRedrawWithRecalculate:NO reCheck:NO reDraw:self.autoRedraw];
    }
}

-(NSDictionary *)naturalNumAttributes
{
    return self.autoCheckLink?(_naturalNumAttributes?_naturalNumAttributes:DWDefaultAttributes):nil;
}

-(void)setNaturalNumHighlightAttributes:(NSDictionary *)naturalNumHighlightAttributes
{
    _naturalNumHighlightAttributes = naturalNumHighlightAttributes;
    if (self.autoCheckLink) {
        [self handleAutoRedrawWithRecalculate:NO reCheck:NO reDraw:self.autoRedraw];
    }
}

-(NSDictionary *)naturalNumHighlightAttributes
{
    return self.autoCheckLink?(_naturalNumHighlightAttributes?_naturalNumHighlightAttributes:DWDefaultHighlightAttributes):nil;
}

-(void)setPhoneNoAttributes:(NSDictionary *)phoneNoAttributes
{
    _phoneNoAttributes = phoneNoAttributes;
    if (self.autoCheckLink) {
        [self handleAutoRedrawWithRecalculate:NO reCheck:NO reDraw:self.autoRedraw];
    }
}

-(NSDictionary *)phoneNoAttributes
{
    return self.autoCheckLink?(_phoneNoAttributes?_phoneNoAttributes:DWDefaultAttributes):nil;
}

-(void)setPhoneNoHighlightAttributes:(NSDictionary *)phoneNoHighlightAttributes
{
    _phoneNoHighlightAttributes = phoneNoHighlightAttributes;
    if (self.autoCheckLink) {
        [self handleAutoRedrawWithRecalculate:NO reCheck:NO reDraw:self.autoRedraw];
    }
}

-(NSDictionary *)phoneNoHighlightAttributes
{
    return self.autoCheckLink?(_phoneNoHighlightAttributes?_phoneNoHighlightAttributes:DWDefaultHighlightAttributes):nil;
}

-(void)setURLAttributes:(NSDictionary *)URLAttributes
{
    _URLAttributes = URLAttributes;
    if (self.autoCheckLink) {
        [self handleAutoRedrawWithRecalculate:NO reCheck:NO reDraw:self.autoRedraw];
    }
}

-(NSDictionary *)URLAttributes
{
    return self.autoCheckLink?(_URLAttributes?_URLAttributes:DWDefaultAttributes):nil;
}

-(void)setURLHighlightAttributes:(NSDictionary *)URLHighlightAttributes
{
    _URLHighlightAttributes = URLHighlightAttributes;
    if (self.autoCheckLink) {
        [self handleAutoRedrawWithRecalculate:NO reCheck:NO reDraw:self.autoRedraw];
    }
}

-(NSDictionary *)URLHighlightAttributes
{
    return self.autoCheckLink?(_URLHighlightAttributes?_URLHighlightAttributes:DWDefaultHighlightAttributes):nil;
}


-(void)setEmailAttributes:(NSDictionary *)emailAttributes
{
    _emailAttributes = emailAttributes;
    if (self.autoCheckLink) {
        [self handleAutoRedrawWithRecalculate:NO reCheck:NO reDraw:self.autoRedraw];
    }
}

-(NSDictionary *)emailAttributes
{
    return self.autoCheckLink?(_emailAttributes?_emailAttributes:DWDefaultAttributes):nil;
}

-(void)setEmailHighlightAttributes:(NSDictionary *)emailHighlightAttributes
{
    _emailHighlightAttributes = emailHighlightAttributes;
    if (self.autoCheckLink) {
        [self handleAutoRedrawWithRecalculate:NO reCheck:NO reDraw:self.autoRedraw];
    }
}

-(NSDictionary *)emailHighlightAttributes
{
    return self.autoCheckLink?(_emailHighlightAttributes?_emailHighlightAttributes:DWDefaultHighlightAttributes):nil;
}

-(void)setCustomLinkAttributes:(NSDictionary *)customLinkAttributes
{
    _customLinkAttributes = customLinkAttributes;
    [self handleAutoRedrawWithRecalculate:NO reCheck:NO reDraw:self.autoRedraw];
}

-(NSDictionary *)customLinkAttributes
{
    return (self.customLinkRegex.length > 0)?(_customLinkAttributes?_customLinkAttributes:DWDefaultAttributes):nil;
}

-(void)setCustomLinkHighlightAttributes:(NSDictionary *)customLinkHighlightAttributes
{
    _customLinkHighlightAttributes = customLinkHighlightAttributes;
    [self handleAutoRedrawWithRecalculate:NO reCheck:NO reDraw:self.autoRedraw];
}

-(NSDictionary *)customLinkHighlightAttributes
{
    return (self.customLinkRegex.length > 0)?(_customLinkHighlightAttributes?_customLinkHighlightAttributes:DWDefaultHighlightAttributes):nil;
}

#pragma mark ---中间容器属性setter、getter---
-(NSMutableArray *)imageArr
{
    if (!_imageArr) {
        _imageArr = [NSMutableArray array];
    }
    return _imageArr;
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

-(NSMutableArray *)activeTextArr
{
    if (!_activeTextArr) {
        _activeTextArr = [NSMutableArray array];
    }
    return _activeTextArr;
}

-(NSMutableArray *)autoLinkArr
{
    if (!_autoLinkArr) {
        _autoLinkArr = [NSMutableArray array];
    }
    return _autoLinkArr;
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
