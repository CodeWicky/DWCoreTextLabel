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
 
 version 1.0.2
 实现行数限制
 实现尾部省略号折行
 
 version 1.0.3
 实现插入图片模式
 
 version 1.0.4
 添加图片点击事件及文字点击事件
 添加活跃文本样式
 
 version 1.0.5
 修复文本点击换行失效问题
 
 version 1.0.6
 优化文本计算逻辑
 
 version 1.0.7
 添加高亮状态、完善高亮逻辑、恢复exclusionP以修复排除区域点击状态下bug
 
 version 1.0.8
 修复多链接响应排序、高亮等问题
 
 version 1.0.9
 优化重绘算法
 
 version 1.0.10
 优化绘制图片算法，添加以路径绘制图片，优化图片判断点击算法，以路径判断
 添加按路径生成图片接口
 
 version 1.0.11
 绘制图片时添加margin预留参数，调整图片绘制时与文字的内距
 插入图片时添加padding预留参数，调整图片绘制时与两侧文字的外距
 
 version 1.0.12
 调整代码，解决内存泄漏
 
 version 1.0.13
 重写sizeToFit、sizeThatFits:方法
 
 version 1.0.14
 解决初次绘制问题
 
 version 1.0.15
 添加自动检测链接属性
 添加代理，提供自动链接点击代理
 初步完成电话号码自动检测
 
 version 1.0.16
 部分赋值重绘规则优化，减少不必要重绘
 添加email、URL自动链接识别
 优化自动链接与活跃文本的优先级：活跃文本>email>URL>phoneNo
 
 version 1.0.17
 添加自定制检测规则
 自动链接添加自然数类型
 当前链接优先级：活跃文本>自定制检测规则>email>URL>phoneNo>naturalNum
 调整代码分块
 
 version 1.0.18
 修复自动链接检测高亮范围bug
 修改URL类型自动链接检测规则
 添加自定制检测链接默认属性
 
 version 1.0.19
 修复垂直对齐bug
 修复取消自动链接逻辑
 优化自动链接匹配逻辑，仅匹配可见文本
 
 version 1.1.0
 全面支持自动链接支持、定制检测规则、图文混排、响应事件
 优化大部分算法，提高响应效率及绘制效率
 
 version 1.1.1
 高亮取消逻辑优化
 自动检测逻辑优化
 部分常用方法改为内联函数，提高裕兴效率
 
 */

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, DWTextVerticalAlignment) {///纵向对齐方式
    DWTextVerticalAlignmentCenter,
    DWTextVerticalAlignmentTop,
    DWTextVerticalAlignmentBottom
};

typedef NS_ENUM(NSInteger,DWImageClipMode)//图片剪裁模式
{
    DWImageClipModeScaleAspectFit,//适应模式
    DWImageClipModeScaleAspectFill,//填充模式
    DWImageClipModeScaleToFill//拉伸模式
};

typedef NS_ENUM(NSUInteger, DWTextImageDrawMode) {///绘制模式
    DWTextImageDrawModeSurround,
    DWTextImageDrawModeCover
};

typedef NS_ENUM(NSUInteger, DWLinkType) {///自动链接样式
    DWLinkTypeNaturalNum,
    DWLinkTypePhoneNo,
    DWLinkTypeURL,
    DWLinkTypeEmail,
    DWLinkTypeCustom
};

#define DWDefaultAttributes @{NSUnderlineStyleAttributeName:@(NSUnderlineStyleSingle),NSForegroundColorAttributeName:[UIColor blueColor]}
#define DWDefaultHighlightAttributes @{NSUnderlineStyleAttributeName:@(NSUnderlineStyleSingle),NSForegroundColorAttributeName:[UIColor redColor]}

@class DWCoreTextLabel;
@protocol DWCoreTextLabelDelegate <NSObject>

@optional

///自动链接回调
-(void)coreTextLabel:(DWCoreTextLabel *)label didSelectLink:(NSString *)link range:(NSRange)range linkType:(DWLinkType)linkType;

@end

@interface DWCoreTextLabel : UIView

#pragma mark ---基本属性---
///代理
@property (nonatomic ,weak) id<DWCoreTextLabelDelegate> delegate;

///普通文本
@property (nonatomic ,strong) NSString * text;

///文本区域内距
@property (nonatomic ,assign) UIEdgeInsets textInsets;

///文本颜色
@property (nonatomic ,strong) UIColor * textColor;

///行数
@property (nonatomic ,assign) NSUInteger numberOfLines;

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
 注：
 设置排除区域后，对齐方式失效
 排除区域位于文本区域外部，排除区域失效
 排除区域重叠部分奇数重合区域则为不排除
 */
@property (nonatomic ,strong) NSMutableArray<UIBezierPath *> * exclusionPaths;

///自动重绘
/**
 默认关闭，开启后设置需要重绘的属性后自动重绘
 */
@property (nonatomic ,assign) BOOL autoRedraw;

/**
 自动检测特殊链接
 
 注：
 1.包括手机号码
 2.默认关闭
 
 */
@property (nonatomic ,assign) BOOL autoCheckLink;

