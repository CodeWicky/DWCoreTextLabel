//
//  DWCoreTextLabelCalculator.m
//  DWCoreTextLabel
//
//  Created by Wicky on 2017/7/20.
//  Copyright © 2017年 Wicky. All rights reserved.
//

#import "DWCoreTextLabelCalculator.h"
#import "DWCoreTextLabel.h"
#import "DWCoreTextLayout.h"

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

NSRange NSRangeFromCFRange(CFRange range) {
    return NSMakeRange(range.location, range.length);
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

CFRange getVisibleRangeFromLastRange(CFRange visibleRange,CFRange lastRange) {
    CFRange range = CFRangeMake(0, 0);
    range.location = MIN(visibleRange.location, lastRange.location);
    NSUInteger maxLocVisible = visibleRange.location + visibleRange.length;
    NSUInteger maxLocLast = lastRange.location + lastRange.length;
    range.length = maxLocVisible < maxLocLast ? maxLocVisible - range.location : maxLocLast - range.location;
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

///获取绘制所需尺寸
CGRect getDrawFrame(CTFrameRef ctFrame,CGFloat height,BOOL startFromZero) {
    DWCoreTextLayout * layout = [DWCoreTextLayout layoutWithCTFrame:ctFrame convertHeight:height considerGlyphs:NO];
    __block CGRect desFrame = CGRectNull;
    if (startFromZero) {
        desFrame = CGRectZero;
    }
    [layout.lines enumerateObjectsUsingBlock:^(DWCTLineWrapper * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        CGRect temp = obj.frame;
        if (CGRectEqualToRect(desFrame, CGRectNull)) {
            desFrame = temp;
            return ;
        }
        desFrame = CGRectUnion(temp, desFrame);
    }];
    return desFrame;
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
NSMutableDictionary * getImageDic(NSArray * arr,CGPoint point) {
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

///将给定数组中的路径根据偏移量校正路径后放入指定容器
void handleExclusionPathArr(NSMutableArray * container,NSArray * pathArr,CGFloat offset) {
    [pathArr enumerateObjectsUsingBlock:^(UIBezierPath * obj, NSUInteger idx, BOOL * _Nonnull stop) {
        translatePath(obj, offset);
        [container addObject:obj];
    }];
}


#pragma mark --- 镜像转换方法 ---
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


#pragma mark --- 比较方法 ---
///在一定精度内判断两个浮点数是否相等
BOOL DWFixEqual(CGFloat a,CGFloat b) {
    if (fabs(a - b) < 1e-6) {
        return YES;
    }
    return NO;
}

///返回给定数在所给范围中的相对位置
NSComparisonResult DWNumBetweenAB(CGFloat num,CGFloat a,CGFloat b) {
    if (a > b) {
        DWSwapfAB(&a, &b);
    }
    if (num < a) {
        if (DWFixEqual(a,num)) {
            return NSOrderedSame;
        }
        return NSOrderedAscending;
    } else if (num > b) {
        if (DWFixEqual(b,num)) {
            return NSOrderedSame;
        }
        return NSOrderedDescending;
    } else {
        return NSOrderedSame;
    }
}


#pragma mark --- 空间位置关系方法 ---
///返指给定点在给定尺寸中的竖直位置关系
NSComparisonResult DWPointInRectV(CGPoint point,CGRect rect) {
    return DWNumBetweenAB(point.y, CGRectGetMinY(rect), CGRectGetMaxY(rect));
}

///返指给定点在给定尺寸中的水平位置关系
NSComparisonResult DWPointInRectH(CGPoint point,CGRect rect) {
    return DWNumBetweenAB(point.x, CGRectGetMinX(rect), CGRectGetMaxX(rect));
}

///返回距离指定坐标较近的一侧的坐标值
CGFloat DWClosestSide(CGFloat xCrd,CGFloat left,CGFloat right) {
    if (right < left) {
        DWSwapfAB(&left, &right);
    }
    CGFloat mid = (left + right) / 2;
    if (xCrd > mid) {
        return right;
    } else {
        return left;
    }
}

///返回给定点是否在给定尺寸的修正范围内
BOOL DWRectFixContainsPoint(CGRect rect,CGPoint point) {
    rect = CGRectInset(rect, 0, -0.25);
    return CGRectContainsPoint(rect, point);
}

///比较指定坐标在给定尺寸中的位置
NSComparisonResult DWCompareXCrdWithRect(CGFloat xCrd,CGRect rect) {
    CGFloat min = CGRectGetMinX(rect);
    CGFloat max = CGRectGetMaxX(rect);
    return DWNumBetweenAB(xCrd, min, max);
}


#pragma mark --- 尺寸修正方法 ---
///修正尺寸至指定坐标
CGRect DWFixRectToXCrd(CGRect rect,CGFloat xCrd,NSComparisonResult result,BOOL backward) {
    if (CGRectEqualToRect(rect, CGRectZero)) {
        return CGRectZero;
    }
    if (result == NSOrderedDescending) {
        rect.size.width = xCrd - rect.origin.x;
    } else if (result == NSOrderedAscending) {
        rect.size.width += rect.origin.x - xCrd;
        rect.origin.x = xCrd;
    } else if (backward) {
        rect.size.width += rect.origin.x - xCrd;
        rect.origin.x = xCrd;
    } else {
        rect.size.width = xCrd - rect.origin.x;
    }
    if (CGRectGetWidth(rect) <= 0) {
        return CGRectZero;
    }
    return rect;
}

///缩短CGRect至指定坐标
CGRect DWShortenRectToXCrd(CGRect rect,CGFloat xCrd,BOOL backward) {
    if (!backward && xCrd == CGRectGetMaxX(rect)) {
        return rect;
    }
    if (backward && xCrd == CGRectGetMinX(rect)) {
        return rect;
    }
    NSComparisonResult result = DWCompareXCrdWithRect(xCrd, rect);
    if (result == NSOrderedSame) {
        return DWFixRectToXCrd(rect, xCrd, result, backward);
    } else {
        return CGRectZero;
    }
}

///延长尺寸至指定坐标
CGRect DWLengthenRectToXCrd(CGRect rect,CGFloat xCrd) {
    BOOL backward = YES;
    NSComparisonResult result = DWCompareXCrdWithRect(xCrd, rect);
    if (result == NSOrderedSame) {
        if (xCrd != CGRectGetMaxX(rect) && xCrd != CGRectGetMinX(rect)) {
            return CGRectZero;
        }
        return rect;
    } else if (result == NSOrderedAscending) {
        backward = NO;
    }
    return DWFixRectToXCrd(rect, xCrd, result, backward);
}

NSComparisonResult DWComparePoint(CGPoint p1,CGPoint p2) {
    if (CGPointEqualToPoint(p1, p2)) {
        return NSOrderedSame;
    }
    if (p2.y > p1.y) {
        return NSOrderedAscending;
    } else if (p2.y == p1.y && p2.x > p1.x) {
        return NSOrderedAscending;
    }
    return NSOrderedDescending;
}

#pragma mark --- 尺寸组合方法 ---

NSValue * DWValueFromRect(CGRect rect) {
    return [NSValue valueWithCGRect:rect];
}

NSValue * DWRectValue(CGFloat x,CGFloat y,CGFloat w,CGFloat h) {
    return DWValueFromRect(CGRectMake(x, y, w, h));
}

NSArray * DWRectsBeyondRect(CGRect target,CGRect origin) {
    if (!CGRectIntersectsRect(origin, target)) {
        return @[DWValueFromRect(target)];
    }
    if (CGRectContainsRect(origin,target)) {
        return @[];
    }
    if (CGRectContainsRect(target, origin)) {
        return nil;
    }
    CGRect intersectR = CGRectIntersection(target, origin);
    NSInteger section = 0;
    if (CGRectGetMinY(intersectR) == CGRectGetMinY(target)) {///上边
        section += 1;
    }
    if (CGRectGetMinX(intersectR) == CGRectGetMinX(target)) {///左边
        section += 2;
    }
    if (CGRectGetMaxY(intersectR) == CGRectGetMaxY(target)) {///下边
        section += 4;
    }
    if (CGRectGetMaxX(intersectR) == CGRectGetMaxX(target)) {///右边
        section += 8;
    }
    //  ________________   ________________    ________________    _______________
    //  |  3 | 1  | 9  |   |    |    |    |    |    |    |    |    |        |    |
    //  |____|____|____|   |____|____|____|    |____|    |____|    |        |    |
    //  |  2 | 0  | 8  |   |       10     |    |    | 5  |    |    |   7    |    |
    //  |____|____|____|   |______________|    |____|    |____|    |        |    |
    //  |  6 | 4  | 12 |   |    |    |    |    |    |    |    |    |        |    |
    //  |____|____|____|   |____|____|____|    |____|____|____|    |________|____|
    //
    //
    //  ________________   ________________    ________________
    //  |              |   |    |         |    |              |
    //  |______________|   |    |         |    |      11      |
    //  |              |   |    |   13    |    |              |
    //  |      14      |   |    |         |    |______________|
    //  |              |   |    |         |    |              |
    //  |______________|   |____|_________|    |______________|
    //
    NSMutableArray * arr = @[].mutableCopy;
    if (section == 1) {
        [arr addObject:DWRectValue(target.origin.x, target.origin.y, CGRectGetMinX(intersectR) - CGRectGetMinX(target), target.size.height)];
        [arr addObjectsFromArray:DWRectsBeyondRect(CGRectMake(intersectR.origin.x, intersectR.origin.y, CGRectGetMaxX(target) - CGRectGetMinX(intersectR), target.size.height), origin)];
    } else if (section == 2) {
        [arr addObject:DWRectValue(target.origin.x, target.origin.y, target.size.width, intersectR.origin.y - target.origin.y)];
        [arr addObjectsFromArray:DWRectsBeyondRect(CGRectMake(intersectR.origin.x, intersectR.origin.y, target.size.width, CGRectGetMaxY(target) - intersectR.origin.y), origin)];
    } else if (section == 3) {
        [arr addObject:DWRectValue(CGRectGetMaxX(intersectR), target.origin.y, target.size.width - intersectR.size.width, target.size.height)];
        [arr addObject:DWRectValue(target.origin.x, CGRectGetMaxY(intersectR), intersectR.size.width, target.size.height - intersectR.size.height)];
    } else if (section == 4) {
        [arr addObject:DWRectValue(CGRectGetMaxX(intersectR), target.origin.y, CGRectGetMaxX(target) - CGRectGetMaxX(intersectR), target.size.height)];
        [arr addObjectsFromArray:DWRectsBeyondRect(CGRectMake(target.origin.x, target.origin.y, CGRectGetMaxX(intersectR) - target.origin.x, target.size.height), origin)];
    } else if (section == 5) {
        [arr addObject:DWRectValue(target.origin.x, target.origin.y, CGRectGetMinX(intersectR) - CGRectGetMinX(target), target.size.height)];
        [arr addObject:DWRectValue(CGRectGetMaxX(intersectR), intersectR.origin.y, CGRectGetMaxX(target) - CGRectGetMaxX(intersectR), target.size.height)];
    } else if (section == 6) {
        [arr addObject:DWRectValue(target.origin.x, target.origin.y, target.size.width, target.size.height - intersectR.size.height)];
        [arr addObject:DWRectValue(CGRectGetMaxX(intersectR), intersectR.origin.y, target.size.width - intersectR.size.width, intersectR.size.height)];
    } else if (section == 7) {
        [arr addObject:DWRectValue(CGRectGetMaxX(intersectR), target.origin.y, target.size.width - intersectR.size.width, target.size.height)];
    } else if (section == 8) {
        [arr addObject:DWRectValue(target.origin.x, target.origin.y, target.size.width, intersectR.origin.y - target.origin.y)];
        [arr addObjectsFromArray:DWRectsBeyondRect(CGRectMake(target.origin.x, intersectR.origin.y, target.size.width, CGRectGetMaxY(target) - intersectR.origin.y), origin)];
    } else if (section == 9) {
        [arr addObject:DWRectValue(target.origin.x, target.origin.y, target.size.width - intersectR.size.width, intersectR.size.height)];
        [arr addObject:DWRectValue(target.origin.x,CGRectGetMaxY(intersectR), target.size.width, target.size.height - intersectR.size.height)];
    } else if (section == 10) {
        [arr addObject:DWRectValue(target.origin.x, target.origin.y, target.size.width, CGRectGetMinY(intersectR) - CGRectGetMinY(target))];
        [arr addObject:DWRectValue(intersectR.origin.x, CGRectGetMaxY(intersectR), target.size.width, CGRectGetMaxY(target) - CGRectGetMaxY(intersectR))];
    } else if (section == 11) {
        [arr addObject:DWRectValue(target.origin.x, CGRectGetMaxY(intersectR), target.size.width, target.size.height - intersectR.size.height)];
    } else if (section == 12) {
        [arr addObject:DWRectValue(target.origin.x, target.origin.y, target.size.width, target.size.height - intersectR.size.height)];
        [arr addObject:DWRectValue(target.origin.x, CGRectGetMaxY(target) - intersectR.size.height, target.size.width - intersectR.size.width, intersectR.size.height)];
    } else if (section == 13) {
        [arr addObject:DWRectValue(target.origin.x, target.origin.y, target.size.width - intersectR.size.width, target.size.height)];
    } else if (section == 14) {
        [arr addObject:DWRectValue(target.origin.x, target.origin.y, target.size.width, target.size.height - intersectR.size.height)];
    }
    return arr.copy;
}


#pragma mark --- 交换对象方法 ---
///交换浮点数
void DWSwapfAB(CGFloat *a,CGFloat *b) {
    CGFloat temp = *a;
    *a = *b;
    *b = temp;
}

///交换对象
void DWSwapoAB(id a,id b) {
    id temp = a;
    a = b;
    b = temp;
}
