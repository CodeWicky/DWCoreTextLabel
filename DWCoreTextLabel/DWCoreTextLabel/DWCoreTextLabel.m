//
//  DWCoreTextLabel.m
//  DWCoreTextLabel
//
//  Created by Wicky on 16/12/4.
//  Copyright © 2016年 Wicky. All rights reserved.
//

#import "DWCoreTextLabel.h"
#import <CoreText/CoreText.h>
static DWTextImageDrawMode DWTextImageDrawModeInsert = 2;
@interface DWCoreTextLabel ()

///绘制文本
@property (nonatomic ,strong) NSMutableAttributedString * mAStr;

///绘制图片数组
@property (nonatomic ,strong) NSMutableArray * imageArr;

///活跃文本数组
@property (nonatomic ,strong) NSMutableArray * activeTextArr;

///活跃文本数组
@property (nonatomic ,strong) NSMutableArray * textRangeArr;

///绘制surround图片是排除区域数组
@property (nonatomic ,strong) NSMutableArray * imageExclusion;

///绘制插入图片是保存插入位置的数组
@property (nonatomic ,strong) NSMutableArray * arrLocationImgHasAdd;

///点击状态
@property (nonatomic ,assign) BOOL textClicked;

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

@end

@implementation DWCoreTextLabel
@synthesize font = _font;
@synthesize textColor = _textColor;
@synthesize exclusionPaths = _exclusionPaths;
@synthesize lineSpacing = _lineSpacing;

#pragma mark ---接口方法---

///在字符串指定位置插入图片
-(void)dw_InsertImage:(UIImage *)image size:(CGSize)size padding:(CGFloat)padding descent:(CGFloat)descent atLocation:(NSUInteger)location target:(id)target selector:(SEL)selector
{
    if (padding != 0) {
        size = CGSizeMake(size.width + padding * 2, size.height);
    }
    NSMutableDictionary * dic = [NSMutableDictionary dictionaryWithDictionary:@{@"image":image,@"size":[NSValue valueWithCGSize:size],@"padding":@(padding),@"location":@(location),@"descent":@(descent),@"drawMode":@(DWTextImageDrawModeInsert)}];
    if (target && selector) {
        [dic setValue:target forKey:@"target"];
        [dic setValue:NSStringFromSelector(selector) forKey:@"SEL"];
    }
    [self.imageArr addObject:dic];
    [self handleAutoRedrawWithRecalculate:YES];
}

///以指定模式绘制图片
-(void)dw_DrawImage:(UIImage *)image atFrame:(CGRect)frame margin:(CGFloat)margin drawMode:(DWTextImageDrawMode)mode target:(id)target selector:(SEL)selector
{
    if (CGRectEqualToRect(frame, CGRectZero)) {
        return;
    }
    CGRect drawFrame = CGRectInset(frame, margin, margin);
    UIBezierPath * drawPath = [UIBezierPath bezierPathWithRect:frame];
    UIBezierPath * activePath = [self getImageAcitvePathWithDrawPath:drawPath margin:margin];
    NSMutableDictionary * dic = [NSMutableDictionary dictionaryWithDictionary:@{@"image":image,@"drawPath":drawPath,@"activePath":activePath,@"frame":[NSValue valueWithCGRect:drawFrame],@"margin":@(margin),@"drawMode":@(mode)}];
    if (target && selector) {
        [dic setValue:target forKey:@"target"];
        [dic setValue:NSStringFromSelector(selector) forKey:@"SEL"];
    }
    [self.imageArr addObject:dic];
    [self handleAutoRedrawWithRecalculate:YES];
}

-(void)dw_DrawImage:(UIImage *)image WithPath:(UIBezierPath *)path margin:(CGFloat)margin drawMode:(DWTextImageDrawMode)mode target:(id)target selector:(SEL)selector
{
    if (!path) {
        return;
    }
    UIBezierPath * newPath = [path copy];
    [newPath applyTransform:CGAffineTransformMakeTranslation(-newPath.bounds.origin.x, -newPath.bounds.origin.y)];
    image = [DWCoreTextLabel dw_ClipImage:image withPath:newPath mode:(DWImageClipModeScaleAspectFill)];
    UIBezierPath * activePath = [self getImageAcitvePathWithDrawPath:path margin:margin];
    
    NSMutableDictionary * dic = [NSMutableDictionary dictionaryWithDictionary:@{@"image":image,@"drawPath":path,@"activePath":activePath,@"frame":[NSValue valueWithCGRect:CGRectInset(path.bounds, margin, margin)],@"drawMode":@(mode)}];
    if (target && selector) {
        [dic setValue:target forKey:@"target"];
        [dic setValue:NSStringFromSelector(selector) forKey:@"SEL"];
    }
    [self.imageArr addObject:dic];
    [self handleAutoRedrawWithRecalculate:YES];
}

