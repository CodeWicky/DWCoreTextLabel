//
//  DWAsyncLayer.m
//  DWCoreTextLabel
//
//  Created by Wicky on 2017/2/9.
//  Copyright © 2017年 Wicky. All rights reserved.
//

#import "DWAsyncLayer.h"
#import <libkern/OSAtomic.h>

static dispatch_queue_t DWCoreTextLabelLayerGetDisplayQueue() {
#define MAX_QUEUE_COUNT 16
    static int queueCount;
    static dispatch_queue_t queues[MAX_QUEUE_COUNT];
    static dispatch_once_t onceToken;
    static int32_t counter = 0;
    dispatch_once(&onceToken, ^{
        queueCount = (int)[NSProcessInfo processInfo].activeProcessorCount;
        queueCount = queueCount < 1 ? 1 : queueCount > MAX_QUEUE_COUNT ? MAX_QUEUE_COUNT : queueCount;
        if ([UIDevice currentDevice].systemVersion.floatValue >= 8.0) {
            for (NSUInteger i = 0; i < queueCount; i++) {
                dispatch_queue_attr_t attr = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_USER_INITIATED, 0);
                queues[i] = dispatch_queue_create("com.codeWicky.DWCoreTextLabel.render", attr);
            }
        } else {
            for (NSUInteger i = 0; i < queueCount; i++) {
                queues[i] = dispatch_queue_create("com.codeWicky.DWCoreTextLabel.render", DISPATCH_QUEUE_SERIAL);
                dispatch_set_target_queue(queues[i], dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0));
            }
        }
    });
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    uint32_t cur = (uint32_t)OSAtomicIncrement32(&counter);
#pragma clang diagnostic pop
    return queues[(cur) % queueCount];
#undef MAX_QUEUE_COUNT
}

static dispatch_queue_t DWCoreTextLabelLayerGetReleaseQueue() {
    return dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
}

@interface DWAsyncLayer ()

@property (atomic, readonly) int32_t signal;

@end

@implementation DWAsyncLayer

-(instancetype)init
{
    self = [super init];
    if (self) {
        _signal = 0;
        _displaysAsynchronously = YES;
    }
    return self;
}

-(void)signalIncrease
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    OSAtomicIncrement32(&_signal);
#pragma clang diagnostic pop
}

-(void)setNeedsDisplay
{
    [self cancelPreviousDisplayCalculate];
    [super setNeedsDisplay];
}

-(void)cancelPreviousDisplayCalculate
{
    [self signalIncrease];
}

-(void)dealloc
{
    [self cancelPreviousDisplayCalculate];
}

-(void)display
{
    super.contents = super.contents;
    [self displayAsync:self.displaysAsynchronously];
}

-(void)displayAsync:(BOOL)async
{
    if (!self.displayBlock) {
        self.contents = nil;
        return;
    }
    if (async) {
        int32_t signal = self.signal;
        BOOL (^isCancelled)(void) = ^BOOL(void) {
            return signal != self.signal;
        };
        CGSize size = self.bounds.size;
        BOOL opaque = self.opaque;
        CGFloat scale = self.contentsScale;
        CGColorRef backgroundColor = (opaque && self.backgroundColor) ? CGColorRetain(self.backgroundColor) : NULL;
        if (size.width < 1 || size.height < 1) {
            CGImageRef image = (__bridge_retained CGImageRef)(self.contents);
            self.contents = nil;
            if (image) {
                dispatch_async(DWCoreTextLabelLayerGetReleaseQueue(), ^{
                    CFRelease(image);
                });
            }
            CGColorRelease(backgroundColor);
            return;
        }
        
        dispatch_async(DWCoreTextLabelLayerGetDisplayQueue(), ^{
            if (isCancelled()) {
                CGColorRelease(backgroundColor);
                return;
            }
            UIGraphicsBeginImageContextWithOptions(size, opaque, scale);
            CGContextRef context = UIGraphicsGetCurrentContext();
            if (opaque) {
                fillContextWithColor(context, backgroundColor, size);
                CGColorRelease(backgroundColor);
            }
            self.displayBlock(context,isCancelled);
            if (isCancelled()) {
                UIGraphicsEndImageContext();
                return;
            }
            UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            if (isCancelled()) {
                return;
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                if (!isCancelled()) {
                    self.contents = (__bridge id)(image.CGImage);
                }
            });
        });
    } else {
        [self signalIncrease];
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, self.opaque, self.contentsScale);
        CGContextRef context = UIGraphicsGetCurrentContext();
        if (self.opaque) {
            CGSize size = self.bounds.size;
            size.width *= self.contentsScale;
            size.height *= self.contentsScale;
            fillContextWithColor(context, self.backgroundColor,size);
        }
        self.displayBlock(context,^{return NO;});
        UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        self.contents = (__bridge id)(image.CGImage);
    }
}

static inline void fillContextWithColor(CGContextRef context,CGColorRef color,CGSize size){
    CGContextSaveGState(context); {
        if (!color || CGColorGetAlpha(color) < 1) {
            CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
            CGContextAddRect(context, CGRectMake(0, 0, size.width, size.height));
            CGContextFillPath(context);
        }
        if (color) {
            CGContextSetFillColorWithColor(context, color);
            CGContextAddRect(context, CGRectMake(0, 0, size.width, size.height));
            CGContextFillPath(context);
        }
    } CGContextRestoreGState(context);
};

@end
