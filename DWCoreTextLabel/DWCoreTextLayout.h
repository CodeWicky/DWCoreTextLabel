//
//  DWCoreTextLayout.h
//  DWCoreTextLabel
//
//  Created by Wicky on 2017/8/10.
//  Copyright © 2017年 Wicky. All rights reserved.
//

/**
 布局类，统一管理布局信息
 */

#import <Foundation/Foundation.h>
#import <CoreText/CoreText.h>
#import "DWCoreTextCommon.h"

@class DWCTRunWrapper;
/**
 字形包装类
 */
@interface DWGlyphWrapper : NSObject

///所属run
@property (nonatomic ,weak ,readonly) DWCTRunWrapper * run;

///上一个字形
@property (nonatomic ,weak ,readonly) DWGlyphWrapper * previousGlyph;

///下一个字形
@property (nonatomic ,weak ,readonly) DWGlyphWrapper * nextGlyph;

///字形开始x坐标
@property (nonatomic ,assign ,readonly) CGFloat startXCrd;

///字形结束x坐标
@property (nonatomic ,assign ,readonly) CGFloat endXCrd;

///字形角标
@property (nonatomic ,assign ,readonly) NSUInteger index;

///起始位置
@property (nonatomic ,assign ,readonly) DWPosition startPosition;

///终止位置
@property (nonatomic ,assign ,readonly) DWPosition endPosition;

@end

@class DWCTLineWrapper;
/**
 CTRun包装类
 */
@interface DWCTRunWrapper : NSObject

///所属Line
@property (nonatomic ,weak ,readonly) DWCTLineWrapper * line;

///对应CTRun
@property (nonatomic ,assign ,readonly) CTRunRef ctRun;

///对应的系统尺寸
@property (nonatomic ,assign ,readonly) CGRect runRect;

///对应的屏幕尺寸
@property (nonatomic ,assign ,readonly) CGRect frame;

///上一个CTRun
@property (nonatomic ,weak ,readonly) DWCTRunWrapper * previousRun;

///下一个CTRun
@property (nonatomic ,weak ,readonly) DWCTRunWrapper * nextRun;

///对应的CTRun的属性
@property (nonatomic ,strong ,readonly) NSDictionary * runAttributes;

///本run包含的所有字符集
@property (nonatomic ,strong ,readonly) NSArray <DWGlyphWrapper *>* glyphs;

///起始位置(包含)
@property (nonatomic ,assign ,readonly) NSUInteger startIndex;

///结束位置(不包含)
@property (nonatomic ,assign ,readonly) NSUInteger endIndex;

///是否是图片
@property (nonatomic ,assign ,readonly) BOOL isImage;

///是否具有事件
@property (nonatomic ,assign ,readonly) BOOL hasAction;

///具有响应事件的属性字典
@property (nonatomic ,strong ,readonly) NSDictionary * activeAttributes;

@end


/**
 CTLine包装类
 */
@interface DWCTLineWrapper : NSObject

///对应CTLine
@property (nonatomic ,assign ,readonly) CTLineRef ctLine;

///系统坐标系原点（若要使用需转换成屏幕坐标系原点）
@property (nonatomic ,assign ,readonly) CGPoint lineOrigin;

///对应的系统尺寸
@property (nonatomic ,assign ,readonly) CGRect lineRect;

///对应的屏幕尺寸
@property (nonatomic ,assign ,readonly) CGRect frame;

///起始位置(包含)
@property (nonatomic ,assign ,readonly) NSUInteger startIndex;

///结束位置(不包含)
@property (nonatomic ,assign ,readonly) NSUInteger endIndex;

///上一行
@property (nonatomic ,weak ,readonly) DWCTLineWrapper * previousLine;

///下一行
@property (nonatomic ,weak ,readonly) DWCTLineWrapper * nextLine;

///行数
@property (nonatomic ,assign ,readonly) NSUInteger row;

///本行包含的ctRun数组
@property (nonatomic ,strong ,readonly) NSArray <DWCTRunWrapper *>* runs;

@end


/**
 CoreText绘制布局计算类
 
 注：此处Layout类仅负责处理由富文本直接绘制的元素。包含文字、链接及插入到字符串的图片。
 */
@interface DWCoreTextLayout : NSObject

///包含的CTLine数组
@property (nonatomic ,strong ,readonly) NSArray <DWCTLineWrapper *>* lines;

///绘制的最大位置
@property (nonatomic ,assign ,readonly) NSUInteger maxLoc;

///具有响应事件的图片的配置数组（Layout仅处理插入图片的图片配置数组，对于Path绘制的不处理）
@property (nonatomic ,strong ,readonly) NSArray * activeImageConfigs;


/**
 生成布局计算类

 @param ctFrame 需要绘制的CTFrame
 @param height 需要绘制CTFrame对应的屏幕坐标与系统坐标转换高度（即控件尺寸，包含空白、缩进等）
 @param considerGlyphs 是否计算每个字形
 @return 返回对应的绘制layout类
 */
+(instancetype)layoutWithCTFrame:(CTFrameRef)ctFrame convertHeight:(CGFloat)height considerGlyphs:(BOOL)considerGlyphs;



