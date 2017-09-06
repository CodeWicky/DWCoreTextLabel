//
//  DWCoreTextSelectionView.h
//  DWCoreTextLabel
//
//  Created by Wicky on 2017/8/30.
//  Copyright © 2017年 Wicky. All rights reserved.
//

/**
 选中状态视图
 
 提供选中、插入状态的指示器及蒙版效果
 */
#import <UIKit/UIKit.h>
#import "DWCoreTextCommon.h"
@class DWCoreTextLayout;
@class DWCoreTextMenuItem;

typedef NS_OPTIONS(NSUInteger, DWSelectAction) {
    DWSelectActionNone = 1 << 0,///无动作
    DWSelectActionCut = 1 << 1,///剪切
    DWSelectActionCopy = 1 << 2,///复制
    DWSelectActionPaste = 1 << 3,///粘贴
    DWSelectActionSelectAll = 1 << 4,///全选
    DWSelectActionDelete = 1 << 5,///删除
    DWSelectActionCustom = 1 << 6,///自定制
};


/**
 选中效果视图
 
 提供选中效果及选中后的动作目录，提供插入指示器、拖动指示器
 */
@interface DWCoreTextSelectionView : UIView

///选中目录动作
@property (nonatomic ,assign) DWSelectAction selectAction;

///自定义目录项
@property (nonatomic ,strong) NSArray <DWCoreTextMenuItem *>* customSelectItems;

///预置动作回调
@property (nonatomic ,copy) void (^selectActionCallBack)(DWSelectAction action);

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


/**
 展示选择目录

 @param rect 要展示的位置
 */
-(void)showSelectMenuInRect:(CGRect)rect;


/**
 以当前选中区域自动展示选择目录
 */
-(void)showSelectMenu;


/**
 隐藏选择目录
 */
-(void)hideSelectMenu;

@end


/**
 插入指示器视图
 */
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

/**
 SelectView选中目录项
 
 本类配合selectionView的customSelectItems属性使用。
 由于UIMenuController自身实现导致，其所需动作实现须由其所对应添加的View实现。
 由于SelectView中会将menu添加在自身上，而导致未实现对应的custom的动作导致崩溃。
 为实现可扩展性custom属性有存在的必要性，故借助本类以及消息转发机制将消息转发至target对象，实现相应动作。
 customSelectItems数组中加入本类实例，selectionView会将对应消息转发至target。
 */
@interface DWCoreTextMenuItem : NSObject

///目录标题
@property (nonatomic ,strong) NSString * title;

///目录动作
@property (nonatomic ,assign) SEL action;

///目录动作target
@property (nonatomic ,weak) id target;

@end
