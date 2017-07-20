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
} while(0)

#pragma mark --- 获取相关数据 ---

/**
 获取当前需要绘制的文本

 @param label Label控件
 @param limitWidth 宽度限制
 @return 要绘制的字符串
 
 注：此处仅处理段落样式、字体、颜色、对齐方式
 */
NSMutableAttributedString * getMAStr(DWCoreTextLabel * label,CGFloat limitWidth);

///获取插入图片偏移量
NSInteger getInsertOffset(NSMutableArray * locations,NSInteger newLoc);

///获取绘制尺寸
CGSize getSuggestSize(CTFramesetterRef frameSetter,CGFloat limitWidth,NSMutableAttributedString * str,NSUInteger numberOfLines,CFDictionaryRef exclusionDic);

///获取计算绘制可见文本范围
NSRange getRangeToDrawForVisibleString(NSAttributedString * aStr,UIBezierPath * drawPath);

///获取绘制Frame范围
CFRange getRangeToDraw(CTFramesetterRef frameSetter,CGFloat limitWidth,NSMutableAttributedString * str,NSUInteger numberOfLines);

///获取最后一行绘制范围
CFRange getLastLineRange(CTFramesetterRef frameSetter,CGFloat limitWidth,NSUInteger numberOfLines);

///获取按照margin缩放的frame
UIBezierPath * getImageAcitvePath(UIBezierPath * path,CGFloat margin);

///获取CTRun的frame
CGRect getCTRunBounds(CTFrameRef frame,CTLineRef line,CGPoint origin,CTRunRef run);

///获取活动图片中包含点的字典
NSMutableDictionary * getImageDic(NSMutableArray * arr,CGPoint point);

///获取活动文字中包含点的字典
NSMutableDictionary * getActiveTextDic(NSMutableArray * arr,CGPoint point);

///获取自动链接中包含点的字典
NSMutableDictionary * getAutoLinkDic(NSMutableArray * arr,CGPoint point);

/**
 根据插入图片的位置对range的偏移进行校正

 @param range 原始range
 @param arrLocationImgHasAdd 插入图片位置的数组
 @return 校正后的range
 */
NSRange getRangeOffset(NSRange range,NSMutableArray * arrLocationImgHasAdd);

///返回目标范围排除指定范围后的结果数组
NSArray * getRangeExcept(NSRange targetRange,NSRange exceptRange);

/**
 返回排除区域字典

 @param paths 需要排除的区域数组
 @param viewBounds 实际绘制bounds
 @return 排除区域的配置字典
 */
NSDictionary * getExclusionDic(NSArray * paths,CGRect viewBounds);

#pragma mark ---镜像转换方法---
///获取镜像path
void convertPath(UIBezierPath * path,CGRect bounds);

///获取镜像frame
CGRect convertRect(CGRect rect,CGFloat height);
