//
//  DWCoreTextLabelCalculator.m
//  DWCoreTextLabel
//
//  Created by Wicky on 2017/7/20.
//  Copyright © 2017年 Wicky. All rights reserved.
//

#import "DWCoreTextLabelCalculator.h"
#import "DWCoreTextLabel.h"

#pragma mark --- 获取相关数据 ---
///获取当前需要绘制的文本
NSMutableAttributedString * getMAStr(DWCoreTextLabel * label,CGFloat limitWidth)
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
NSInteger getInsertOffset(NSMutableArray * locations,NSInteger newLoc)
{
    NSNumber * loc = [NSNumber numberWithInteger:newLoc];
    if (locations.count == 0) {//如果数组是空的，直接添加位置，并返回0
        [locations addObject:loc];
        return 0;
    }
    [locations addObject:loc];//否则先插入，再排序
    [locations sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {//升序排序方法
        if ([obj1 integerValue] > [obj2 integerValue]) {
            return (NSComparisonResult)NSOrderedDescending;
        }
        
        if ([obj1 integerValue] < [obj2 integerValue]) {
            return (NSComparisonResult)NSOrderedAscending;
        }
        return (NSComparisonResult)NSOrderedSame;
    }];
    return [locations indexOfObject:loc];//返回本次插入图片的偏移量
}

///获取绘制尺寸
CGSize getSuggestSize(CTFramesetterRef frameSetter,CGFloat limitWidth,NSMutableAttributedString * str,NSUInteger numberOfLines,CFDictionaryRef exclusionDic) {
    CGSize restrictSize = CGSizeMake(limitWidth, MAXFLOAT);
    if (numberOfLines == 1) {
        restrictSize = CGSizeMake(MAXFLOAT, MAXFLOAT);
    }
    CFRange rangeToDraw = getRangeToDraw(frameSetter,limitWidth,str,numberOfLines);
    CGSize suggestSize = CTFramesetterSuggestFrameSizeWithConstraints(frameSetter, rangeToDraw, exclusionDic, restrictSize, nil);
    return CGSizeMake(MIN(suggestSize.width, limitWidth), suggestSize.height);
}

///获取计算绘制可见文本范围
NSRange getRangeToDrawForVisibleString(NSAttributedString * aStr,UIBezierPath * drawPath)
{
    CTFramesetterRef tempFrameSetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)aStr);
    CTFrameRef tempFrame = CTFramesetterCreateFrame(tempFrameSetter, CFRangeMake(0, aStr.length), drawPath.CGPath, NULL);
    CFRange range = CTFrameGetVisibleStringRange(tempFrame);
    CFSAFERELEASE(tempFrame);
    CFSAFERELEASE(tempFrameSetter);
    return NSMakeRange(range.location, range.length);
}

///获取绘制Frame范围
CFRange getRangeToDraw(CTFramesetterRef frameSetter,CGFloat limitWidth,NSMutableAttributedString * str,NSUInteger numberOfLines)
{
    CFRange rangeToDraw = CFRangeMake(0, str.length);
    CFRange range = getLastLineRange(frameSetter,limitWidth,numberOfLines);
    if (range.length > 0) {
        rangeToDraw = CFRangeMake(0, range.location + range.length);
    }
    return rangeToDraw;
}

///获取最后一行绘制范围
CFRange getLastLineRange(CTFramesetterRef frameSetter,CGFloat limitWidth,NSUInteger numberOfLines)
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
UIBezierPath * getImageAcitvePath(UIBezierPath * path,CGFloat margin)
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
CGRect getCTRunBounds(CTFrameRef frame,CTLineRef line,CGPoint origin,CTRunRef run)
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
NSMutableDictionary * getImageDic(NSMutableArray * arr,CGPoint point)
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
NSMutableDictionary * getGivenDic(CGPoint point,NSMutableArray * arr)
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
NSMutableDictionary * getActiveTextDic(NSMutableArray * arr,CGPoint point)
{
    return getGivenDic(point,arr);
}

