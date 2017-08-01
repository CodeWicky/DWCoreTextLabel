//
//  DWCoreTextLabelCalculator.h
//  DWCoreTextLabel
//
//  Created by Wicky on 2017/7/20.
//  Copyright © 2017年 Wicky. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreText/CoreText.h>
@class DWCoreTextLabel;

//安全释放
#define CFSAFERELEASE(a)\
do {\
if(a != NULL) {\
CFRelease(a);\
}\
} while(0);

#pragma mark --- 获取相关数据 ---

/**
 获取当前需要绘制的文本

 @param label Label控件
 @param limitWidth 宽度限制
 @param exclusionPaths 排除区域数组
 @return 要绘制的字符串
 
 注：此处仅处理段落样式、字体、颜色、对齐方式，不处理高亮、插入图片、文末省略
 */
NSMutableAttributedString * getMAStr(DWCoreTextLabel * label,CGFloat limitWidth,NSArray * exclusionPaths);

/**
 获取插入图片偏移量

 @param locations 已插入数组
 @param newLoc 目标插入位置（不考虑偏移）
 @return 实际插入位置（偏移校正后）
 */
NSInteger getInsertOffset(NSMutableArray * locations,NSInteger newLoc);

/**
 获取建议绘制尺寸

 @param frameSetter 获取大致绘制尺寸
 @param rangeToDraw 需要绘制的范围
 @param limitWidth 宽度限制
 @param numberOfLines 行数
 @return 建议绘制尺寸
 
 注：仅在无排除区域时计算有效
 */
CGSize getSuggestSize(CTFramesetterRef frameSetter,CFRange rangeToDraw,CGFloat limitWidth,NSUInteger numberOfLines);

/**
 获取计算绘制可见文本范围

 @param frame 绘制frame
 @return 返回可见范围
 */
CFRange getRangeToDrawForVisibleString(CTFrameRef frame);

/**
 获取最后一行绘制范围

 @param frame 绘制frame
 @param numberOfLines 行数
 @param visibleRange 可见范围
 @return 最后一行范围
 */
CFRange getLastLineRange(CTFrameRef frame,NSUInteger numberOfLines,CFRange visibleRange);

/**
 根据margin获取图片实际响应区域

 @param path 图片围绕区域
 @param margin 图片围绕区域内缩进
 @return 图片实际响应区域
 */
UIBezierPath * getImageAcitvePath(UIBezierPath * path,CGFloat margin);

/**
 获取CTRun对应的实际尺寸

 @param frame 绘制frame
 @param line CTRun所在CTLine
 @param origin CTLine对应原点
 @param run CTRun
 @return 返回CTRun对应的实际尺寸
 
 注：此坐标为系统坐标，需于屏幕坐标进行转换
 */
CGRect getCTRunBounds(CTFrameRef frame,CTLineRef line,CGPoint origin,CTRunRef run);

/**
 获取活动图片中包含点的字典

 @param arr 所有活动图片配置的数组
 @param point 当前点击的point
 @return 返回当前点击的点对应的活动图片配置
 */
NSMutableDictionary * getImageDic(NSMutableArray * arr,CGPoint point);

/**
 获取活动文字中包含点的字典

 @param arr 所有活动文字配置的数组
 @param point 当前点击的point
 @return 返回当前点击的点对应的活动文字配置
 */
NSMutableDictionary * getActiveTextDic(NSMutableArray * arr,CGPoint point);

///获取自动链接中包含点的字典

/**
 获取自动链接中包含点的字典

 @param arr 所有自动链接配置的数组
 @param point 当前点击的point
 @return 返回当前点击的点对应的自动链接配置
 */
NSMutableDictionary * getAutoLinkDic(NSMutableArray * arr,CGPoint point);

/**
 根据插入图片的位置对range的偏移进行校正

 @param range 原始range
 @param arrLocationImgHasAdd 插入图片位置的数组
 @return 校正后的range
 */
NSRange getRangeOffset(NSRange range,NSMutableArray * arrLocationImgHasAdd);

/**
 返回目标范围排除指定范围后的结果数组

 @param targetRange 目标范围
 @param exceptRange 需要排除的范围
 @return 返回排除范围后的范围
 */
NSArray * getRangeExcept(NSRange targetRange,NSRange exceptRange);

/**
 返回排除区域字典

 @param paths 需要排除的区域数组
 @param viewBounds 实际绘制bounds
 @return 排除区域的配置字典
 */
NSDictionary * getExclusionDic(NSArray * paths,CGRect viewBounds);

#pragma mark ---镜像转换方法---

/**
 获取镜像path

 @param path 原始路径
 @param bounds 需要镜像的尺寸
 */
void convertPath(UIBezierPath * path,CGRect bounds);

/**
 获取镜像frame

 @param rect 原始尺寸
 @param height 需要镜像的高度
 @return 镜像后的尺寸
 */
CGRect convertRect(CGRect rect,CGFloat height);


/**
 平移路径

 @param path 原始路径
 @param offsetY 纵向平移距离
 */
void translatePath(UIBezierPath * path,CGFloat offsetY);