/**
 自动检测的配置字典
 
 用于定制检测规则
 可修改本配置字典以达到改变检测规则或减少检测项
 
 注：
 1.可修改检测规则，及正则文本，不可添加或改变键名
 2.可减少键值对，不可增加预置类型外的键值对
 3.若想匹配预置类型外的规则，请使用customLinkRegex属性
 */
@property (nonatomic ,strong) NSMutableDictionary * autoCheckConfig;

/**
 匹配自定制特殊链接的正则
 */
@property (nonatomic ,copy) NSString * customLinkRegex;

#pragma mark ---链接属性---
///活跃文本的属性
@property (nonatomic ,strong) NSDictionary * activeTextAttributes;

///活跃文本的高亮属性
@property (nonatomic ,strong) NSDictionary * activeTextHighlightAttributes;
///以下属性在autoCheckLink为真时有效
/**
 自然数属性
 */
@property (nonatomic ,strong) NSDictionary * naturalNumAttributes;

/**
 自然数高亮属性
 */
@property (nonatomic ,strong) NSDictionary * naturalNumHighlightAttributes;

/**
 电话号码属性
 */
@property (nonatomic ,strong) NSDictionary * phoneNoAttributes;

/**
 电话号码高亮时属性
 */
@property (nonatomic ,strong) NSDictionary * phoneNoHighlightAttributes;

/**
 URL属性
 */
@property (nonatomic ,strong) NSDictionary * URLAttributes;

/**
 URL高亮时属性
 */
@property (nonatomic ,strong) NSDictionary * URLHighlightAttributes;

/**
 email属性
 */
@property (nonatomic ,strong) NSDictionary * emailAttributes;

/**
 email高亮时属性
 */
@property (nonatomic ,strong) NSDictionary * emailHighlightAttributes;

/**
 自定制链接属性
 */
@property (nonatomic ,strong) NSDictionary * customLinkAttributes;

/**
 自定制链接高亮时属性
 */
@property (nonatomic ,strong) NSDictionary * customLinkHighlightAttributes;

#pragma mark ---方法---
/**
 以frame绘制矩形图片
 
 image      将要绘制的图片
 frame      绘制图片的尺寸
 margin     绘制图片时的内距效果，margin大于0时，绘制的实际尺寸小于frame，同时保证绘制中心不变
 drawMode   图片绘制模式，包括环绕型和覆盖型
 target     可选参数，与target配套使用
 selector   为图片添加点击事件，响应区域为图片实际绘制区域
 
 注：surround模式下，frame应在文本区域内部，若存在外部，请以coverMode绘制并自行添加排除区域
 若图片有重合区域，请以coverMode绘制并自行添加排除区域
 */
-(void)dw_DrawImage:(UIImage *)image atFrame:(CGRect)frame margin:(CGFloat)margin drawMode:(DWTextImageDrawMode)mode target:(id)target selector:(SEL)selector;

/**
 以path绘制不规则形状图片
 
 image      将要绘制的图片
 path       绘制图片的路径，先以path对图片进行剪裁，后绘制
 margin     绘制图片时的内距效果，margin大于0时，绘制的实际路径小于path，同时保证绘制中心不变
 drawMode   图片绘制模式，包括环绕型和覆盖型
 target     可选参数，与target配套使用
 selector   为图片添加点击事件，响应区域为图片实际绘制区域
 
 注：
 1.surround模式下，path应在文本区域内部，若存在外部，请以coverMode绘制并自行添加排除区域
 若图片有重合区域，请以coverMode绘制并自行添加排除区域
 2.将自动按照path路径形状剪裁图片，图片无需事先处理
 3.自动剪裁图片时按照path的形状剪裁，与origin无关。
 */
-(void)dw_DrawImage:(UIImage *)image WithPath:(UIBezierPath *)path margin:(CGFloat)margin drawMode:(DWTextImageDrawMode)mode target:(id)target selector:(SEL)selector;

/**
 插入图片
 
 image      将要绘制的图片
 size       绘制图片的大小
 padding    绘制图片时的外距效果，padding大于0时，绘制的图片距两端文字有padding的距离
 descent    绘制图片的底部基线与文字基线的偏移量，当descent等于0时，与文字的底部基线对其
 location   要插入图片的位置
 target     可选参数，与target配套使用
 selector   为图片添加点击事件，响应区域为图片实际绘制区域
 
 注：
 1.在指定位置插入图片，图片大小会影响行间距
 2.插入图片的位置不影响为范围内文字添加点击事件，无需另做考虑
 */
-(void)dw_InsertImage:(UIImage *)image size:(CGSize)size padding:(CGFloat)padding descent:(CGFloat)descent atLocation:(NSUInteger)location target:(id)target selector:(SEL)selector;

/**
 为指定区域文本添加点击事件
 */
-(void)dw_AddTarget:(id)target selector:(SEL)selector toRange:(NSRange)range;

/**
 返回指定形状的image对象
 */
+(UIImage *)dw_ClipImage:(UIImage *)image withPath:(UIBezierPath *)path mode:(DWImageClipMode)mode;
@end