///给指定范围添加响应事件
-(void)dw_AddTarget:(id)target selector:(SEL)selector toRange:(NSRange)range
{
    if (target && selector && range.length > 0) {
        NSMutableDictionary * dic = [NSMutableDictionary dictionaryWithDictionary:@{@"target":target,@"SEL":NSStringFromSelector(selector),@"range":[NSValue valueWithRange:range]}];
        [self.textRangeArr addObject:dic];
        [self handleAutoRedrawWithRecalculate:YES];
    }
}

+(UIImage *)dw_ClipImage:(UIImage *)image withPath:(UIBezierPath *)path mode:(DWImageClipMode)mode
{
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
    [path addClip];
    ///移动原点至图片中心
    CGContextTranslateCTM(bitmap, boxBounds.size.width/2.0, boxBounds.size.height/2.0);
    CGContextScaleCTM(bitmap, 1.0, -1.0);
    CGContextDrawImage(bitmap, CGRectMake(-width / 2, -height / 2, width, height), image.CGImage);
    
    ///生成图片
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}

#pragma mark ---插入图片相关---

///将图片设置代理后插入富文本
-(void)insertPicWithDictionary:(NSMutableDictionary *)dic
                         toStr:(NSMutableAttributedString *)str
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
    CFRelease(delegate);
    NSInteger offset = [self getInsertOffsetWithLocation:location];
    [str insertAttributedString:placeHolderAttrStr atIndex:location + offset];
}

///将所有插入图片插入字符串
-(void)handleStr:(NSMutableAttributedString *)str withInsertImageArr:(NSMutableArray *)arr
{
    [self.arrLocationImgHasAdd removeAllObjects];
    [arr enumerateObjectsUsingBlock:^(NSMutableDictionary * dic, NSUInteger idx, BOOL * _Nonnull stop) {
        [self insertPicWithDictionary:dic toStr:str];
    }];
}

///将所有插入图片的字典中的frame补全
-(void)handleInsertImageFrameWithArr:(NSMutableArray *)arr
                             CTFrame:(CTFrameRef)frame
{
    [arr enumerateObjectsUsingBlock:^(NSMutableDictionary * dic, NSUInteger idx, BOOL * _Nonnull stop) {
        UIImage * image = dic[@"image"];
        CGRect rect = [self getRectWithImage:image CTFrame:frame];
        rect = [self convertRect:rect];
        dic[@"drawPath"] = [UIBezierPath bezierPathWithRect:rect];
        CGFloat padding = [dic[@"padding"] floatValue];
        if (padding != 0) {
            rect = CGRectInset(rect, padding, 0);
        }
        if (!CGRectEqualToRect(rect, CGRectZero)) {
            dic[@"frame"] = [NSValue valueWithCGRect:rect];
            dic[@"activePath"] = [UIBezierPath bezierPathWithRect:rect];
        }
    }];
}

