//
//  DWCoreTextSelectionView.m
//  DWCoreTextLabel
//
//  Created by Wicky on 2017/8/30.
//  Copyright © 2017年 Wicky. All rights reserved.
//

#import "DWCoreTextSelectionView.h"

@interface DWCoreTextSelectionView ()

@property (nonatomic ,strong) UIView * maskViewsContainer;

@property (nonatomic ,strong) UIView * indicatorContainer;

@property (nonatomic ,strong) DWCoreTextGrabber * startGrabber;

@property (nonatomic ,strong) DWCoreTextGrabber * endGrabber;

@property (nonatomic ,strong) DWCoreTextCaretView * caret;

@property (nonatomic ,strong) NSArray * selArr;

@property (nonatomic ,strong) NSMutableArray * selectedRects;

@end

@implementation DWCoreTextSelectionView

-(BOOL)updateGrabberWithStartPosition:(DWPosition)startP endPosition:(DWPosition)endP {
    if (DWPositionIsNull(startP) || DWPositionIsNull(endP)) {
        return NO;
    }
    if (DWPositionIsZero(startP) || DWPositionIsZero(endP)) {
        [self.startGrabber hideCaret];
        [self.endGrabber hideCaret];
        return YES;
    }
    if (DWComparePosition(startP, endP) == NSOrderedDescending) {
        DWPosition temp = startP;
        startP = endP;
        endP = temp;
    }
    [self.caret hideCaret];
    [self.startGrabber showCaret];
    [self.endGrabber showCaret];
    [self.startGrabber moveToPosition:startP];
    [self.endGrabber moveToPosition:endP];
    return YES;
}

-(BOOL)updateSelectedRects:(NSArray *)rects {
    [self hideSelectMenu];
    [self.maskViewsContainer.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];///移除全部遮罩
    CGRect box = self.maskViewsContainer.bounds;
    __block BOOL updated = NO;
    NSMutableArray * selectedRects = @[].mutableCopy;
    [rects enumerateObjectsUsingBlock:^(NSValue * obj, NSUInteger idx, BOOL * _Nonnull stop) {
        CGRect rect = [obj CGRectValue];
        if (CGRectIsEmpty(rect) || CGRectIsEmpty(CGRectIntersection(rect, box))) {
            return ;
        }
        if (!updated) {
            updated = YES;
        }
        [selectedRects addObject:obj];
        UIView * mask = [[UIView alloc] initWithFrame:rect];
        mask.backgroundColor = [UIColor colorWithRed:30 / 255.0 green:144 / 255.0 blue:1 alpha:0.3];
        [self.maskViewsContainer addSubview:mask];
    }];
    if (updated) {
        self.selectedRects = selectedRects;
    }
    return updated;
}

-(BOOL)updateSelectedRects:(NSArray *)rects startGrabberPosition:(DWPosition)startP endGrabberPosition:(DWPosition)endP {
    BOOL updated = [self updateGrabberWithStartPosition:startP endPosition:endP];
    if (updated) {
        updated |= [self updateSelectedRects:rects];
    }
    return updated;
}

-(BOOL)updateCaretWithPosition:(DWPosition)position {
    if (DWPositionIsNull(position)) {
        return NO;
    }
    if (DWPositionIsZero(position)) {
        [self.caret hideCaret];
        return YES;;
    }
    [self updateSelectedRects:@[]];
    [self.startGrabber hideCaret];
    [self.endGrabber hideCaret];
    [self.caret showCaret];
    [self.caret moveToPosition:position];
    return YES;
}

-(void)showSelectMenu {
    __block CGRect rect = [self.selectedRects.firstObject CGRectValue];
    [self.selectedRects enumerateObjectsUsingBlock:^(NSValue * obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (idx == 0) {
            return;
        }
        rect = CGRectUnion(rect, obj.CGRectValue);
    }];
    [self showSelectMenuInRect:rect];
}

-(void)hideSelectMenu {
    UIMenuController * menu = [UIMenuController sharedMenuController];
    [menu setMenuVisible:NO];
}

