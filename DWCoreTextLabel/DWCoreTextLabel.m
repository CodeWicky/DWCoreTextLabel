//
//  DWCoreTextLabel.m
//  DWCoreTextLabel
//
//  Created by Wicky on 16/12/4.
//  Copyright © 2016年 Wicky. All rights reserved.
//

#import "DWCoreTextLabel.h"
#import <CoreText/CoreText.h>

@implementation DWCoreTextLabel
@synthesize font = _font;
@synthesize textColor = _textColor;

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
    
    CGMutablePathRef path = CGPathCreateMutable();//创建绘制区域
    CGPathAddRect(path, NULL, frame);//添加绘制尺寸
    CTFrameRef _frame = CTFramesetterCreateFrame(frameSetter, CFRangeMake(0, mAStr.length), path, NULL);//工厂根据绘制区域及富文本（可选范围，多次设置）设置frame
    CTFrameDraw(_frame, context);//根据frame绘制上下文
    CFRelease(path);
    CFRelease(frameSetter);
}

-(NSMutableAttributedString *)getMAStr
{
    ///解决水平对齐方式
    NSMutableParagraphStyle   *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle setLineSpacing:5.5];//行间距
    paragraphStyle.alignment = self.textAlignment;
    
    NSRange totalRange = NSMakeRange(0, self.text.length);
    NSMutableAttributedString * mAStr = [[NSMutableAttributedString alloc] initWithAttributedString:self.attributedText];
    if (!self.attributedText) {
        NSMutableAttributedString * attributeStr = [[NSMutableAttributedString alloc] initWithString:self.text];
        [attributeStr addAttribute:NSFontAttributeName value:self.font range:totalRange];
        [attributeStr addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:totalRange];
        [attributeStr addAttribute:(NSString *)NSForegroundColorAttributeName value:self.textColor range:totalRange];
        mAStr = attributeStr;
    }
    return mAStr;
}

-(CGSize)getSuggestSizeWithFrameSetter:(CTFramesetterRef)frameSetter
                      limitWidth:(CGFloat)limitWidth
{
    CGSize restrictSize = CGSizeMake(limitWidth, CGFLOAT_MAX);//创建预估计尺寸
    CGSize suggestSize = CTFramesetterSuggestFrameSizeWithConstraints(frameSetter, CFRangeMake(0, 0), nil, restrictSize, nil);//根据工厂生成建议尺寸。宽度不变，高度自适应
    return suggestSize;
}

#pragma mark ---method override---
-(void)sizeToFit
{
    CGRect frame = self.frame;
    frame.size = [self sizeThatFits:CGSizeMake(self.bounds.size.width, 0)];
    self.frame = frame;
}

-(CGSize)sizeThatFits:(CGSize)size
{
    CGFloat limitWidth = (size.width - self.textInsets.left - self.textInsets.right) > 0 ? (self.bounds.size.width - self.textInsets.left - self.textInsets.right) : 0;
    NSMutableAttributedString * mAStr = [self getMAStr];
    CTFramesetterRef frameSetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)mAStr);//一个frame的工厂，负责生成frame
    
    CGSize suggestSize = [self getSuggestSizeWithFrameSetter:frameSetter limitWidth:limitWidth];
    
    return CGSizeMake(suggestSize.width + self.textInsets.left + self.textInsets.right, suggestSize.height + self.textInsets.top + self.textInsets.bottom);
}
#pragma mark ---setter、getter---
-(void)setText:(NSString *)text
{
    _text = text;
    [self setNeedsDisplay];
}

-(void)setTextAlignment:(NSTextAlignment)textAlignment
{
    _textAlignment = textAlignment;
    [self setNeedsDisplay];
}

-(void)setTextVerticalAlignment:(DWTextVerticalAlignment)textVerticalAlignment
{
    _textVerticalAlignment = textVerticalAlignment;
    [self setNeedsDisplay];
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
    [self setNeedsDisplay];
}

-(void)setTextInsets:(UIEdgeInsets)textInsets
{
    _textInsets = textInsets;
    [self setNeedsDisplay];
}

-(void)setAttributedText:(NSAttributedString *)attributedText
{
    _attributedText = attributedText;
    [self setNeedsDisplay];
}

-(void)setTextColor:(UIColor *)textColor
{
    _textColor = textColor;
    [self setNeedsDisplay];
}

-(UIColor *)textColor
{
    if (!_textColor) {
        _textColor = [UIColor blackColor];
    }
    return _textColor;
}




@end