#pragma mark ---文本相关---
///获取当前需要绘制的文本
-(NSMutableAttributedString *)getMAStrWithLimitWidth:(CGFloat)limitWidth
{
    NSMutableAttributedString * mAStr = [[NSMutableAttributedString alloc] initWithAttributedString:self.attributedText];
    NSUInteger length = self.attributedText?self.attributedText.length:self.text.length;
    NSMutableParagraphStyle * paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    NSRange totalRange = NSMakeRange(0, length);
    if (!self.attributedText) {
        [paragraphStyle setLineBreakMode:self.lineBreakMode];
        [paragraphStyle setLineSpacing:self.lineSpacing];
        paragraphStyle.alignment = (self.exclusionPaths.count == 0)?self.textAlignment:NSTextAlignmentLeft;
        NSMutableAttributedString * attributeStr = [[NSMutableAttributedString alloc] initWithString:self.text];
        [attributeStr addAttribute:NSFontAttributeName value:self.font range:totalRange];
        [attributeStr addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:totalRange];
        [attributeStr addAttribute:NSForegroundColorAttributeName value:self.textColor range:totalRange];
        mAStr = attributeStr;
    }
    else
    {
        [paragraphStyle setLineBreakMode:self.lineBreakMode];
        paragraphStyle.alignment = (self.exclusionPaths.count == 0)?self.textAlignment:NSTextAlignmentLeft;
        [mAStr addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:totalRange];
    }
    
    CTFramesetterRef frameSetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)mAStr);
    CFRange range = [self getLastLineRangeWithFrameSetter:frameSetter limitWidth:limitWidth];
    NSMutableParagraphStyle * newPara = [paragraphStyle mutableCopy];
    newPara.lineBreakMode = NSLineBreakByTruncatingTail;
    [mAStr addAttribute:NSParagraphStyleAttributeName value:newPara range:NSMakeRange(range.location, range.length)];
    CFRelease(frameSetter);
    return mAStr;
}

///处理对齐方式
-(void)handleAlignmentWithFrame:(CGRect)frame
                    suggestSize:(CGSize)suggestSize
                     limitWidth:(CGFloat)limitWidth
{
    if ((self.exclusionPaths.count + self.imageExclusion.count) == 0) {///若无排除区域按对齐方式处理
        if (frame.size.height > suggestSize.height) {///垂直对齐方式处理
            frame.size = suggestSize;
            CGPoint origin = frame.origin;
            if (self.textVerticalAlignment == DWTextVerticalAlignmentCenter) {
                origin.y = self.bounds.size.height / 2.0 - suggestSize.height / 2.0;
            }
            else if (self.textVerticalAlignment == DWTextVerticalAlignmentTop)
            {
                origin.y = self.bounds.size.height - suggestSize.height - self.textInsets.top;
            }
            frame.origin = origin;
        }
        
        if (frame.size.width < limitWidth) {///水平对齐方式处理
            CGPoint origin = frame.origin;
            if (self.textAlignment == NSTextAlignmentCenter) {
                origin.x = self.bounds.size.width / 2.0 - frame.size.width / 2.0;
            }
            else if (self.textAlignment == NSTextAlignmentRight)
            {
                origin.x = self.bounds.size.width - frame.size.width - self.textInsets.right;
            }
            frame.origin = origin;
        }
    }
}

///添加点击事件方法
-(void)handleActiveTextWithStr:(NSMutableAttributedString *)str withImage:(BOOL)withImage
{
    [self.textRangeArr enumerateObjectsUsingBlock:^(NSMutableDictionary * dic  , NSUInteger idx, BOOL * _Nonnull stop) {
        NSRange range = [dic[@"range"] rangeValue];
        if (withImage) {
            range = [self handleRangeOffset:range];
        }
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
-(NSRange)handleRangeOffset:(NSRange)range
{
    __block NSRange newRange = range;
    [self.arrLocationImgHasAdd enumerateObjectsUsingBlock:^(NSNumber * location, NSUInteger idx, BOOL * _Nonnull stop) {
        if (location.integerValue <= range.location) {
            newRange.location ++;
        }
        else if (location.integerValue <= (range.location + range.length - 1)){
            newRange.length ++;
        }
    }];
    return newRange;
}

///将所有活动文本的frame补全
-(void)handleActiveTextFrameWithCTFrame:(CTFrameRef)frame
{
    [self.activeTextArr removeAllObjects];
    [self enumerateCTRunInFrame:frame handler:^(NSArray *arrLines, CGPoint *points, int currentLineNum, NSArray *arrRuns, int currentRunNum, BOOL *stop) {
        CTRunRef run = (__bridge CTRunRef)arrRuns[currentRunNum];
        NSDictionary * attributes = (NSDictionary *)CTRunGetAttributes(run);
        NSMutableDictionary * dic = attributes[@"clickAttribute"];
        if (!dic) {
            return ;
        }
        CGPoint point = points[currentLineNum];
        CTLineRef line = (__bridge CTLineRef)arrLines[currentLineNum];
        CGRect deleteBounds = [self getCTRunBoundsWithFrame:frame line:line lineOrigin:point run:run];
        if (!CGRectEqualToRect(deleteBounds, CGRectNull)) {
            deleteBounds = [self convertRect:deleteBounds];
            NSValue * boundsValue = [NSValue valueWithCGRect:deleteBounds];
            NSMutableDictionary * dicWithFrame = [NSMutableDictionary dictionaryWithDictionary:dic];
            dicWithFrame[@"frame"] = boundsValue;
            [self.activeTextArr addObject:dicWithFrame];
        }
    }];
}

#pragma mark ---绘制相关---
///自动重绘
-(void)handleAutoRedrawWithRecalculate:(BOOL)reCalculate
{
    self.reCalculate = reCalculate;
    if (self.autoRedraw) {
        [self setNeedsDisplay];
    }
}

///处理图片环绕数组，绘制前调用
-(void)handleImageExclusionWithFrame:(CGRect)frame
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
            [self dw_MirrorPath:obj inBounds:frame];
            [path appendPath:obj];
        }
    }];
}

