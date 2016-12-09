//
//  DWCoreTextLabel.m
//  DWCoreTextLabel
//
//  Created by Wicky on 16/12/4.
//  Copyright © 2016年 Wicky. All rights reserved.
//

#import "DWCoreTextLabel.h"
#import <CoreText/CoreText.h>

@interface DWCoreTextLabel ()

@property (nonatomic ,strong) NSMutableArray * exclusionP;

@property (nonatomic ,strong) NSMutableArray * imageArr;

@property (nonatomic ,strong) NSMutableArray * imageExclusion;

@end

@implementation DWCoreTextLabel
@synthesize font = _font;
@synthesize textColor = _textColor;
@synthesize exclusionPaths = _exclusionPaths;
@synthesize lineSpacing = _lineSpacing;

-(instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _lineSpacing = - 65536;
        _lineBreakMode = NSLineBreakByCharWrapping;
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetTextMatrix(context, CGAffineTransformIdentity);
    CGContextTranslateCTM(context, 0, self.bounds.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    
    CGFloat limitWidth = (self.bounds.size.width - self.textInsets.left - self.textInsets.right) > 0 ? (self.bounds.size.width - self.textInsets.left - self.textInsets.right) : 0;
    CGFloat limitHeight = (self.bounds.size.height - self.textInsets.top - self.textInsets.bottom) > 0 ? (self.bounds.size.height - self.textInsets.top - self.textInsets.bottom) : 0;
    
    NSMutableAttributedString * mAStr = [self getMAStrWithLimitWidth:limitWidth];
    
    CTFramesetterRef frameSetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)mAStr);//一个frame的工厂，负责生成frame
    
    CGSize suggestSize = [self getSuggestSizeWithFrameSetter:frameSetter limitWidth:limitWidth strToDraw:mAStr];
    
    CGRect frame = CGRectMake(self.textInsets.left, self.textInsets.bottom, limitWidth, limitHeight);
    
    [self handleImageExclusionWithFrame:frame];
    
    
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
    
    UIBezierPath * path = [UIBezierPath bezierPathWithRect:frame];
    
    ///排除区域处理
    if (self.exclusionPaths.count) {
        [self handleDrawPath:path frame:frame exclusionArray:self.exclusionP];
    }
    
    ///图片环绕区域处理
    if (self.imageExclusion.count) {
        [self handleDrawPath:path frame:frame exclusionArray:self.imageExclusion];
    }
    
    CTFrameRef _frame = CTFramesetterCreateFrame(frameSetter, CFRangeMake(0, mAStr.length), path.CGPath, NULL);//工厂根据绘制区域及富文本（可选范围，多次设置）设置frame
    
    CFRange range = CTFrameGetVisibleStringRange(_frame);
    if (range.length < mAStr.length) {
        _frame = CTFramesetterCreateFrame(frameSetter, CFRangeMake(0, range.length), path.CGPath, NULL);
    }
    
    [self.imageArr enumerateObjectsUsingBlock:^(NSDictionary * dic, NSUInteger idx, BOOL * _Nonnull stop) {
        UIImage * image = dic[@"image"];
        CGRect frame = [self convertRect:[dic[@"frame"] CGRectValue]];
        CGContextDrawImage(context, frame, image.CGImage);
    }];
    
    CTFrameDraw(_frame, context);//根据frame绘制上下文
    CFRelease(_frame);
    CFRelease(frameSetter);
}


-(void)drawImage:(UIImage *)image atFrame:(CGRect)frame drawMode:(DWTextImageDrawMode)mode
{
    switch (mode) {
        case DWTextImageDrawModeCover:
        {
           
        }
            break;
        case DWTextImageDrawModeInsert:
        {
            
        }
            break;
        default:
        {
            
        }
            break;
    }
    [self.imageArr addObject:@{@"image":image,@"frame":[NSValue valueWithCGRect:frame],@"drawMode":@(mode)}];
    [self handleAutoRedraw];
}


#pragma mark ---tool method---

///获取当前需要绘制的文本
-(NSMutableAttributedString *)getMAStrWithLimitWidth:(CGFloat)limitWidth
{
    NSMutableAttributedString * mAStr = [[NSMutableAttributedString alloc] initWithAttributedString:self.attributedText];
    NSUInteger length = self.attributedText?self.attributedText.length:self.text.length;
    NSMutableParagraphStyle * paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    NSRange totalRange = NSMakeRange(0, length);
    if (!self.attributedText) {
        
        [paragraphStyle setLineBreakMode:self.lineBreakMode];
        [paragraphStyle setLineSpacing:self.lineSpacing];//行间距
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
    
    CTFramesetterRef frameSetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)mAStr);//一个frame的工厂，负责生成frame
    CFRange range = [self getLastLineRangeWithFrameSetter:frameSetter limitWidth:limitWidth];
    NSMutableParagraphStyle * newPara = [paragraphStyle mutableCopy];
    newPara.lineBreakMode = NSLineBreakByTruncatingTail;
    [mAStr addAttribute:NSParagraphStyleAttributeName value:newPara range:NSMakeRange(range.location, range.length)];
    return mAStr;
}

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

///处理图片环绕数组，绘制前调用
-(void)handleImageExclusionWithFrame:(CGRect)frame
{
    [self.imageExclusion removeAllObjects];
    [self.imageArr enumerateObjectsUsingBlock:^(NSDictionary * dic, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([dic[@"drawMode"] integerValue] == DWTextImageDrawModeSurround) {
            CGRect imgFrame = [dic[@"frame"] CGRectValue];
            CGRect newFrame = CGRectIntersection(frame,imgFrame);
            [self.imageExclusion addObject:[UIBezierPath bezierPathWithRect:newFrame]];
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

-(void)handleAutoRedraw
{
    if (self.autoRedraw) {
        [self setNeedsDisplay];
    }
}
#pragma mark ---method override---
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
    [self handleAutoRedraw];
}

-(void)setTextAlignment:(NSTextAlignment)textAlignment
{
    if (self.exclusionPaths.count == 0) {
        _textAlignment = textAlignment;
        [self handleAutoRedraw];
    }
}

-(void)setTextVerticalAlignment:(DWTextVerticalAlignment)textVerticalAlignment
{
    if (self.exclusionPaths.count == 0) {
        _textVerticalAlignment = textVerticalAlignment;
        [self handleAutoRedraw];
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
    [self handleAutoRedraw];
}

-(void)setTextInsets:(UIEdgeInsets)textInsets
{
    _textInsets = textInsets;
    [self handleAutoRedraw];
}

-(void)setAttributedText:(NSAttributedString *)attributedText
{
    _attributedText = attributedText;
    [self handleAutoRedraw];
}

-(void)setTextColor:(UIColor *)textColor
{
    _textColor = textColor;
    [self handleAutoRedraw];
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
    [self handleAutoRedraw];
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
    [self handleAutoRedraw];
}

-(NSMutableArray *)exclusionP
{
    return [self.exclusionPaths copy];
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
@end