-(void)showSelectMenuInRect:(CGRect)rect {
    [self becomeFirstResponder];
    UIMenuController * menu = [UIMenuController sharedMenuController];
    NSMutableArray * actions = @[].mutableCopy;
    if (self.selectAction & DWSelectActionCopy) {
        [actions addObject:[[UIMenuItem alloc] initWithTitle:@"复制" action:@selector(dw_copy:)]];
    }
    if (self.selectAction & DWSelectActionCut) {
        [actions addObject:[[UIMenuItem alloc] initWithTitle:@"剪切" action:@selector(dw_cut:)]];
    }
    if (self.selectAction & DWSelectActionPaste) {
        [actions addObject:[[UIMenuItem alloc] initWithTitle:@"粘贴" action:@selector(dw_paste:)]];
    }
    if (self.selectAction & DWSelectActionSelectAll) {
        [actions addObject:[[UIMenuItem alloc] initWithTitle:@"全选" action:@selector(dw_selectAll:)]];
    }
    if (self.selectAction & DWSelectActionDelete) {
        [actions addObject:[[UIMenuItem alloc] initWithTitle:@"删除" action:@selector(dw_delete:)]];
    }
    if (self.selectAction & DWSelectActionCustom) {
        
        if (self.customSelectItems.count) {
            __block NSMutableArray * temp = @[].mutableCopy;
            [self.customSelectItems enumerateObjectsUsingBlock:^(DWCoreTextMenuItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                [temp addObject:[[UIMenuItem alloc] initWithTitle:obj.title action:obj.action]];
            }];
            [actions addObjectsFromArray:temp];
        }
    }
    menu.menuItems = actions;
    [menu setTargetRect:rect inView:self];
    [menu setMenuVisible:YES animated:YES];
}

-(NSArray *)customSelectActions {
    NSMutableArray * arr = @[].mutableCopy;
    return arr.copy;
}

-(void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    self.maskViewsContainer.frame = self.bounds;
    self.indicatorContainer.frame = self.bounds;
}

-(UIView *)maskViewsContainer {
    if (!_maskViewsContainer) {
        _maskViewsContainer = [[UIView alloc] initWithFrame:self.bounds];
        [self addSubview:_maskViewsContainer];
    }
    return _maskViewsContainer;
}

-(UIView *)indicatorContainer {
    if (!_indicatorContainer) {
        _indicatorContainer = [[UIView alloc] initWithFrame:self.bounds];
        [self addSubview:_indicatorContainer];
    }
    return _indicatorContainer;
}

-(BOOL)canBecomeFirstResponder {
    return YES;
}

-(BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    NSString * actionStr = NSStringFromSelector(action);
    DWSelectAction actionO = DWSelectActionNone;
    if ([actionStr isEqualToString:@"dw_cut:"]) {
        actionO = DWSelectActionCut;
    } else if ([actionStr isEqualToString:@"dw_copy:"]) {
        actionO = DWSelectActionCopy;
    } else if ([actionStr isEqualToString:@"dw_paste:"]) {
        actionO = DWSelectActionPaste;
    } else if ([actionStr isEqualToString:@"dw_selectAll:"]) {
        actionO = DWSelectActionSelectAll;
    } else if ([actionStr isEqualToString:@"dw_delete:"]) {
        actionO = DWSelectActionDelete;
    } else {
        if ([self.selArr containsObject:actionStr]) {
            actionO = DWSelectActionCustom;
        }
    }
    return (self.selectAction & actionO) && !(actionO & DWSelectActionNone);
}

-(void)dw_cut:(UIMenuController *)menu {
    if (self.selectActionCallBack) {
        self.selectActionCallBack(DWSelectActionCut);
    }
}

-(void)dw_copy:(UIMenuController *)menu {
    if (self.selectActionCallBack) {
        self.selectActionCallBack(DWSelectActionCopy);
    }
}

-(void)dw_paste:(UIMenuController *)menu {
    if (self.selectActionCallBack) {
        self.selectActionCallBack(DWSelectActionPaste);
    }
}

-(void)dw_selectAll:(UIMenuController *)menu {
    if (self.selectActionCallBack) {
        self.selectActionCallBack(DWSelectActionSelectAll);
    }
}

-(void)dw_delete:(UIMenuController *)menu {
    if (self.selectActionCallBack) {
        self.selectActionCallBack(DWSelectActionDelete);
    }
}

-(id)forwardingTargetForSelector:(SEL)aSelector {
    __block id target = nil;
    [self.customSelectItems enumerateObjectsUsingBlock:^(DWCoreTextMenuItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (aSelector == obj.action) {
            target = obj.target;
            *stop = YES;
        }
    }];
    return target;
}

-(NSArray *)selArr {
    NSMutableArray * arr = @[].mutableCopy;
    [self.customSelectItems enumerateObjectsUsingBlock:^(DWCoreTextMenuItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [arr addObject:NSStringFromSelector(obj.action)];
    }];
    return arr.copy;
}

-(DWCoreTextCaretView *)caret {
    if (!_caret) {
        _caret = [[DWCoreTextCaretView alloc] initWithPosition:DWPositionZero];
        _caret.blinks = YES;
        [self.indicatorContainer addSubview:_caret];
    }
    return _caret;
}