#pragma mark ---获取相关数据方法---
///获取插入图片偏移量
-(NSInteger)getInsertOffsetWithLocation:(NSInteger)location
{
    NSNumber * loc = [NSNumber numberWithInteger:location];
    if (self.arrLocationImgHasAdd.count == 0) {//如果数组是空的，直接添加位置，并返回0
        [self.arrLocationImgHasAdd addObject:loc];
        return 0;
    }
    [self.arrLocationImgHasAdd addObject:loc];//否则先插入，再排序
    [self.arrLocationImgHasAdd sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {//升序排序方法
        if ([obj1 integerValue] > [obj2 integerValue]) {
            return (NSComparisonResult)NSOrderedDescending;
        }
        
        if ([obj1 integerValue] < [obj2 integerValue]) {
            return (NSComparisonResult)NSOrderedAscending;
        }
        return (NSComparisonResult)NSOrderedSame;
    }];
    return [self.arrLocationImgHasAdd indexOfObject:loc];//返回本次插入图片的偏移量
}

///获取绘制尺寸
-(CGSize)getSuggestSizeWithFrameSetter:(CTFramesetterRef)frameSetter
                            limitWidth:(CGFloat)limitWidth
                             strToDraw:(NSMutableAttributedString *)str
{
    CGSize restrictSize = CGSizeMake(limitWidth, MAXFLOAT);
    if (self.numberOflines == 1) {
        restrictSize = CGSizeMake(MAXFLOAT, MAXFLOAT);
    }
    CFRange rangeToDraw = [self getRangeToDrawWithFrameSetter:frameSetter limitWidth:limitWidth strToDraw:str];
    CGSize suggestSize = CTFramesetterSuggestFrameSizeWithConstraints(frameSetter, rangeToDraw, nil, restrictSize, nil);
    return CGSizeMake(MIN(suggestSize.width, limitWidth), suggestSize.height);
}

///获取绘制范围
-(CFRange)getRangeToDrawWithFrameSetter:(CTFramesetterRef)frameSetter
                             limitWidth:(CGFloat)limitWidth
                              strToDraw:(NSMutableAttributedString *)str
{
    CFRange rangeToDraw = CFRangeMake(0, str.length);
    CFRange range = [self getLastLineRangeWithFrameSetter:frameSetter limitWidth:limitWidth];
    if (range.length > 0) {
        rangeToDraw = CFRangeMake(0, range.location + range.length);
    }
    return rangeToDraw;
}

///获取最后一行绘制范围
-(CFRange)getLastLineRangeWithFrameSetter:(CTFramesetterRef)frameSetter
                               limitWidth:(CGFloat)limitWidth
{
    CFRange range = CFRangeMake(0, 0);
    if (self.numberOflines > 0) {
        CGMutablePathRef path = CGPathCreateMutable();
        CGPathAddRect(path, NULL, CGRectMake(0.0f, 0.0f, limitWidth, MAXFLOAT));
        CTFrameRef frame = CTFramesetterCreateFrame(frameSetter, CFRangeMake(0, 0), path, NULL);
        CFArrayRef lines = CTFrameGetLines(frame);
        if (CFArrayGetCount(lines) > 0) {
            NSUInteger lineNum = MIN(self.numberOflines, CFArrayGetCount(lines));
            CTLineRef line = CFArrayGetValueAtIndex(lines, lineNum - 1);
            range = CTLineGetStringRange(line);
        }
        CFRelease(path);
        CFRelease(frame);
    }
    return range;
}

