//
//  DWCoreTextLayout.m
//  DWCoreTextLabel
//
//  Created by Wicky on 2017/8/10.
//  Copyright © 2017年 Wicky. All rights reserved.
//

#import "DWCoreTextLayout.h"
#import "DWCoreTextLabelCalculator.h"

@implementation DWGlyphWrapper

-(instancetype)initWithIndex:(NSUInteger)index startXCrd:(CGFloat)startXCrd endXCrd:(CGFloat)endXCrd {
    if (self = [super init]) {
        _index = index;
        _startXCrd = startXCrd;
        _endXCrd = endXCrd;
    }
    return self;
}

@end

@implementation DWCTRunWrapper

+(instancetype)createWrapperForCTRun:(CTRunRef)ctRun {
    DWCTRunWrapper * wrapper = [[DWCTRunWrapper alloc] initWithCTRun:ctRun];
    return wrapper;
}

-(instancetype)initWithCTRun:(CTRunRef)ctRun {
    if (self = [super init]) {
        _ctRun = ctRun;
        _runAttributes = (NSDictionary *)CTRunGetAttributes(ctRun);
        CFRange range = CTRunGetStringRange(_ctRun);
        _startIndex = range.location;
        _endIndex = range.location + range.length;
    }
    return self;
}

-(void)configWithCTFrame:(CTFrameRef)ctFrame ctLine:(CTLineRef)ctLine origin:(CGPoint)origin convertHeight:(CGFloat)height {
    _runRect = getCTRunBounds(ctFrame, ctLine, origin, _ctRun);
    _frame = convertRect(_runRect, height);
}

-(void)handleGlyphsWithCTFrame:(CTFrameRef)ctFrame CTLine:(CTLineRef)ctLine origin:(CGPoint)origin {
    NSUInteger count = CTRunGetGlyphCount(_ctRun);
    NSMutableArray * temp = @[].mutableCopy;
    for (int i = 0; i < count; i ++) {
        CGFloat offset = getCTFramePahtXOffset(ctFrame);
        NSUInteger index = _startIndex + i;
        CGFloat startXCrd = origin.x + CTLineGetOffsetForStringIndex(ctLine, index, NULL) + offset;
        CGFloat endXCrd = origin.x + CTLineGetOffsetForStringIndex(ctLine, index + 1, NULL) + offset;
        DWGlyphWrapper * wrapper = [[DWGlyphWrapper alloc] initWithIndex:index startXCrd:startXCrd endXCrd:endXCrd];
        [temp addObject:wrapper];
    }
    _glyphs = temp.copy;
}

