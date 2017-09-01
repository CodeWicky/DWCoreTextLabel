//
//  DWCoreTextCommon.m
//  DWCoreTextLabel
//
//  Created by Wicky on 2017/9/1.
//  Copyright © 2017年 Wicky. All rights reserved.
//

#import "DWCoreTextCommon.h"
#import "DWCoreTextLabelCalculator.h"

DWPosition const DWPositionZero = {0,0,0};

DWPosition const DWPositionNull = {MAXFLOAT,MAXFLOAT,MAXFLOAT};

DWPosition DWMakePosition(CGFloat baseLineY,CGFloat xCrd,CGFloat height) {
    DWPosition pos = {baseLineY,xCrd,height};
    return pos;
}

CGPoint DWPositionGetBaseOrigin(DWPosition p) {
    return CGPointMake(p.xCrd, p.baseLineY);
}

BOOL DWPositionEqualToPosition(DWPosition p1,DWPosition p2) {
    return (p1.baseLineY == p2.baseLineY) && (p1.xCrd == p2.xCrd) && (p1.height == p2.height);
}

BOOL DWPositionIsNull(DWPosition p) {
    return DWPositionEqualToPosition(p, DWPositionNull);
}

BOOL DWPositionIsZero(DWPosition p) {
    return DWPositionEqualToPosition(p, DWPositionZero);
}

NSComparisonResult DWComparePosition(DWPosition p1,DWPosition p2) {
    CGPoint bO1 = DWPositionGetBaseOrigin(p1);
    CGPoint bO2 = DWPositionGetBaseOrigin(p2);
    return DWComparePoint(bO1, bO2);
}

BOOL DWPositionBaseOriginEqualToPosition(DWPosition p1,DWPosition p2) {
    return (DWComparePosition(p1, p2) == NSOrderedSame);
}

CGRect CGRectFromPosition(DWPosition p,CGFloat width) {
    if (DWPositionIsNull(p) || width == CGFLOAT_MAX) {
        return CGRectNull;
    }
    return CGRectMake(p.xCrd, p.baseLineY - p.height, width, p.height);
}

