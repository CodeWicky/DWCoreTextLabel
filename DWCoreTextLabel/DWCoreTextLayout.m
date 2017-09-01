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

-(void)configRun:(DWCTRunWrapper *)run {
    _run = run;
}

-(void)configPreviousGlyph:(DWGlyphWrapper *)preGlyph {
    _previousGlyph = preGlyph;
    [preGlyph configNextGlyph:self];
}

-(void)configNextGlyph:(DWGlyphWrapper *)nextGlyph {
    _nextGlyph = nextGlyph;
}

-(void)configPositionWithBaseLineY:(CGFloat)baseLineY height:(CGFloat)height {
    _startPosition = DWMakePosition(baseLineY, _startXCrd, height);
    _endPosition = DWMakePosition(baseLineY, _endXCrd, height);
}

-(NSString *)debugDescription {
    NSString * string = [NSString stringWithFormat:@"%@ {",[super description]];
    string = [string stringByAppendingString:[NSString stringWithFormat:@"\n\tindex:\t%lu",self.index]];
    string = [string stringByAppendingString:[NSString stringWithFormat:@"\n\tstartXCrd:\t%.2f",self.startXCrd]];
    string = [string stringByAppendingString:[NSString stringWithFormat:@"\n\tendXCrd:\t%.2f\n}",self.endXCrd]];
    return string;
}

@end

@implementation DWCTRunWrapper

+(instancetype)createWrapperForCTRun:(CTRunRef)ctRun {
    DWCTRunWrapper * wrapper = [[DWCTRunWrapper alloc] initWithCTRun:ctRun];
    return wrapper;
}

