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

/**
 字形包装类
 */
@interface DWGlyphWrapper : NSObject

///字形开始x坐标
@property (nonatomic ,assign) CGFloat startXCrd;

///字形结束x坐标
@property (nonatomic ,assign) CGFloat endXCrd;

///字形角标
@property (nonatomic ,assign) NSUInteger index;

@end


/**
 CTRun包装类
 */
@interface DWCTRunWrapper : NSObject

///对应CTRun
@property (nonatomic ,assign ,readonly) CTRunRef ctRun;

///对应的系统尺寸
@property (nonatomic ,assign ,readonly) CGRect runRect;

///对应的屏幕尺寸
@property (nonatomic ,assign ,readonly) CGRect frame;

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
@property (nonatomic ,assign) NSUInteger row;

///本行包含的ctRun数组
@property (nonatomic ,strong ,readonly) NSArray <DWCTRunWrapper *>* runs;

@end


/**
 CoreText布局计算类
 */
@interface DWCoreTextLayout : NSObject

///包含的CTLine数组
@property (nonatomic ,strong ,readonly) NSArray <DWCTLineWrapper *>* lines;

///绘制的最大位置
@property (nonatomic ,assign ,readonly) NSUInteger maxLoc;


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
 返回CTLine、CTRun或Glyph

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

@end
