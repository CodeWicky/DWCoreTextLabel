//
//  DWCoreTextCommon.h
//  DWCoreTextLabel
//
//  Created by Wicky on 2017/9/1.
//  Copyright © 2017年 Wicky. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef struct {
    CGFloat baseLineY;///基线纵坐标
    CGFloat xCrd;///x点横坐标
    CGFloat height;///高度
} DWPosition;

/**
 0位置，{0,0,0}
 */
UIKIT_EXTERN DWPosition const DWPositionZero;

/**
 空位置，{MAXFLOAT,MAXFLOAT,MAXFLOAT}
 */
UIKIT_EXTERN DWPosition const DWPositionNull;


/**
 初始化位置结构体

 @param baseLineY 基线纵坐标
 @param xCrd 横坐标
 @param height 位置高度
 @return 结构体
 */
DWPosition DWMakePosition(CGFloat baseLineY,CGFloat xCrd,CGFloat height);


/**
 获取位置基点

 @param p 位置
 @return 基点
 */
CGPoint DWPositionGetBaseOrigin(DWPosition p);


/**
 比较两位置是否相同

 @param p1 位置1
 @param p2 位置2
 @return 比较结果
 
 注：
 baseLineY、xCrd、height均相同的两个位置才相同
 */
BOOL DWPositionEqualToPosition(DWPosition p1,DWPosition p2);


/**
 比较当前位置是否为空

 @param p 位置
 @return 比较结果
 */
BOOL DWPositionIsNull(DWPosition p);


/**
 比较当前位置是否为0

 @param p 位置
 @return 比较结果
 */
BOOL DWPositionIsZero(DWPosition p);


/**
 比较两位置空间相对位置（高度忽略）

 @param p1 位置1
 @param p2 位置2
 @return 比较结果
 
 注：
 即比较baseOrigin的相对位置，返回值规则同DWComparePoint()
 */
NSComparisonResult DWComparePosition(DWPosition p1,DWPosition p2);


/**
 比较两位置空间相对位置是否相同（高度忽略）

 @param p1 位置1
 @param p2 位置2
 @return 比较结果
 
 注：
 即比较baseOrigin是否相同
 */
BOOL DWPositionBaseOriginEqualToPosition(DWPosition p1,DWPosition p2);


/**
 根据位置及宽度返回尺寸

 @param p 位置
 @param width 宽度
 @return 尺寸
 */
CGRect CGRectFromPosition(DWPosition p,CGFloat width);