///获取按照margin缩放的frame
-(UIBezierPath *)getImageAcitvePathWithDrawPath:(UIBezierPath *)path margin:(CGFloat)margin
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

///获取对应图片的绘制frame
-(CGRect)getRectWithImage:(UIImage *)image
                    CTFrame:(CTFrameRef)frame
{
    __block CGRect deleteBounds = CGRectNull;
    [self enumerateCTRunInFrame:frame handler:^(NSArray *arrLines, CGPoint *points, int currentLineNum, NSArray *arrRuns, int currentRunNum,BOOL * stop) {
        CTRunRef run = (__bridge CTRunRef)arrRuns[currentRunNum];
        NSDictionary * attributes = (NSDictionary *)CTRunGetAttributes(run);
        CTRunDelegateRef delegate = (__bridge CTRunDelegateRef)[attributes valueForKey:(id)kCTRunDelegateAttributeName];
        if (delegate == nil) {
            return ;
        }
        NSDictionary * dic = CTRunDelegateGetRefCon(delegate);
        if (![dic isKindOfClass:[NSDictionary class]]) {
            return;
        }
        if (![dic[@"image"] isEqual:image]) {
            return;
        }
        CGPoint point = points[currentLineNum];
        CTLineRef line = (__bridge CTLineRef)arrLines[currentLineNum];
        deleteBounds = [self getCTRunBoundsWithFrame:frame line:line lineOrigin:point run:run];
        *stop = YES;
    }];
    return deleteBounds;
}

///获取CTRun的frame
-(CGRect)getCTRunBoundsWithFrame:(CTFrameRef)frame
                            line:(CTLineRef)line
                      lineOrigin:(CGPoint)origin
                             run:(CTRunRef)run
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

///遍历CTRun
-(void)enumerateCTRunInFrame:(CTFrameRef)frame
                     handler:(void(^)(NSArray * arrLines,CGPoint points[],int currentLineNum,NSArray * arrRuns,int currentRunNum,BOOL * stop))handler{
    NSArray * arrLines = (NSArray *)CTFrameGetLines(frame);
    NSInteger count = [arrLines count];
    CGPoint points[count];
    CTFrameGetLineOrigins(frame, CFRangeMake(0, 0), points);
    for (int i = 0; i < count; i ++) {
        CTLineRef line = (__bridge CTLineRef)arrLines[i];
        NSArray * arrRuns = (NSArray *)CTLineGetGlyphRuns(line);
        for (int j = 0; j < arrRuns.count; j ++) {
            BOOL stop = NO;
            handler(arrLines,points,i,arrRuns,j,&stop);
            if (stop) {
                break;
            }
        }
    }
}