-(instancetype)initWithCTRun:(CTRunRef)ctRun {
    if (self = [super init]) {
        CFSAFESETVALUEA2B(ctRun, _ctRun)
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

-(void)configLine:(DWCTLineWrapper *)line {
    _line = line;
}

-(void)configPreviousRun:(DWCTRunWrapper *)preRun {
    _previousRun = preRun;
    [preRun configNextRun:self];
}

-(void)configNextRun:(DWCTRunWrapper *)nextRun {
    _nextRun = nextRun;
}

-(void)handleGlyphsWithCTFrame:(CTFrameRef)ctFrame CTLine:(CTLineRef)ctLine origin:(CGPoint)origin {
    NSUInteger count = CTRunGetGlyphCount(_ctRun);
    NSMutableArray * temp = @[].mutableCopy;
    DWGlyphWrapper * preGlyph = nil;
    CGFloat baseLineY = CGRectGetMaxY(self.frame);
    CGFloat height = CGRectGetHeight(self.frame);
    for (int i = 0; i < count; i ++) {
        CGFloat offset = getCTFramePahtXOffset(ctFrame);
        NSUInteger index = _startIndex + i;
        CGFloat startXCrd = origin.x + CTLineGetOffsetForStringIndex(ctLine, index, NULL) + offset;
        CGFloat endXCrd = origin.x + CTLineGetOffsetForStringIndex(ctLine, index + 1, NULL) + offset;
        DWGlyphWrapper * wrapper = [[DWGlyphWrapper alloc] initWithIndex:index startXCrd:startXCrd endXCrd:endXCrd];
        [wrapper configRun:self];
        [wrapper configPreviousGlyph:preGlyph];
        [wrapper configPositionWithBaseLineY:baseLineY height:height];
        preGlyph = wrapper;
        [temp addObject:wrapper];
    }
    _glyphs = temp.copy;
}

-(void)handleActiveRunWithCustomLinkRegex:(NSString *)customLinkRegex autoCheckLink:(BOOL)autoCheckLink  {
    CGRect deleteBounds = self.frame;
    _isImage = NO;
    _hasAction = NO;
    _activeAttributes = nil;
    if (CGRectEqualToRect(deleteBounds,CGRectNull)) {///无活动范围跳过
        return ;
    }
    NSDictionary * attributes = self.runAttributes;
    CTRunDelegateRef delegate = (__bridge CTRunDelegateRef)[attributes valueForKey:(id)kCTRunDelegateAttributeName];
    NSMutableDictionary * dic = nil;
    if (delegate == nil) {///检测图片，不是图片检测文字
        dic = attributes[@"clickAttribute"];
        if (!dic) {///不是活动文字检测自动链接及定制链接
            if (customLinkRegex.length) {
                dic = attributes[@"customLink"];
            }
            
            if (!dic && autoCheckLink) {
                dic = attributes[@"autoCheckLink"];
            }
        }
        _activeAttributes = dic;
    } else {
        dic = CTRunDelegateGetRefCon(delegate);
        if ([dic isKindOfClass:[NSMutableDictionary class]] && dic[@"image"]) {
            _isImage = YES;
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
    if (_activeAttributes) {
        if (_activeAttributes[@"target"] && _activeAttributes[@"SEL"]) {
            _hasAction = YES;
        }
    }
}

-(NSString *)debugDescription {
    NSString * string = [NSString stringWithFormat:@"%@ {",[super description]];
    string = [string stringByAppendingString:[NSString stringWithFormat:@"\n\tframe:\t%@",NSStringFromCGRect(self.frame)]];
    string = [string stringByAppendingString:[NSString stringWithFormat:@"\n\tpreviousRun:\t%@",self.previousRun]];
    string = [string stringByAppendingString:[NSString stringWithFormat:@"\n\tnextRun:\t%@\n}",self.nextRun]];
    string = [string stringByAppendingString:[NSString stringWithFormat:@"\n\tstartIndex:\t%lu",self.startIndex]];
    string = [string stringByAppendingString:[NSString stringWithFormat:@"\n\tendIndex:\t%lu",self.endIndex]];
    string = [string stringByAppendingString:[NSString stringWithFormat:@"\n\tglyphs:\t%@\n}",self.glyphs]];
    return string;
}

-(void)dealloc {
    CFSAFERELEASE(_ctRun)
}

@end

@implementation DWCTLineWrapper

+(instancetype)createWrapperForCTLine:(CTLineRef)ctLine {
    DWCTLineWrapper * wrapper = [[DWCTLineWrapper alloc] initWithCTLine:ctLine];
    return wrapper;
}

-(instancetype)initWithCTLine:(CTLineRef)ctLine {
    if (self = [super init]) {
        CFSAFESETVALUEA2B(ctLine, _ctLine)
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
    DWCTRunWrapper * preRun = nil;
    for (int i = 0; i < count; i ++) {
        CTRunRef run = CFArrayGetValueAtIndex(runs, i);
        DWCTRunWrapper * runWrapper = [DWCTRunWrapper createWrapperForCTRun:run];
        [runWrapper configWithCTFrame:ctFrame ctLine:_ctLine origin:_lineOrigin convertHeight:height];
        [runWrapper configLine:self];
        [runWrapper configPreviousRun:preRun];
        if (considerGlyphs) {
            [runWrapper handleGlyphsWithCTFrame:ctFrame CTLine:_ctLine origin:_lineOrigin];
        }
        preRun = runWrapper;
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

-(NSString *)debugDescription {
    NSString * string = [NSString stringWithFormat:@"%@ {",[super description]];
    string = [string stringByAppendingString:[NSString stringWithFormat:@"\n\tframe:\t%@",NSStringFromCGRect(self.frame)]];
    string = [string stringByAppendingString:[NSString stringWithFormat:@"\n\trow:\t%lu",self.row]];
    string = [string stringByAppendingString:[NSString stringWithFormat:@"\n\truns:\t%@",self.runs]];
    string = [string stringByAppendingString:[NSString stringWithFormat:@"\n\tpreviousLine:\t%@",self.previousLine]];
    string = [string stringByAppendingString:[NSString stringWithFormat:@"\n\tnextLine:\t%@\n}",self.nextLine]];
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

-(void)handleActiveImageAndTextWithCustomLinkRegex:(NSString *)customLinkRegex autoCheckLink:(BOOL)autoCheckLink {
    NSMutableArray * arr = @[].mutableCopy;
    [self enumerateCTRunUsingBlock:^(DWCTRunWrapper *run, BOOL *stop) {
        [run handleActiveRunWithCustomLinkRegex:customLinkRegex autoCheckLink:autoCheckLink];
        if (run.isImage && run.activeAttributes[@"activePath"]) {
            [arr addObject:run.activeAttributes];
        }
    }];
    _activeImageConfigs = arr.copy;
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

#pragma mark --- 以角标获取相关数据 ---
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

-(DWPosition)positionAtLocation:(NSUInteger)loc {
    DWGlyphWrapper * glyph = [self glyphAtLocation:loc];
    if (!glyph) {
        return DWPositionNull;
    }
    return glyph.startPosition;
}

-(DWPosition)positionAtPoint:(CGPoint)point {
    DWGlyphWrapper * glyph = [self glyphAtPoint:point];
    if (!glyph) {
        return DWPositionNull;
    }
    CGFloat closestSide = DWClosestSide(point.x, glyph.startXCrd, glyph.endXCrd);
    if (closestSide == glyph.startXCrd) {
        return glyph.startPosition;
    }
    return glyph.endPosition;
}

-(CGFloat)xCrdAtLocation:(NSUInteger)loc {
    DWGlyphWrapper * glyph = [self glyphAtLocation:loc];
    if (!glyph) {
        return MAXFLOAT;
    }
    return glyph.startXCrd;
}

-(CGFloat)xCrdAtPoint:(CGPoint)point {
    DWGlyphWrapper * glyph = [self glyphAtPoint:point];
    if (!glyph) {
        return MAXFLOAT;
    }
    return DWClosestSide(point.x, glyph.startXCrd, glyph.endXCrd);
}

#pragma mark --- 获取指定范围内符合条件的字形矩阵尺寸数组 ---
-(NSArray *)selectedRectsBetweenLocationA:(NSUInteger)locationA andLocationB:(NSUInteger)locationB {
    if (locationB >= _maxLoc + 1) {
        return @[];
    }
    if (locationA >= locationB) {
        return @[];
    }
    locationB --;//函数出入的是不包含的locationB，所以自减至包含位置
    CGFloat startXCrd = [self xCrdAtLocation:locationA];
    CGFloat endXCrd = [self glyphAtLocation:locationB].endXCrd;
    DWCTRunWrapper * startRun = [self runAtLocation:locationA];
    DWCTRunWrapper * endRun = [self runAtLocation:locationB];
    return [self rectsInLayoutWithStartRun:startRun startXCrd:startXCrd endRun:endRun endXCrd:endXCrd];
}

-(NSArray *)selectedRectsBetweenPointA:(CGPoint)pointA andPointB:(CGPoint)pointB {
    DWCTRunWrapper * startRun = [self runAtPoint:pointA];
    DWCTRunWrapper * endRun = [self runAtPoint:pointB];
    if (startRun.startIndex > endRun.startIndex) {///保证小点在前
        DWSwapoAB(startRun, endRun);
        CGPoint temp = pointA;
        pointA = pointB;
        pointB = temp;
    }
    CGFloat startXCrd = [self xCrdAtPoint:pointA];
    CGFloat endXCrd = [self xCrdAtPoint:pointB];
    return [self rectsInLayoutWithStartRun:startRun startXCrd:startXCrd endRun:endRun endXCrd:endXCrd];
}

-(NSArray *)selectedRectsInRange:(NSRange)range {
    return [self selectedRectsBetweenLocationA:range.location andLocationB:range.location + range.length];
}

///返回run中对应的坐标之间的rect
#pragma mark --- 获取给定Run两坐标之间的所有字形矩阵尺寸数组 ---
-(NSArray *)rectInRun:(DWCTRunWrapper *)run XCrdA:(CGFloat)xCrdA xCrdB:(CGFloat)xCrdB {
    if (xCrdA > xCrdB) {
        DWSwapfAB(&xCrdA, &xCrdB);
    }
    CGRect rect = run.frame;
    rect = DWShortenRectToXCrd(rect, xCrdA, YES);
    rect = DWShortenRectToXCrd(rect, xCrdB, NO);
    return @[[NSValue valueWithCGRect:rect]];
}

#pragma mark --- 获取给定Line某点之前或之后的所有字形矩阵尺寸数组 ---
-(NSArray *)rectInLineAtLocation:(NSUInteger)loc backword:(BOOL)backward {
    if (loc > _maxLoc && backward) {
        return @[];
    }
    if (!backward && loc > _maxLoc + 1) {
        return @[];
    }
    DWCTRunWrapper * run = [self runAtLocation:loc];
    CGFloat xCrd = [self xCrdAtLocation:loc];
    return [self rectsInLineWithRun:run xCrd:xCrd backward:backward];
}

-(NSArray *)rectInLineAtPoint:(CGPoint)point backword:(BOOL)backward {
    DWCTRunWrapper * run = [self runAtPoint:point];
    CGFloat xCrd = [self xCrdAtPoint:point];
    return [self rectsInLineWithRun:run xCrd:xCrd backward:backward];
}

#pragma mark --- 返回同一行中两个run之间在两个坐标之间的字形矩阵尺寸数组 ---
-(NSArray *)rectsInLineWithStartRun:(DWCTRunWrapper *)startRun startXCrd:(CGFloat)startXCrd endRun:(DWCTRunWrapper *)endRun endXCrd:(CGFloat)endXCrd {
    if (!startRun || !endRun || startXCrd == MAXFLOAT || endXCrd == MAXFLOAT) {///参数不合法
        return @[];
    }
    if (![startRun.line isEqual:endRun.line]) {///参数不合法
        return @[];
    }
    if (startRun.startIndex > endRun.startIndex) {///保证小者在前
        DWSwapoAB(startRun, endRun);
    }
    if (startXCrd > endXCrd) {///保证小者在前
        DWSwapfAB(&startXCrd, &endXCrd);
    }
    if ([startRun isEqual:endRun]) {///在同一Run中
        return [self rectInRun:startRun XCrdA:startXCrd xCrdB:endXCrd];
    }
    ///不在同一run中
    NSMutableArray * rects = @[].mutableCopy;
    CGRect rect = startRun.frame;
    rect = DWShortenRectToXCrd(rect, startXCrd, YES);
    do {
        startRun = [self handleRect:rect withRun:startRun backward:YES container:rects];
        rect = startRun.frame;
    } while (!CGRectEqualToRect(rect, CGRectZero) && ![startRun isEqual:endRun] && startRun);
    rect = DWShortenRectToXCrd(endRun.frame, endXCrd, NO);
    [self addRect:rect toArray:rects];
    return rects.copy;
}

#pragma mark --- 获取指定CTLine所有字形矩阵尺寸数组 ---
-(NSArray *)rectsInLine:(DWCTLineWrapper *)line {
    if (!line || !line.runs.count) {
        return @[];
    }
    DWCTRunWrapper * run = line.runs.firstObject;
    if (!run) {
        return @[];
    }
    return [self rectInLineAtPoint:run.frame.origin backword:YES];
}

#pragma mark --- 返回任意两个Run直接介于起始终止坐标之间的所有字形矩阵尺寸数组 ---
-(NSArray *)rectsInLayoutWithStartRun:(DWCTRunWrapper *)startRun startXCrd:(CGFloat)startXCrd endRun:(DWCTRunWrapper *)endRun endXCrd:(CGFloat)endXCrd {
    if (!startRun || !endRun || startXCrd == MAXFLOAT || endXCrd == MAXFLOAT) {///参数不合法
        return @[];
    }
    if (startRun.startIndex > endRun.startIndex) {///参数不合法
        DWSwapoAB(startRun, endRun);
    }
    if ([startRun.line isEqual:endRun.line]) {///同一Line中
        return [self rectsInLineWithStartRun:startRun startXCrd:startXCrd endRun:endRun endXCrd:endXCrd];
    }
    ///不同行
    NSMutableArray * rects = @[].mutableCopy;
    DWCTLineWrapper * startLine = startRun.line;
    DWCTLineWrapper * endLine = endRun.line;
    [rects addObjectsFromArray:[self rectsInLineWithRun:startRun xCrd:startXCrd backward:YES]];
    while (![startLine.nextLine isEqual:endLine]) {
        startLine = startLine.nextLine;
        [rects addObjectsFromArray:[self rectsInLine:startLine]];
    }
    [rects addObjectsFromArray:[self rectsInLineWithRun:endRun xCrd:endXCrd backward:NO]];
    return rects;
}

#pragma mark --- 获取点的位置返回角标 ---
-(NSUInteger)locFromPoint:(CGPoint)point {
    DWGlyphWrapper * glyph = [self glyphAtPoint:point];
    if (!glyph) {
        return NSNotFound;
    }
    return glyph.index;
}

#pragma mark --- 工具方法 ---
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

/**
 根据指定条件返回对应Line中xCrd及相应模式对应的字形矩阵尺寸数组
 
 @param run 指定位置的CTRun
 @param xCrd 指定位置的横坐标
 @param backward 是否为向后模式
 @return 符合条件的字形矩阵尺寸数组
 */
-(NSArray *)rectsInLineWithRun:(DWCTRunWrapper *)run xCrd:(CGFloat)xCrd backward:(BOOL)backward {
    if (!run || xCrd == MAXFLOAT) {
        return @[];
    }
    NSMutableArray * rects = @[].mutableCopy;
    CGRect rect = run.frame;
    rect = DWShortenRectToXCrd(rect, xCrd, backward);
    do {
        run = [self handleRect:rect withRun:run backward:backward container:rects];
        rect = run.frame;
    } while (!CGRectEqualToRect(rect, CGRectZero) && run);
    return rects.copy;
}

-(void)addRect:(CGRect)rect toArray:(NSMutableArray *)array {
    [array addObject:[NSValue valueWithCGRect:rect]];
}


/**
 将同行中指定run之前或之后的尺寸加入容器

 @param rect 指定run的已计算好的尺寸（可能不完整）
 @param run 指定run
 @param backward 指定模式
 @param container 指定容器
 @return 下一个或上一个run
 
 注：
 本方法为循环方法中的中间方法，会将传入的rect延长至下一个矩阵区域后加入指定容器。
 并返回下一个run
 */
-(DWCTRunWrapper *)handleRect:(CGRect)rect withRun:(DWCTRunWrapper *)run backward:(BOOL)backward container:(NSMutableArray *)container {
    if (!container) {
        return nil;
    }
    if (!run) {
        return nil;
    }
    run = backward?run.nextRun:run.previousRun;
    if (!run) {
        if (CGRectEqualToRect(rect, CGRectZero)) {
            return nil;
        }
        [self addRect:rect toArray:container];
        return nil;
    }
    CGRect newR = run.frame;
    if (CGRectEqualToRect(rect, CGRectZero)) {
        return run;
    }
    CGFloat xCrd = backward?CGRectGetMinX(newR):CGRectGetMaxX(newR);
    [self addRect:DWLengthenRectToXCrd(rect, xCrd) toArray:container];
    return run;
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

@end
