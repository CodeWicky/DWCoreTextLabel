//
//  DWAsyncLayer.h
//  DWCoreTextLabel
//
//  Created by Wicky on 2017/2/9.
//  Copyright © 2017年 Wicky. All rights reserved.
//

/**
 图层异步绘制类
 
 提供图层的异步绘制，线程安全。
 
 version 1.0.0
 提供异步绘制
 */

#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>

@interface DWAsyncLayer : CALayer

@property (nonatomic ,copy) void (^displayBlock)(CGContextRef context,BOOL(^isCanceled)(void));

@property (nonatomic ,assign) BOOL displaysAsynchronously;

@end
