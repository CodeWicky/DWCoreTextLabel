//
//  DWCoreTextCommon.m
//  DWCoreTextLabel
//
//  Created by Wicky on 2017/9/1.
//  Copyright © 2017年 Wicky. All rights reserved.
//

#import "DWCoreTextCommon.h"
#import "DWCoreTextLabelCalculator.h"

#pragma mark --- DWPosition ---
DWPosition const DWPositionZero = {0,0,0,0};

DWPosition const DWPositionNull = {MAXFLOAT,MAXFLOAT,MAXFLOAT,MAXFLOAT};

BOOL DWPositionIsNull(DWPosition p) {
    return DWPositionEqualToPosition(p, DWPositionNull);
}

BOOL DWPositionIsZero(DWPosition p) {
    return DWPositionEqualToPosition(p, DWPositionZero);
}

NSComparisonResult DWComparePosition(DWPosition p1,DWPosition p2) {
    if (p1.index == p2.index) {
        return NSOrderedSame;
    } else if (p1.index < p2.index) {
        return NSOrderedAscending;
    }
    return NSOrderedDescending;
}

BOOL DWPositionBaseOriginEqualToPosition(DWPosition p1,DWPosition p2) {
    CGPoint pA = DWPositionGetBaseOrigin(p1);
    CGPoint pB = DWPositionGetBaseOrigin(p2);
    return CGPointEqualToPoint(pA, pB);
}

CGRect CGRectFromPosition(DWPosition p,CGFloat width) {
    if (DWPositionIsNull(p) || width == CGFLOAT_MAX) {
        return CGRectNull;
    }
    return CGRectMake(p.xCrd, p.baseLineY - p.height, width, p.height);
}

#pragma mark --- NSRange ---
NSRange const NSRangeZero = {0,0};

NSRange const NSRangeNull = {MAXFLOAT,MAXFLOAT};

NSRange NSMakeRangeBetweenLocation(NSUInteger loc1,NSUInteger loc2) {
    if (loc1 > loc2) {
        NSUInteger temp = loc1;
        loc1 = loc2;
        loc2 = temp;
    }
    return NSMakeRange(loc1, loc2 - loc1);
}

