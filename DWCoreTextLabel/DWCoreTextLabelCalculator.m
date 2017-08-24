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
NSMutableAttributedString * getMAStr(DWCoreTextLabel * label,CGFloat limitWidth,NSArray * exclusionPaths) {
    NSMutableAttributedString * mAStr = [[NSMutableAttributedString alloc] initWithAttributedString:label.attributedText];
    NSUInteger length = label.attributedText?label.attributedText.length:label.text.length;
    NSMutableParagraphStyle * paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    NSRange totalRange = NSMakeRange(0, length);
    if (!label.attributedText) {
        [paragraphStyle setLineBreakMode:label.lineBreakMode];
        [paragraphStyle setLineSpacing:label.lineSpacing];
        paragraphStyle.alignment = (exclusionPaths.count == 0)?label.textAlignment:NSTextAlignmentLeft;
        NSMutableAttributedString * attributeStr = [[NSMutableAttributedString alloc] initWithString:label.text];
        [attributeStr addAttribute:NSFontAttributeName value:label.font range:totalRange];
        [attributeStr addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:totalRange];
        [attributeStr addAttribute:NSForegroundColorAttributeName value:label.textColor range:totalRange];
        mAStr = attributeStr;
    } else {
        [paragraphStyle setLineBreakMode:label.lineBreakMode];
        paragraphStyle.alignment = (exclusionPaths.count == 0)?label.textAlignment:NSTextAlignmentLeft;
        [mAStr addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:totalRange];
    }
    return mAStr;
}

///获取插入图片偏移量
NSInteger getInsertOffset(NSMutableArray * locations,NSInteger newLoc) {
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
CGSize getSuggestSize(CTFramesetterRef frameSetter,CFRange rangeToDraw,CGFloat limitWidth,NSUInteger numberOfLines) {
    CGSize restrictSize = CGSizeMake(limitWidth, MAXFLOAT);
    if (numberOfLines == 1) {
        restrictSize = CGSizeMake(MAXFLOAT, MAXFLOAT);
    }
    CGSize suggestSize = CTFramesetterSuggestFrameSizeWithConstraints(frameSetter, rangeToDraw, NULL, restrictSize, nil);
    return CGSizeMake(ceil(MIN(suggestSize.width, limitWidth)),ceil(suggestSize.height));
}

///获取计算绘制可见文本范围
CFRange getRangeToDrawForVisibleString(CTFrameRef frame) {
    return CTFrameGetVisibleStringRange(frame);
}

///获取最后一行绘制范围
CFRange getLastLineRange(CTFrameRef frame ,NSUInteger numberOfLines,CFRange visibleRange) {
    CFRange range = CFRangeMake(0, 0);
    NSRange vRange = NSMakeRange(visibleRange.location, visibleRange.length);
    if (numberOfLines == 0) {
        numberOfLines = ULONG_MAX;
    }
    CFArrayRef lines = CTFrameGetLines(frame);
    long lineCount = CFArrayGetCount(lines);
    if (lineCount > 0) {
        NSUInteger lineNum = 0;
        if (numberOfLines <= lineCount) {
            lineNum = numberOfLines;
            CTLineRef line = CFArrayGetValueAtIndex(lines, lineNum - 1);
            range = CTLineGetStringRange(line);
        } else {
            for (int i = 0; i < lineCount; i++) {
                CTLineRef line = CFArrayGetValueAtIndex(lines, i);
                
                CFRange tempRange = CTLineGetStringRange(line);
                if (NSLocationInRange(NSMaxRange(NSMakeRange(tempRange.location, tempRange.length)) - 1,vRange)) {
                    range = tempRange;
                } else {
                    break;
                }
            }
        }
    }
    return range;
}

///获取按照margin缩放的frame
UIBezierPath * getImageAcitvePath(UIBezierPath * path,CGFloat margin) {
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
CGRect getCTRunBounds(CTFrameRef frame,CTLineRef line,CGPoint origin,CTRunRef run) {
    CGFloat ascent;
    CGFloat descent;
    CGRect boundsRun = CGRectZero;
    boundsRun.size.width = CTRunGetTypographicBounds(run, CFRangeMake(0, 0), &ascent, &descent, NULL);
    boundsRun.size.height = ascent + descent;
    CGFloat xOffset = CTLineGetOffsetForStringIndex(line, CTRunGetStringRange(run).location, NULL);
    boundsRun.origin.x = origin.x + xOffset;
    boundsRun.origin.y = origin.y - descent;
    return getRectWithCTFramePathOffset(boundsRun, frame);
}

///获取CTFrame校正后的尺寸
CGRect getRectWithCTFramePathOffset(CGRect rect,CTFrameRef frame) {
    CGPathRef path = CTFrameGetPath(frame);
    CGRect colRect = CGPathGetBoundingBox(path);
    return CGRectOffset(rect, colRect.origin.x, colRect.origin.y);
}



///获取Frame的路径的横坐标偏移
CGFloat getCTFramePahtXOffset(CTFrameRef frame) {
    CGPathRef path = CTFrameGetPath(frame);
    CGRect colRect = CGPathGetBoundingBox(path);
    return colRect.origin.x;
}

///获取活动图片中包含点的字典
NSMutableDictionary * getImageDic(NSMutableArray * arr,CGPoint point) {
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
    return [NSDictionary dictionaryWithObjectsAndKeys:pathsArray,kCTFrameClippingPathsAttributeName, nil];
}

#pragma mark ---镜像转换方法---
///获取镜像path
void convertPath(UIBezierPath * path,CGRect bounds) {
    [path applyTransform:CGAffineTransformMakeScale(1, -1)];
    [path applyTransform:CGAffineTransformMakeTranslation(0, 2 * bounds.origin.y + bounds.size.height)];
}

///获取镜像frame
CGRect convertRect(CGRect rect,CGFloat height) {
    if (CGRectEqualToRect(rect, CGRectNull)) {
        return CGRectNull;
    }
    return CGRectMake(rect.origin.x, height - rect.origin.y - rect.size.height, rect.size.width, rect.size.height);
}

///平移路径
void translatePath(UIBezierPath * path,CGFloat offsetY) {
    if (offsetY == 0) {
        return;
    }
    [path applyTransform:CGAffineTransformMakeTranslation(0, offsetY)];
}