-(void)handleActiveRun {
    CGRect deleteBounds = self.frame;
    if (CGRectEqualToRect(deleteBounds,CGRectNull)) {///无活动范围跳过
        return ;
    }
    CTRunDelegateRef delegate = (__bridge CTRunDelegateRef)[_runAttributes valueForKey:(id)kCTRunDelegateAttributeName];
    if (delegate) {
        NSMutableDictionary * dic = CTRunDelegateGetRefCon(delegate);
        if ([dic isKindOfClass:[NSMutableDictionary class]]) {
            UIImage * image = dic[@"image"];
            if (image) {///检测图片，不是图片跳过
                _isImage = YES;
                if (dic[@"SEL"] && dic[@"target"]) {
                    _hasAction = YES;
                } else {
                    _hasAction = NO;
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
                _activeAttributes = dic;
            }
        }
    } else {
        _isImage = NO;
    }
}

-(NSString *)description {
    NSString * string = [NSString stringWithFormat:@"%@ {",[super description]];
    string = [string stringByAppendingString:[NSString stringWithFormat:@"\n\tframe:\t%@",NSStringFromCGRect(self.frame)]];
    string = [string stringByAppendingString:[NSString stringWithFormat:@"\n\tstartIndex:\t%lu",self.startIndex]];
    string = [string stringByAppendingString:[NSString stringWithFormat:@"\n\tendIndex:\t%lu",self.endIndex]];
    string = [string stringByAppendingString:[NSString stringWithFormat:@"\n\truns:\t%@\n}",self.glyphs]];
    return string;
}

@end

@implementation DWCTLineWrapper

+(instancetype)createWrapperForCTLine:(CTLineRef)ctLine {
    DWCTLineWrapper * wrapper = [[DWCTLineWrapper alloc] initWithCTLine:ctLine];
    return wrapper;
}

-(instancetype)initWithCTLine:(CTLineRef)ctLine {
    if (self = [super init]) {
        _ctLine = ctLine;
        CFRange range = CTLineGetStringRange(ctLine);
        _startIndex = range.location;
        _endIndex = range.location + range.length;
    }
    return self;
}

-(void)configWithOrigin:(CGPoint)origin row:(NSUInteger)row ctFrame:(CTFrameRef)ctFrame convertHeight:(CGFloat)height {
    _lineOrigin = origin;
    _row = row;
    CGFloat lineAscent;
    CGFloat lineDescent;
    CGFloat lineWidth = CTLineGetTypographicBounds(_ctLine, &lineAscent, &lineDescent, nil);
    CGRect boundsLine = CGRectMake(0, - lineDescent, lineWidth, lineAscent + lineDescent);
    boundsLine = CGRectOffset(boundsLine, origin.x, origin.y);
    _lineRect = getRectWithCTFramePathOffset(boundsLine, ctFrame);
    _frame = convertRect(_lineRect, height);
}

-(void)configCTRunsWithCTFrame:(CTFrameRef)ctFrame convertHeight:(CGFloat)height considerGlyphs:(BOOL)considerGlyphs {
    CFArrayRef runs = CTLineGetGlyphRuns(_ctLine);
    NSUInteger count = CFArrayGetCount(runs);
    NSMutableArray * runsA = @[].mutableCopy;
    for (int i = 0; i < count; i ++) {
        CTRunRef run = CFArrayGetValueAtIndex(runs, i);
        DWCTRunWrapper * runWrapper = [DWCTRunWrapper createWrapperForCTRun:run];
        [runWrapper configWithCTFrame:ctFrame ctLine:_ctLine origin:_lineOrigin convertHeight:height];
        if (considerGlyphs) {
            [runWrapper handleGlyphsWithCTFrame:ctFrame CTLine:_ctLine origin:_lineOrigin];
        }
        [runsA addObject:runWrapper];
    }
    _runs = runsA.copy;
}

-(void)configPreviousLine:(DWCTLineWrapper *)preLine {
    _previousLine = preLine;
    [preLine configNextLine:self];
}

-(void)configNextLine:(DWCTLineWrapper *)nextLine {
    _nextLine = nextLine;
}

-(NSString *)description {
    NSString * string = [NSString stringWithFormat:@"%@ {",[super description]];
    string = [string stringByAppendingString:[NSString stringWithFormat:@"\n\tframe:\t%@",NSStringFromCGRect(self.frame)]];
    string = [string stringByAppendingString:[NSString stringWithFormat:@"\n\trow:\t%lu",self.row]];
    string = [string stringByAppendingString:[NSString stringWithFormat:@"\n\truns:\t%@\n}",self.runs]];
    return string;
}

-(void)dealloc {
    CFSAFERELEASE(_ctLine)
}

@end

@implementation DWCoreTextLayout
+(instancetype)layoutWithCTFrame:(CTFrameRef)ctFrame convertHeight:(CGFloat)height considerGlyphs:(BOOL)considerGlyphs {
    DWCoreTextLayout * layout = [[DWCoreTextLayout alloc] initWithCTFrame:ctFrame convertHeight:height considerGlyphs:considerGlyphs];
    return layout;
}

-(instancetype)initWithCTFrame:(CTFrameRef)ctFrame convertHeight:(CGFloat)height considerGlyphs:(BOOL)considerGlyphs {
    if (self = [super init]) {
        CFArrayRef arrLines = CTFrameGetLines(ctFrame);
        NSUInteger count = CFArrayGetCount(arrLines);
        CGPoint points[count];
        CTFrameGetLineOrigins(ctFrame, CFRangeMake(0, 0), points);
        CFRange range = CTFrameGetStringRange(ctFrame);
        _maxLoc = range.location + range.length - 1;
        DWCTLineWrapper * previousLine = nil;
        NSMutableArray * lineA = @[].mutableCopy;
        for (int i = 0; i < count; i++) {
            CTLineRef line = CFArrayGetValueAtIndex(arrLines, i);
            DWCTLineWrapper * lineWrap = [DWCTLineWrapper createWrapperForCTLine:line];
            [lineWrap configWithOrigin:points[i] row:i ctFrame:ctFrame convertHeight:height];
            [lineWrap configCTRunsWithCTFrame:ctFrame convertHeight:height considerGlyphs:considerGlyphs];
            [lineWrap configPreviousLine:previousLine];
            previousLine = lineWrap;
            [lineA addObject:lineWrap];
        }
        _lines = lineA.copy;
    }
    return self;
}

-(void)handleActiveImageAndText {
    [self enumerateCTRunUsingBlock:^(DWCTRunWrapper *run, BOOL *stop) {
        [run handleActiveRun];
    }];
}

-(void)enumerateCTRunUsingBlock:(void (^)(DWCTRunWrapper *, BOOL *))handler {
    if (!handler || self.lines.count == 0) {
        return;
    }
    
    BOOL stop = NO;
    for (int i = 0; i < self.lines.count; i ++) {
        DWCTLineWrapper * line = self.lines[i];
        for (int j = 0; j < line.runs.count; j ++) {
            DWCTRunWrapper * runW = line.runs[j];
            handler(runW,&stop);
            if (stop) {
                break;
            }
        }
    }
}

-(DWCTLineWrapper *)lineAtLocation:(NSUInteger)loc {
    if (loc > _maxLoc) {
        return nil;
    }
    __block DWCTLineWrapper * line = nil;
    [self binarySearchInContainer:self.lines condition:^NSComparisonResult(DWCTLineWrapper * obj, NSUInteger currentIdx, BOOL *stop) {
        if (obj.startIndex <= loc && obj.endIndex > loc) {
            line = obj;
            return NSOrderedSame;
        } else if (obj.startIndex > loc) {
            return NSOrderedAscending;
        } else {
            return NSOrderedDescending;
        }
    }];
    
    return line;
}

-(DWCTRunWrapper *)runAtLocation:(NSUInteger)loc {
    DWCTLineWrapper * line = [self lineAtLocation:loc];
    if (!line) {
        return nil;
    }
    __block DWCTRunWrapper * run = nil;
    [self binarySearchInContainer:line.runs condition:^NSComparisonResult(DWCTRunWrapper * obj, NSUInteger currentIdx, BOOL *stop) {
        if (obj.startIndex <= loc && obj.endIndex > loc) {
            run = obj;
            return NSOrderedSame;
        } else if (obj.startIndex > loc) {
            return NSOrderedAscending;
        } else {
            return NSOrderedDescending;
        }
    }];
    return run;
}

-(DWGlyphWrapper *)glyphAtLocation:(NSUInteger)loc {
    DWCTRunWrapper * run = [self runAtLocation:loc];
    if (!run) {
        return nil;
    }
    NSUInteger idx = loc - run.startIndex;
    if (idx >= run.glyphs.count) {
        return nil;
    }
    return run.glyphs[idx];
}

-(DWCTLineWrapper *)lineAtPoint:(CGPoint)point {
    __block DWCTLineWrapper * line = nil;
    [self binarySearchInContainer:self.lines condition:^NSComparisonResult(DWCTLineWrapper * obj, NSUInteger currentIdx, BOOL *stop) {
        if (DWRectFixContainsPoint(obj.frame, point)) {
            line = obj;
            return NSOrderedSame;
        } else {
            NSComparisonResult result = DWPointInRectV(point, obj.frame);
            if (result == NSOrderedSame) {
                return DWPointInRectH(point, obj.frame);
            } else {
                return result;
            }
        }
    }];
    return line;
}

-(DWCTRunWrapper *)runAtPoint:(CGPoint)point {
    DWCTLineWrapper * line = [self lineAtPoint:point];
    if (!line) {
        return nil;
    }
    __block DWCTRunWrapper * run = nil;
    [self binarySearchInContainer:line.runs condition:^NSComparisonResult(DWCTRunWrapper * obj, NSUInteger currentIdx, BOOL *stop) {
        if (DWRectFixContainsPoint(obj.frame, point)) {
            run = obj;
            return NSOrderedSame;
        } else {
            return DWNumBetweenAB(point.x, CGRectGetMinX(obj.frame), CGRectGetMaxX(obj.frame));
        }
    }];
    return run;
}

-(DWGlyphWrapper *)glyphAtPoint:(CGPoint)point {
    DWCTRunWrapper * run = [self runAtPoint:point];
    if (!run) {
        return nil;
    }
    __block DWGlyphWrapper * glyph = nil;
    [self binarySearchInContainer:run.glyphs condition:^NSComparisonResult(DWGlyphWrapper * obj, NSUInteger currentIdx, BOOL *stop) {
        NSComparisonResult result = DWNumBetweenAB(point.x, obj.startXCrd, obj.endXCrd);
        if (result == NSOrderedSame) {
            glyph = obj;
        }
        return result;
    }];
    return glyph;
}



/**
 二分法查找数组中指定元素
 
 @param container 需要查找的有序容器
 @param condition 对比条件
        - obj 当前找到元素
        - currentIdx 当前找到角标
        - *stop 是否停止查找
 
 eg. 在给定数组@[@1,@2,@3,@4,@5]中查找@2的角标
 
        NSArray * arr = @[@1,@2,@3,@4,@5];
        __block NSUInteger idx = NSNotFound;
        [self binarySearchInContainer:arr condition:^NSComparisonResult(NSNumber * obj, NSUInteger currentIdx, BOOL *stop) {
            if ([obj isEqualToNumber:@2]) {
                idx = currentIdx;
                return NSOrderedSame;
            } else if (obj.integerValue > 2) {
                return NSOrderedAscending;
            } else {
                return NSOrderedDescending;
            }
        }];
        if (idx == NSNotFound) {
            NSLog(@"未找到@2");
        } else {
            NSLog(@"元素@2的角标为%lu",idx);
        }
 
 注：
 1.当condition为nil的时候会立刻返回
 2.请确保被查找容器为有序容器
 3.当查找到所需元素时，返回NSOrderedSame以停止查找过程
 当未查找到所需元素时，返回NSOrderedAscending以检测角标较小的一侧
 当未查找到所需元素时，返回NSOrderedDescending以检测角标较大的一侧
 4.任何时候，可以通过修改stop为YES以停止查找过程
 */
-(void)binarySearchInContainer:(NSArray *)container condition:(NSComparisonResult(^)(id obj,NSUInteger currentIdx,BOOL * stop))condition {
    if (!condition || container.count == 0) {
        return;
    }
    NSUInteger hR = container.count - 1;
    NSUInteger lR = 0;
    NSUInteger mR = 0;
    BOOL stop = NO;
    while (lR <= hR) {
        mR = (hR + lR) / 2;
        NSComparisonResult result = condition(container[mR],mR,&stop);
        if (result == NSOrderedSame || stop == YES) {
            break;
        } else if (result == NSOrderedAscending) {
            if (mR == 0) {
                break;
            } else {
                hR = mR - 1;
            }
        } else {
            if (mR == container.count - 1) {
                break;
            } else {
                lR = mR + 1;
            }
        }
    }
}

static inline BOOL DWRectFixContainsPoint(CGRect rect,CGPoint point) {
    rect = CGRectInset(rect, 0, -0.25);
    return CGRectContainsPoint(rect, point);
}

static inline NSComparisonResult DWNumBetweenAB(CGFloat num,CGFloat a,CGFloat b) {
    if (a > b) {
        CGFloat temp = a;
        a = b;
        b = temp;
    }
    if (num < a) {
        return NSOrderedAscending;
    } else if (num > b) {
        return NSOrderedDescending;
    } else {
        return NSOrderedSame;
    }
}

static inline NSComparisonResult DWPointInRectV(CGPoint point,CGRect rect) {
    return DWNumBetweenAB(point.y, CGRectGetMinY(rect), CGRectGetMaxY(rect));
}

static inline NSComparisonResult DWPointInRectH(CGPoint point,CGRect rect) {
    return DWNumBetweenAB(point.x, CGRectGetMinX(rect), CGRectGetMaxX(rect));
}
@end
