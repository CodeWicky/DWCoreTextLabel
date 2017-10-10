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
@class DWCoreTextLayout;

///安全释放
#define CFSAFERELEASE(a)\
do {\
if(a) {\
CFRelease(a);\
a = NULL;\
}\
} while(0);

///安全赋值
#define CFSAFESETVALUEA2B(a,b)\
do {\
CFSAFERELEASE(b)\
if (a) {\
CFRetain(a);\
b = a;\
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
 转换range

 @param range CFRange
 @return NSRange
 */
NSRange NSRangeFromCFRange(CFRange range);

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
 通过最后一行区域获取修正后的可见区域

 @param visibleRange 当前可见区域
 @param lastRange 当前最后一行区域
 @return 修正后的可见区域
 */
CFRange getVisibleRangeFromLastRange(CFRange visibleRange,CFRange lastRange);

/**
 根据margin获取图片实际响应区域

 @param path 图片围绕区域
 @param margin 图片围绕区域内缩进
 @return 图片实际响应区域
 */
UIBezierPath * getImageAcitvePath(UIBezierPath * path,CGFloat margin);


/**
 根据CTFrame及转换视图高度获取将要绘制的frame

 @param ctFrame 计算用的绘制Frame
 @param height 视图高度
 @param startFromZero 是否从0开始计算
 @return 将要绘制的尺寸
 
 注：
 sizeThatFits中从零开始计算，正常绘制时不从零计算
 */
CGRect getDrawFrame(CTFrameRef ctFrame,CGFloat height,BOOL startFromZero);

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
 获取尺寸相对于Frame的路径校正后的尺寸

 @param rect 原始尺寸
 @param frame 对应CTFrame
 @return 校正后尺寸
 */
CGRect getRectWithCTFramePathOffset(CGRect rect,CTFrameRef frame);

/**
 获取Frame的路径的横坐标偏移

 @param frame 对应CTFrame
 @return 横坐标偏移量
 */
CGFloat getCTFramePahtXOffset(CTFrameRef frame);

/**
 获取活动图片中包含点的字典

 @param arr 所有活动图片配置的数组
 @param point 当前点击的point
 @return 返回当前点击的点对应的活动图片配置
 */
NSMutableDictionary * getImageDic(NSArray * arr,CGPoint point);

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

/**
 将给定数组中的路径根据偏移量校正路径后放入指定容器

 @param container 指定容器
 @param pathArr 给定路径数组
 @param offset 纵向偏移量
 */
void handleExclusionPathArr(NSMutableArray * container,NSArray * pathArr,CGFloat offset);


#pragma mark --- 镜像转换方法 ---
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


#pragma mark --- 比较方法 ---
/**
 返回给定数在所给范围中的相对位置
 
 @param num 给定数
 @param a 范围A
 @param b 范围B
 @return 返回相对位置
 
 注：
 当num在数轴上位于[a,b]左侧时返回NSOrderedAscending，右侧返回NSOrderedDescending，包含关系返回NSOrderedSame
 */
NSComparisonResult DWNumBetweenAB(CGFloat num,CGFloat a,CGFloat b);


#pragma mark --- 空间位置关系方法 ---
/**
 返指给定点在给定尺寸中的竖直位置关系
 
 @param point 指定点
 @param rect 给定尺寸
 @return 相对竖直位置
 
 注：
 返回结果定义同DWNumBetweenAB()
 */
NSComparisonResult DWPointInRectV(CGPoint point,CGRect rect);

/**
 返指给定点在给定尺寸中的水平位置关系
 
 @param point 指定点
 @param rect 给定尺寸
 @return 相对水平位置
 
 注：
 返回结果定义同DWNumBetweenAB()
 */
NSComparisonResult DWPointInRectH(CGPoint point,CGRect rect);

/**
 返回距离指定坐标较近的一侧的坐标值
 
 @param xCrd 指定坐标
 @param left 左侧坐标
 @param right 右侧坐标
 @return 较近一侧的坐标
 
 注：
 当左右坐标传入空间位置矛盾时会自动交换左右坐标
 */
CGFloat DWClosestSide(CGFloat xCrd,CGFloat left,CGFloat right);

/**
 返回给定点是否在给定尺寸的修正范围内

 @param rect 给定尺寸
 @param point 给定点
 @return 是否包含
 */
BOOL DWRectFixContainsPoint(CGRect rect,CGPoint point);

/**
 比较指定坐标在给定尺寸中的位置
 
 @param xCrd 指定坐标
 @param rect 给定尺寸
 @return 相对位置
 
 注：
 返回结果定义同DWNumBetweenAB()
 */
NSComparisonResult DWCompareXCrdWithRect(CGFloat xCrd,CGRect rect);


#pragma mark --- 尺寸修正方法 ---
/**
 缩短CGRect至指定坐标
 
 @param rect 原始尺寸
 @param xCrd 指定x坐标
 @param backward 是否为向后模式
 @return 缩短后的尺寸
 
 注:
 向后模式及保留指定x坐标右侧区域，反之亦然
 */
CGRect DWShortenRectToXCrd(CGRect rect,CGFloat xCrd,BOOL backward);

/**
 延长尺寸至指定坐标
 
 @param rect 原始尺寸
 @param xCrd 指定坐标
 @return 延长后的尺寸
 */
CGRect DWLengthenRectToXCrd(CGRect rect,CGFloat xCrd);


/**
 比较两个点的空间位置

 @param p1 点1
 @param p2 点2
 @return 返回点2相对于点1的位置
 
 注：
 当p1与p2重合时返回NSOrderedSame，
 当向量p1p2与坐标系x轴夹角位于(Pi,2Pi]时返回NSOrderedAscending，
 其余情况返回NSOrderedDescending。
 */
NSComparisonResult DWComparePoint(CGPoint p1,CGPoint p2);

#pragma mark --- 尺寸组合方法 ---

/**
 返回target中不在origin范围内的尺寸集合

 @param target 待分隔的尺寸
 @param origin 分隔参照的尺寸
 @return target中不在origin范围内的尺寸集合
 
 注：
 当target包含origin是返回nil。
 当origin包含target是返回空数组。
 当没有交集是返回target
 其余返回不在origin范围内的尺寸集合
 */
NSArray * DWRectsBeyondRect(CGRect target,CGRect origin);

#pragma mark --- 交换对象方法 ---
///交换两个浮点数
void DWSwapfAB(CGFloat *a,CGFloat *b);

///交换两个对象
void DWSwapoAB(id a,id b);