/**
 自动处理具有响应事件的图片及文字

 @param customLinkRegex 自定制链接匹配正则
 @param autoCheckLink 是否自动检测链接
 */
-(void)handleActiveImageAndTextWithCustomLinkRegex:(NSString *)customLinkRegex autoCheckLink:(BOOL)autoCheckLink;


/**
 遍历绘制所需CTRun

 @param handler 遍历回调
 */
-(void)enumerateCTRunUsingBlock:(void(^)(DWCTRunWrapper * run,BOOL * stop))handler;

/***
 返回CTLine、CTRun、Glyph、Position或x坐标

 注：
 loc为对应角标
 point为屏幕坐标系内的点
 */
-(DWCTLineWrapper *)lineAtLocation:(NSUInteger)loc;
-(DWCTLineWrapper *)lineAtPoint:(CGPoint)point;
-(DWCTRunWrapper *)runAtLocation:(NSUInteger)loc;
-(DWCTRunWrapper *)runAtPoint:(CGPoint)point;
-(DWGlyphWrapper *)glyphAtLocation:(NSUInteger)loc;
-(DWGlyphWrapper *)glyphAtPoint:(CGPoint)point;
-(DWPosition)positionAtLocation:(NSUInteger)loc;
-(DWPosition)positionAtPoint:(CGPoint)point;
-(CGFloat)xCrdAtLocation:(NSUInteger)loc;
-(CGFloat)xCrdAtPoint:(CGPoint)point;


/**
 返回两个角标或点之间被选中的矩形尺寸数组

 注：
 loc为对应角标（locA应小于locB，包含locA，不包含locB）
 point为屏幕坐标系内的点
 range为将要选中的范围
 */
-(NSArray *)selectedRectsBetweenLocationA:(NSUInteger)locA andLocationB:(NSUInteger)locB;
-(NSArray *)selectedRectsBetweenPointA:(CGPoint)pointA andPointB:(CGPoint)pointB;
-(NSArray *)selectedRectsInRange:(NSRange)range;


/**
 获取给定Run两坐标之间的所有字形矩阵尺寸数组

 @param run 给定run
 @param xCrdA 横坐标A
 @param xCrdB 横坐标B
 @return 符合条件的字形矩阵尺寸数组
 
 注：两坐标无大小顺序要求，若B坐标小于A，API会自动交换
 */
-(NSArray *)rectInRun:(DWCTRunWrapper *)run XCrdA:(CGFloat)xCrdA xCrdB:(CGFloat)xCrdB;


/**
 获取给定Line某点之前或之后的所有字形矩阵尺寸数组

 loc 角标
 point 目标点
 backward 是否取点之后的所有字形
 @return 符合条件的字形矩阵尺寸数组
 */
-(NSArray *)rectInLineAtLocation:(NSUInteger)loc backword:(BOOL)backward;
-(NSArray *)rectInLineAtPoint:(CGPoint)point backword:(BOOL)backward;


/**
 获取同一行中两个run之间在两个坐标之间的字形矩阵尺寸数组

 @param startRun 开始的run
 @param startXCrd 开始的横坐标
 @param endRun 结束的run
 @param endXCrd 结束的横坐标
 @return 符合条件的字形矩阵尺寸数组
 
 注：
 run及xCrd均无大小顺序要求，如果传入相反顺序，API会自行交换（此API仅可应用于计算同一Line对象中两个Run间的字形矩阵计算）
 */
-(NSArray *)rectsInLineWithStartRun:(DWCTRunWrapper *)startRun startXCrd:(CGFloat)startXCrd endRun:(DWCTRunWrapper *)endRun endXCrd:(CGFloat)endXCrd;


/**
 获取指定Line所有字形矩阵尺寸数组

 @param line 目标CTLine
 @return 目标CTLine的所有字形矩阵尺寸数组
 */
-(NSArray *)rectsInLine:(DWCTLineWrapper *)line;


/**
 返回任意两个Run直接介于起始终止坐标之间的所有字形矩阵尺寸数组

 @param startRun 开始的run
 @param startXCrd 需要返回尺寸的字形起始位置横坐标
 @param endRun 结束的run
 @param endXCrd 需要返回尺寸的字形终止位置横坐标
 @return 符合条件的字形矩阵尺寸数组
 
 注：
 理论上run及坐标均应保证正确的先后对应顺序。
 若run传入的startRun的角标大于endRun，API会自动交换。
 但startXCrd中，API无法根据横坐标数值判断先后顺序，故应保证横坐标按对应顺序传入。当开发者无法确定横坐标起始顺序时，应根据实际情况，酌情考虑使用-selectedRectsBetweenPointA:andPointB: API来计算等效范围
 */
-(NSArray *)rectsInLayoutWithStartRun:(DWCTRunWrapper *)startRun startXCrd:(CGFloat)startXCrd endRun:(DWCTRunWrapper *)endRun endXCrd:(CGFloat)endXCrd;


/**
 获取点的位置返回角标

 @param point 屏幕中的点
 @return 对应角标
 */
-(NSUInteger)locFromPoint:(CGPoint)point;

@end
