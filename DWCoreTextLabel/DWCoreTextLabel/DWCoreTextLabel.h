//
//  DWCoreTextLabel.h
//  DWCoreTextLabel
//
//  Created by Wicky on 16/12/4.
//  Copyright © 2016年 Wicky. All rights reserved.
//

/**
 DWCoreTextLabel
 以coreText形式实现的label控件
 
 version 1.0.0
 实现基本文本展示相关属性
 重写sizeToFit、sizeThatFits:方法
 
 version 1.0.1
 移除sizeToFit、sizeThatFits:方法
 添加排除区域组
 添加自动重绘标签
 添加绘制图片api
 */

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, DWTextVerticalAlignment) {
    DWTextVerticalAlignmentCenter,
    DWTextVerticalAlignmentTop,
    DWTextVerticalAlignmentBottom
};

typedef NS_ENUM(NSUInteger, DWTextImageDrawMode) {
    DWTextImageDrawModeSurround,
    DWTextImageDrawModeCover,
    DWTextImageDrawModeInsert
};

@interface DWCoreTextLabel : UIView

///普通文本
@property (nonatomic ,strong) NSString * text;

///文本区域内距
@property (nonatomic ,assign) UIEdgeInsets textInsets;

///文本颜色
@property (nonatomic ,strong) UIColor * textColor;

///行数
@property (nonatomic ,assign) NSUInteger numberOflines;

///断行模式
@property (nonatomic ,assign) NSLineBreakMode lineBreakMode;

///字体
@property (nonatomic ,strong) UIFont * font;

///富文本
@property (nonatomic ,strong) NSAttributedString * attributedText;

///水平对齐方式
@property (nonatomic ,assign) NSTextAlignment textAlignment;

///垂直对齐方式
@property (nonatomic ,assign) DWTextVerticalAlignment textVerticalAlignment;

///行间距
@property (nonatomic ,assign) CGFloat lineSpacing;

///排除区域组
/**
 注：设置排除区域后，对齐方式失效
 排除区域位于文本区域外部，排除区域失效
 */
@property (nonatomic ,strong) NSMutableArray<UIBezierPath *> * exclusionPaths;

///自动重绘
/**
 默认关闭，开启后设置需要重绘的属性后自动重绘
 */
@property (nonatomic ,assign) BOOL autoRedraw;

-(void)drawImage:(UIImage *)image atFrame:(CGRect)frame drawMode:(DWTextImageDrawMode)mode;

@end