///获取自动链接中包含点的字典
NSMutableDictionary * getAutoLinkDic(NSMutableArray * arr,CGPoint point)
{
    return getGivenDic(point,arr);
}

///矫正range偏移量
NSRange getRangeOffset(NSRange range,NSMutableArray * arrLocationImgHasAdd) {
    __block NSRange newRange = range;
    [arrLocationImgHasAdd enumerateObjectsUsingBlock:^(NSNumber * location, NSUInteger idx, BOOL * _Nonnull stop) {
        if (location.integerValue <= range.location) {
            newRange.location ++;
        } else if (location.integerValue <= (range.location + range.length - 1)) {
            newRange.length ++;
        }
    }];
    return newRange;
}

///返回目标范围排除指定范围后的结果数组
NSArray * getRangeExcept(NSRange targetRange,NSRange exceptRange) {
    NSRange interRange = NSIntersectionRange(targetRange, exceptRange);
    if (interRange.length == 0) {
        return nil;
    } else if (NSEqualRanges(targetRange, interRange)) {
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

///返回排除区域字典
NSDictionary * getExclusionDic(NSArray * paths,CGRect viewBounds) {
    if (paths.count == 0) {
        return NULL;
    }
    NSMutableArray *pathsArray = [[NSMutableArray alloc] init];
    [paths enumerateObjectsUsingBlock:^(UIBezierPath * obj, NSUInteger idx, BOOL * _Nonnull stop) {
        convertPath(obj, viewBounds);
        NSDictionary *clippingPathDictionary = [NSDictionary dictionaryWithObject:(__bridge id)(obj.CGPath) forKey:(__bridge NSString *)kCTFramePathClippingPathAttributeName];
        [pathsArray addObject:clippingPathDictionary];
    }];
    
    int eFrameWidth=0;
    CFNumberRef frameWidth = CFNumberCreate(NULL, kCFNumberNSIntegerType, &eFrameWidth);
    
    int eFillRule = kCTFramePathFillEvenOdd;
    CFNumberRef fillRule = CFNumberCreate(NULL, kCFNumberNSIntegerType, &eFillRule);
    
    int eProgression = kCTFrameProgressionTopToBottom;
    CFNumberRef progression = CFNumberCreate(NULL, kCFNumberNSIntegerType, &eProgression);
    
    CFStringRef keys[] = { kCTFrameClippingPathsAttributeName, kCTFramePathFillRuleAttributeName, kCTFrameProgressionAttributeName, kCTFramePathWidthAttributeName};
    CFTypeRef values[] = { (__bridge CFTypeRef)(pathsArray), fillRule, progression, frameWidth};
    CFDictionaryRef clippingPathsDictionary = CFDictionaryCreate(NULL,
                                                                 (const void **)&keys, (const void **)&values,
                                                                 sizeof(keys) / sizeof(keys[0]),
                                                                 &kCFTypeDictionaryKeyCallBacks,
                                                                 &kCFTypeDictionaryValueCallBacks);

    return [NSDictionary dictionaryWithObjectsAndKeys:pathsArray,kCTFrameClippingPathsAttributeName,@(kCTFramePathFillEvenOdd),kCTFramePathFillRuleAttributeName,@(kCTFrameProgressionTopToBottom),kCTFrameProgressionAttributeName,@0,kCTFramePathWidthAttributeName, nil];
}

#pragma mark ---镜像转换方法---
///获取镜像path
void convertPath(UIBezierPath * path,CGRect bounds)
{
    [path applyTransform:CGAffineTransformMakeScale(1, -1)];
    [path applyTransform:CGAffineTransformMakeTranslation(0, 2 * bounds.origin.y + bounds.size.height)];
}

///获取镜像frame
CGRect convertRect(CGRect rect,CGFloat height)
{
    return CGRectMake(rect.origin.x, height - rect.origin.y - rect.size.height, rect.size.width, rect.size.height);
}


