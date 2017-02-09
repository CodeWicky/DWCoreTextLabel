//
//  DWAsyncLayer.h
//  DWCoreTextLabel
//
//  Created by Wicky on 2017/2/9.
//  Copyright © 2017年 Wicky. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>

@interface DWAsyncLayer : CALayer

@property (atomic, readonly) int32_t signal;

@property (nonatomic ,copy) void (^displayBlock)(CGContextRef context,BOOL(^isCanceled)());

@property (nonatomic ,assign) BOOL displaysAsynchronously;

@end