///获取活动图片中包含点的字典
-(NSMutableDictionary *)getImageDicWithPoint:(CGPoint)point
{
    __block NSMutableDictionary * dicClicked = nil;
    [self.imageArr enumerateObjectsUsingBlock:^(NSMutableDictionary * dic, NSUInteger idx, BOOL * _Nonnull stop) {
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

///获取活动文字中包含点的字典
-(NSMutableDictionary *)getActiveTextDicWithPoint:(CGPoint)point
{
    __block NSMutableDictionary * dicClicked = nil;
    [self.activeTextArr enumerateObjectsUsingBlock:^(NSMutableDictionary * dic, NSUInteger idx, BOOL * _Nonnull stop) {
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

#pragma mark ---镜像转换方法---
///获取镜像path
-(void)dw_MirrorPath:(UIBezierPath *)path inBounds:(CGRect)bounds
{
    [path applyTransform:CGAffineTransformMakeScale(1, -1)];
    [path applyTransform:CGAffineTransformMakeTranslation(0, 2 * bounds.origin.y + bounds.size.height)];
}

///获取镜像frame
-(CGRect)convertRect:(CGRect)rect
{
    return CGRectMake(rect.origin.x, self.bounds.size.height - rect.origin.y - rect.size.height, rect.size.width, rect.size.height);
}

///获取镜像point
-(CGPoint)convertPoint:(CGPoint)point
{
    return CGPointMake(point.x, self.bounds.size.height - point.y);
}

#pragma mark ---获取点击行为---
-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    CGPoint point = [[touches anyObject] locationInView:self];
    
    [self handleHasActionStatusWithPoint:point];
    NSMutableDictionary * dic = [self getActiveTextDicWithPoint:point];
    if (dic) {
        [self handleHighlightClickWithDic:dic];
        return;
    }
    [super touchesBegan:touches withEvent:event];
}

-(void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    if (self.hasActionToDo) {
        CGPoint point = [[touches anyObject] locationInView:self];
        [self handleHasActionStatusWithPoint:point];
        if (!self.hasActionToDo) {
            if (self.textClicked) {
                self.textClicked = NO;
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
        NSMutableDictionary * dic = [self getImageDicWithPoint:point];
        if (dic) {
            [self handleClickWithDic:dic];
            return;
        }
        dic = self.highlightDic;
        if (dic) {
            if (self.textClicked) {
                self.textClicked = NO;
                [self setNeedsDisplay];
            }
            [self handleClickWithDic:dic];
            return;
        }
    }
    [super touchesEnded:touches withEvent:event];
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
    [invocation invoke];
}

///处理点击高亮
-(void)handleHighlightClickWithDic:(NSMutableDictionary *)dic
{
    if (self.activeTextHighlightAttributes) {
        self.textClicked = YES;
        self.highlightDic = dic;
        [self setNeedsDisplay];
    }
}

///处理具有响应事件状态
-(void)handleHasActionStatusWithPoint:(CGPoint)point
{
    self.hasActionToDo = ([self getImageDicWithPoint:point] || [self getActiveTextDicWithPoint:point]);
}

#pragma mark ---CTRUN代理---
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

-(instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _lineSpacing = - 65536;
        _lineBreakMode = NSLineBreakByCharWrapping;
        _reCalculate = YES;
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    
    ///坐标系处理
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetTextMatrix(context, CGAffineTransformIdentity);
    CGContextTranslateCTM(context, 0, self.bounds.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    
    ///计算绘制尺寸限制
    CGFloat limitWidth = (self.bounds.size.width - self.textInsets.left - self.textInsets.right) > 0 ? (self.bounds.size.width - self.textInsets.left - self.textInsets.right) : 0;
    CGFloat limitHeight = (self.bounds.size.height - self.textInsets.top - self.textInsets.bottom) > 0 ? (self.bounds.size.height - self.textInsets.top - self.textInsets.bottom) : 0;
    if (self.reCalculate || !self.mAStr) {
        ///获取要绘制的文本
        self.mAStr = [self getMAStrWithLimitWidth:limitWidth];
    }
    
    ///添加点击事件
    [self handleActiveTextWithStr:self.mAStr withImage:!self.reCalculate];
    
    ///处理插入图片
    NSMutableArray * arrInsert = [NSMutableArray array];
    if (self.reCalculate) {
        [self.imageArr enumerateObjectsUsingBlock:^(NSDictionary * dic, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([dic[@"drawMode"] integerValue] == DWTextImageDrawModeInsert) {
                [arrInsert addObject:dic];
            }
        }];
        ///富文本插入图片占位符
        [self handleStr:self.mAStr withInsertImageArr:arrInsert];
    }
    
    
    ///添加工厂
    CTFramesetterRef frameSetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)self.mAStr);
    
    if (self.reCalculate) {
        ///生成绘制尺寸
        CGSize suggestSize = [self getSuggestSizeWithFrameSetter:frameSetter limitWidth:limitWidth strToDraw:self.mAStr];
        
        CGRect frame = CGRectMake(self.textInsets.left, self.textInsets.bottom, limitWidth, limitHeight);
        
        ///处理图片排除区域
        [self handleImageExclusionWithFrame:frame];
        
        ///处理对其方式方式
        [self handleAlignmentWithFrame:frame suggestSize:suggestSize limitWidth:limitWidth];
        
        self.drawFrame = frame;
    }
    
    if (self.reCalculate) {
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
    
    ///获取全部绘制区域
    CTFrameRef _frame = CTFramesetterCreateFrame(frameSetter, CFRangeMake(0, self.mAStr.length), self.drawPath.CGPath, NULL);
    
    ///获取范围内可显示范围
    CFRange range = CTFrameGetVisibleStringRange(_frame);
    
    ///获取可显示绘制区域
    if (range.length < self.mAStr.length) {
        CFRelease(_frame);
        _frame = CTFramesetterCreateFrame(frameSetter, CFRangeMake(0, range.length), self.drawPath.CGPath, NULL);
    }
    
    if (self.reCalculate) {
        ///计算可点击文本frame
        [self handleActiveTextFrameWithCTFrame:_frame];
        ///计算插入图片的frame
        [self handleInsertImageFrameWithArr:arrInsert CTFrame:_frame];
    }

    ///绘制图片
    [self.imageArr enumerateObjectsUsingBlock:^(NSDictionary * dic, NSUInteger idx, BOOL * _Nonnull stop) {
        UIImage * image = dic[@"image"];
        CGRect frame = [self convertRect:[dic[@"frame"] CGRectValue]];
        CGContextDrawImage(context, frame, image.CGImage);
    }];
    
    self.reCalculate = NO;
    
    ///绘制上下文
    CTFrameDraw(_frame, context);
    
    ///内存管理
    CFRelease(_frame);
    CFRelease(frameSetter);
}

//-(void)sizeToFit
//{
//    CGRect frame = self.frame;
//    frame.size = [self sizeThatFits:CGSizeMake(self.bounds.size.width, 0)];
//    self.frame = frame;
//}
//
//-(CGSize)sizeThatFits:(CGSize)size
//{
//    CGFloat limitWidth = (size.width - self.textInsets.left - self.textInsets.right) > 0 ? (self.bounds.size.width - self.textInsets.left - self.textInsets.right) : 0;
//    NSMutableAttributedString * mAStr = [self getMAStr];
//    CTFramesetterRef frameSetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)mAStr);//一个frame的工厂，负责生成frame
//
//    CGSize suggestSize = [self getSuggestSizeWithFrameSetter:frameSetter limitWidth:limitWidth];
//
//    return CGSizeMake(suggestSize.width + self.textInsets.left + self.textInsets.right, suggestSize.height + self.textInsets.top + self.textInsets.bottom);
//}

#pragma mark ---setter、getter---
-(void)setText:(NSString *)text
{
    _text = text;
    [self handleAutoRedrawWithRecalculate:YES];
}

-(void)setTextAlignment:(NSTextAlignment)textAlignment
{
    if (self.exclusionPaths.count == 0) {
        _textAlignment = textAlignment;
        [self handleAutoRedrawWithRecalculate:YES];
    }
}

-(void)setTextVerticalAlignment:(DWTextVerticalAlignment)textVerticalAlignment
{
    if (self.exclusionPaths.count == 0) {
        _textVerticalAlignment = textVerticalAlignment;
        [self handleAutoRedrawWithRecalculate:YES];
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
    [self handleAutoRedrawWithRecalculate:YES];
}

-(void)setTextInsets:(UIEdgeInsets)textInsets
{
    _textInsets = textInsets;
    [self handleAutoRedrawWithRecalculate:YES];
}

-(void)setAttributedText:(NSAttributedString *)attributedText
{
    _attributedText = attributedText;
    [self handleAutoRedrawWithRecalculate:YES];
}

-(void)setTextColor:(UIColor *)textColor
{
    _textColor = textColor;
    [self handleAutoRedrawWithRecalculate:YES];
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
    _lineSpacing = lineSpacing;
    [self handleAutoRedrawWithRecalculate:YES];
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
    [self handleAutoRedrawWithRecalculate:YES];
}

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

-(NSMutableArray *)exclusionP
{
    return [[NSMutableArray alloc] initWithArray:self.exclusionPaths copyItems:YES];
}

-(void)setNumberOflines:(NSUInteger)numberOflines
{
    _numberOflines = numberOflines;
    [self handleAutoRedrawWithRecalculate:YES];
}

-(void)setLineBreakMode:(NSLineBreakMode)lineBreakMode
{
    _lineBreakMode = lineBreakMode;
    [self handleAutoRedrawWithRecalculate:YES];
}

-(void)setActiveTextAttributes:(NSDictionary *)activeTextAttributes
{
    _activeTextAttributes = activeTextAttributes;
    [self handleAutoRedrawWithRecalculate:NO];
}

-(void)setActiveTextHighlightAttributes:(NSDictionary *)activeTextHighlightAttributes
{
    _activeTextHighlightAttributes = activeTextHighlightAttributes;
    [self handleAutoRedrawWithRecalculate:NO];
}

@end
