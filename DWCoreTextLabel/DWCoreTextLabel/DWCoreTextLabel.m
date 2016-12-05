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

@end

@implementation DWCoreTextLabel
@synthesize font = _font;
@synthesize textColor = _textColor;
@synthesize exclusionPaths = _exclusionPaths;

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetTextMatrix(context, CGAffineTransformIdentity);
    CGContextTranslateCTM(context, 0, self.bounds.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    
    NSMutableAttributedString * mAStr = [self getMAStr];
    
    CGFloat limitWidth = (self.bounds.size.width - self.textInsets.left - self.textInsets.right) > 0 ? (self.bounds.size.width - self.textInsets.left - self.textInsets.right) : 0;
    CGFloat limitHeight = (self.bounds.size.height - self.textInsets.top - self.textInsets.bottom) > 0 ? (self.bounds.size.height - self.textInsets.top - self.textInsets.bottom) : 0;
    
    CTFramesetterRef frameSetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)mAStr);//一个frame的工厂，负责生成frame
    
    CGSize suggestSize = [self getSuggestSizeWithFrameSetter:frameSetter limitWidth:limitWidth];
    
    CGRect frame = CGRectMake(self.textInsets.left, self.textInsets.bottom, limitWidth, limitHeight);
    if (self.exclusionPaths.count == 0) {///若无排除区域按对齐方式处理
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
    [[UIColor greenColor] setFill];
    [path fill];
    
    
    if (self.exclusionPaths.count) {
        [self.exclusionP enumerateObjectsUsingBlock:^(UIBezierPath * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (CGRectContainsRect(path.bounds, obj.bounds)) {
                [self dw_MirrorPath:obj inBounds:frame];
                [path appendPath:obj];
            }
        }];
    }
    
    [[UIColor orangeColor] setFill];
    [path fill];
    
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
        default:
        {
            [self.exclusionPaths addObject:[UIBezierPath bezierPathWithRect:frame]];
        }
            break;
    }
    [self.imageArr addObject:@{@"image":image,@"frame":[NSValue valueWithCGRect:frame],@"drawMode":@(mode)}];
    if (self.autoRedraw) {
        [self setNeedsDisplay];
    }
}


#pragma mark ---tool method---

-(NSMutableAttributedString *)getMAStr
{
    
    
    NSMutableAttributedString * mAStr = [[NSMutableAttributedString alloc] initWithAttributedString:self.attributedText];
    if (!self.attributedText) {
        ///解决水平对齐方式
        NSMutableParagraphStyle   *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        [paragraphStyle setLineSpacing:5.5];//行间距
        paragraphStyle.alignment = self.exclusionPaths.count == 0?self.textAlignment:NSTextAlignmentLeft;
        NSRange totalRange = NSMakeRange(0, self.text.length);
        NSMutableAttributedString * attributeStr = [[NSMutableAttributedString alloc] initWithString:self.text];
        [attributeStr addAttribute:NSFontAttributeName value:self.font range:totalRange];
        [attributeStr addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:totalRange];
        [attributeStr addAttribute:(NSString *)NSForegroundColorAttributeName value:self.textColor range:totalRange];
        
        mAStr = attributeStr;
        
    }
    return mAStr;
}

-(void)dw_MirrorPath:(UIBezierPath *)path inBounds:(CGRect)bounds
{
    [path applyTransform:CGAffineTransformMakeScale(1, -1)];
    [path applyTransform:CGAffineTransformMakeTranslation(0, 2 * bounds.origin.y + bounds.size.height)];
}

-(CGSize)getSuggestSizeWithFrameSetter:(CTFramesetterRef)frameSetter
                            limitWidth:(CGFloat)limitWidth
{
    CGSize restrictSize = CGSizeMake(limitWidth, CGFLOAT_MAX);//创建预估计尺寸
    CGSize suggestSize = CTFramesetterSuggestFrameSizeWithConstraints(frameSetter, CFRangeMake(0, 0), nil, restrictSize, nil);//根据工厂生成建议尺寸。宽度不变，高度自适应
    return suggestSize;
}

-(CGRect)convertRect:(CGRect)rect
{
    return CGRectMake(rect.origin.x, self.bounds.size.height - rect.origin.y - rect.size.height, rect.size.width, rect.size.height);
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
    if (self.autoRedraw) {
        [self setNeedsDisplay];
    }
}

-(void)setTextAlignment:(NSTextAlignment)textAlignment
{
    if (self.exclusionPaths.count == 0) {
        _textAlignment = textAlignment;
        if (self.autoRedraw) {
            [self setNeedsDisplay];
        }
    }
}

-(void)setTextVerticalAlignment:(DWTextVerticalAlignment)textVerticalAlignment
{
    if (self.exclusionPaths.count == 0) {
        _textVerticalAlignment = textVerticalAlignment;
        if (self.autoRedraw) {
            [self setNeedsDisplay];
        }
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
    if (self.autoRedraw) {
        [self setNeedsDisplay];
    }
}

-(void)setTextInsets:(UIEdgeInsets)textInsets
{
    _textInsets = textInsets;
    if (self.autoRedraw) {
        [self setNeedsDisplay];
    }
}

-(void)setAttributedText:(NSAttributedString *)attributedText
{
    _attributedText = attributedText;
    if (self.autoRedraw) {
        [self setNeedsDisplay];
    }
}

-(void)setTextColor:(UIColor *)textColor
{
    _textColor = textColor;
    if (self.autoRedraw) {
        [self setNeedsDisplay];
    }
}

-(UIColor *)textColor
{
    if (!_textColor) {
        _textColor = [UIColor blackColor];
    }
    return _textColor;
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
    if (self.autoRedraw) {
        [self setNeedsDisplay];
    }
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
@end