-(DWCoreTextGrabber *)startGrabber {
    if (!_startGrabber) {
        _startGrabber = [[DWCoreTextGrabber alloc] initWithPosition:DWPositionZero];
        _startGrabber.startGrabber = YES;
        [self.indicatorContainer addSubview:_startGrabber];
    }
    return _startGrabber;
}

-(DWCoreTextGrabber *)endGrabber {
    if (!_endGrabber) {
        _endGrabber = [[DWCoreTextGrabber alloc] initWithPosition:DWPositionZero];
        [self.indicatorContainer addSubview:_endGrabber];
    }
    return _endGrabber;
}

@end

@implementation DWCoreTextCaretView

-(instancetype)initWithPosition:(DWPosition)position {
    if (self = [super init]) {
        self.frame = CGRectFromPosition(position, 1);
        self.backgroundColor = [UIColor colorWithRed:30 / 255.0 green:144 / 255.0 blue:1 alpha:1];
        self.layer.cornerRadius = 0.5;
    }
    return self;
}

-(void)setBlinks:(BOOL)blinks {
    if (blinks != _blinks) {
        _blinks = blinks;
        if (blinks) {
            if (self.isVisible) {
                [self.layer addAnimation:DWCoreTextCaretBlinkAnimation() forKey:@"blinkAnimation"];
            }
        } else {
            [self.layer removeAnimationForKey:@"blinkAnimation"];
        }
    }
}

-(void)showCaret {
    if (!self.isVisible) {
        self.hidden = NO;
        self.blinks = YES;
    }
}

-(void)hideCaret {
    if (self.isVisible) {
        self.blinks = NO;
        self.hidden = YES;
    }
}

-(void)updateHeight:(CGFloat)height {
    [self moveToPosition:DWMakePosition(CGRectGetMaxY(self.frame), CGRectGetMinX(self.frame), height,0)];
}

-(void)moveToBaseLineY:(CGFloat)baseLineY xCrd:(CGFloat)xCrd {
    [self moveToPosition:DWMakePosition(baseLineY, xCrd, CGRectGetHeight(self.frame),0)];
}

-(void)moveToPosition:(DWPosition)position {
    CGRect frame = self.frame;
    CGFloat oB = CGRectGetMaxY(frame);
    CGFloat oX = CGRectGetMinX(frame);
    CGFloat oH = CGRectGetHeight(frame);
    DWPosition oP = DWMakePosition(oB, oX, oH,0);
    if (!DWPositionEqualToPosition(position, oP)) {
        frame.origin.y = position.baseLineY - position.height;
        frame.origin.x = position.xCrd;
        frame.size.height = position.height;
        self.frame = frame;
    }
}

-(BOOL)isVisible {
    return !self.hidden && (self.alpha > 0);
}

CABasicAnimation * DWCoreTextCaretBlinkAnimation () {
    static CABasicAnimation * animation = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        animation = [CABasicAnimation animationWithKeyPath:@"hidden"];
        animation.duration = 1.12;
        animation.fromValue = @1;
        animation.toValue = @0;
        animation.fillMode = kCAFillModeForwards;
        animation.repeatCount = MAXFLOAT;
        animation.removedOnCompletion = NO;
    });
    return animation;
}
@end

@interface DWCoreTextGrabber ()

@property (nonatomic ,strong) UIView * dot;

@property (nonatomic ,assign) BOOL needsResetPot;

@end

@implementation DWCoreTextGrabber
@dynamic blinks;

-(instancetype)initWithPosition:(DWPosition)position {
    if (self = [super initWithPosition:position]) {
        _needsResetPot = YES;
    }
    return self;
}

-(void)moveToPosition:(DWPosition)position {
    [super moveToPosition:position];
    _needsResetPot = YES;
}

-(void)layoutSubviews {
    [super layoutSubviews];
    if (!self.dot) {
        self.dot = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
        self.dot.backgroundColor = self.backgroundColor;
        self.dot.layer.cornerRadius = 5;
        [self addSubview:self.dot];
    }
    if (_needsResetPot) {
        if (self.startGrabber) {
            self.dot.center = CGPointMake(1, 0);
        } else {
            self.dot.center = CGPointMake(0, self.bounds.size.height);
        }
        _needsResetPot = NO;
    }
}

-(void)setStartGrabber:(BOOL)startGrabber {
    if (_startGrabber != startGrabber) {
        _startGrabber = startGrabber;
        _needsResetPot = YES;
    }
}

-(void)setBlinks:(BOOL)blinks {
    ///不做动作
}
@end

@implementation DWCoreTextMenuItem

@end
