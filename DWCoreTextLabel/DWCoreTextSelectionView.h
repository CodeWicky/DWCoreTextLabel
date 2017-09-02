//
//  DWCoreTextSelectionView.h
//  DWCoreTextLabel
//
//  Created by Wicky on 2017/8/30.
//  Copyright © 2017年 Wicky. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DWCoreTextCommon.h"
@class DWCoreTextLayout;

@interface DWCoreTextSelectionView : UIView

/**
 更新选中区域
 
 @param rects 选中区域尺寸数组
 
 @return 更新是否成功
 */
-(BOOL)updateSelectedRects:(NSArray *)rects;


/**
 更新两拖动指示器位置

 @param startP 起始范围拖动指示器位置
 @param endP 范围终止拖动指示器位置
 
 @return 更新是否成功
 */
-(BOOL)updateGrabberWithStartPosition:(DWPosition)startP endPosition:(DWPosition)endP;


/**
 更新选中区域
 
 @param rects 选中区域
 @param startP 起始范围拖动指示器位置
 @param endP 终止范围拖动指示器位置
 
 @return 更新是否成功
 */
-(BOOL)updateSelectedRects:(NSArray *)rects startGrabberPosition:(DWPosition)startP endGrabberPosition:(DWPosition)endP;


/**
 更新插入指示器位置

 @param position 位置
 
 @return 更新是否成功
 */
-(BOOL)updateCaretWithPosition:(DWPosition)position;

@end

@interface DWCoreTextCaretView : UIView

///是否闪烁
@property (nonatomic ,assign ,getter=isBlinking) BOOL blinks;

///是否可见
@property (nonatomic ,assign ,readonly ,getter=isVisible) BOOL visible;


/**
 生成插入指示器

 @param position 位置
 @return 插入指示器
 */
-(instancetype)initWithPosition:(DWPosition)position;

///显示插入指示器
-(void)showCaret;

///隐藏插入指示器
-(void)hideCaret;

/**
 保持底部坐标不变的情况下更新高度

 @param height 要更新的高度
 
 注：
 默认基线为下，所以保持底部坐标不变
 */
-(void)updateHeight:(CGFloat)height;


/**
 移动插入指示器

 @param baseLineY 基线纵坐标
 @param xCrd 指定位置横坐标
 */
-(void)moveToBaseLineY:(CGFloat)baseLineY xCrd:(CGFloat)xCrd;


/**
 设置插入指示器

 @param position 指定插入指示器的位置
 */
-(void)moveToPosition:(DWPosition)position;

@end


/**
 选中范围拖动指示器
 */
@interface DWCoreTextGrabber : DWCoreTextCaretView

@property (nonatomic ,assign) BOOL startGrabber;

@end
