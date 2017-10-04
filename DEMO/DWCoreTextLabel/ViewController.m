//
//  ViewController.m
//  DWCoreTextLabel
//
//  Created by Wicky on 16/12/4.
//  Copyright © 2016年 Wicky. All rights reserved.
//

#import "ViewController.h"
#import "DWCoreTextLabel.h"
#import "DWCoreTextSelectionView.h"
#import "DWCoreTextCommon.h"
#import "DWCoreTextLabelCalculator.h"
@interface ViewController ()<DWCoreTextLabelDelegate>

@property (nonatomic ,strong) DWCoreTextLabel * label;

@property (nonatomic ,strong) DWCoreTextSelectionView * aView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    DWCoreTextLabel * label = [[DWCoreTextLabel alloc] initWithFrame:self.view.bounds];
    self.label = label;
    label.text = @"姓名：\t老司机\n性别：\t男\n年龄：\t18+\n现居地：\t北京\n爱好：\t女\n简历：你就想想一个逗逼程序员是什么样，老司机就是什么样。嗯，如果不了解程序员这个行业，你就想想逗逼什么样吧。\n\n欢迎各位女程序员前来骚扰，男程序员们申请个女号再来骚扰。\n简书地址：http://www.jianshu.com/users/a56ec10f6603/latest_articles\nGitHub：https://github.com/CodeWicky\nDWCoreTextLabel简介：\nDWCoreTextLabel最大的特点是这是一个支持图片环绕文本、添加文字图片点击事件的一个控件，它是基于CoreText致力于让你替换系统Label的一个日常化组件。目前作者正在努力完善其他功能中~恩，这之所以写这么多字，是因为我要展示一下环绕文字的效果。";
//    label.text = @"123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890";
//    label.text = @"1234";
    label.backgroundColor = [UIColor colorWithRed:253 / 255.0 green:249 / 255.0 blue:218 / 255.0 alpha:1];
    label.textInsets = UIEdgeInsetsMake(50, 10, 50, 10);
    label.textColor = [UIColor blueColor];
//    label.numberOfLines = 2;
    [self.view addSubview:label];
//    label.exclusionPaths = @[[UIBezierPath bezierPathWithRect:CGRectMake(0, 50, 50, 50)]].mutableCopy;
    [label dw_InsertImage:[UIImage imageNamed:@"2.jpg"] withImageID:@"URL" size:CGSizeMake(335, 160) padding:10 descent:0 atLocation:91 target:self selector:@selector(clickPic)];
//    [label dw_DrawImage:[UIImage imageNamed:@"oldDriver"] withImageID:@"URL" path:[UIBezierPath bezierPathWithOvalInRect:CGRectMake(13,53, 120, 120)] margin:0 drawMode:(DWTextImageDrawModeCover) target:self selector:@selector(clickHeader)];
    [label dw_AddTarget:self selector:@selector(clickLink) toRange:NSMakeRange(126, 57)];
    [label dw_AddTarget:self selector:@selector(clickBlog) toRange:NSMakeRange(191, 28)];
    label.delegate = self;
    label.autoCheckLink = YES;
    NSDictionary * dic = @{NSForegroundColorAttributeName:[UIColor redColor]};
    label.activeTextAttributes = dic;
//    label.textVerticalAlignment = DWTextVerticalAlignmentBottom;
    NSDictionary * dic2 = @{NSForegroundColorAttributeName:[UIColor greenColor]};
    label.activeTextHighlightAttributes = dic2;
    UIBezierPath * path = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(20, 575, 120, 120)];
//    [path moveToPoint:CGPointMake(self.view.center.x, 575)];
//    [path addLineToPoint:CGPointMake(self.view.center.x - 50, 625)];
//    [path addLineToPoint:CGPointMake(self.view.center.x, 675)];
//    [path addLineToPoint:CGPointMake(self.view.center.x + 50, 625)];
//    [path closePath];
//    [label dw_DrawImageWithUrl:@"https://timgsa.baidu.com/timg?image&quality=80&size=b9999_10000&sec=1486655338141&di=f457d61d52460455bd37430fe77b5cf4&imgtype=0&src=http%3A%2F%2Fimgsrc.baidu.com%2Fforum%2Fpic%2Fitem%2F4c8e31a03bb6ec2cf31fe7b4.jpg" withImageID:@"URL" placeHolder:nil path:path margin:0 drawMode:(DWTextImageDrawModeSurround) target:nil selector:nil];
//////
//////    
////////    [label sizeToFit];
//////    
//    UIView * view =[[UIView alloc] initWithFrame:CGRectMake(100, 100, 100, 100)];
//    view.backgroundColor = [UIColor redColor];
//    [label addSubview:view];
    
    
//    UITapGestureRecognizer * tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap)];
//    tap.numberOfTapsRequired = 2;
////    tap.enabled = NO;
//    [label addGestureRecognizer:tap];
//
//    
//    
//    
//    
//    
////    UILabel * lable = [[UILabel alloc] initWithFrame:self.view.bounds];
////    lable.text = @"123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890";
////    lable.numberOfLines = 0;
////    lable.layoutMargins = UIEdgeInsetsMake(20, 20, 20, 20);
////    lable.preservesSuperviewLayoutMargins = YES;
////    lable.backgroundColor = [UIColor greenColor];
////    [self.view addSubview:lable];
    
//    DWCoreTextSelectionView * view = [[DWCoreTextSelectionView alloc] initWithFrame:self.view.bounds];
//    [self.view addSubview:view];
//    view.selectAction = DWSelectActionCut | DWSelectActionDelete | DWSelectActionSelectAll | DWSelectActionCustom;
//    DWCoreTextMenuItem * item = [DWCoreTextMenuItem new];
//    item.target = self;
//    item.action = @selector(tap);
//    item.title = @"custom";
//    DWCoreTextMenuItem * item2 = [DWCoreTextMenuItem new];
//    item2.target = self;
//    item2.action = @selector(tap2);
//    item2.title = @"custom2";
//    view.customSelectItems = @[item,item2];
//    self.aView = view;
    
//    CGRect origin = CGRectMake(0,0, 100, 100);
//    CGRect target = CGRectMake(100, 100, 100, 100);
//    NSLog(@"%@",DWRectsBeyondRect(target, origin));
    
}

-(void)tap {
    NSLog(@"tap");
}

-(void)tap2 {
    NSLog(@"tap2");
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
//    [self.label updateHeight:self.label.bounds.size.height + 10];
//    self.label.startGrabber = NO;
//    [self.label setNeedsLayout];
//    [self.label moveToBaseLineY:200 xCrd:400];
    [self.aView showSelectMenuInRect:CGRectMake(0,0, 100, 736 - 100)];
}

//-(void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
//    UITouch * touch = [touches anyObject];
//    CGPoint point = [touch locationInView:self.view];
//    NSLog(@"P = %f,%f",point.x,point.y);
//    
//    DWPosition p = DWMakePosition(point.y, point.x, 100);
//    
//    NSLog(@"%f,%f,%f",p.baseLineY,p.xCrd,p.height);
//    
//    [self.sel updateCaretWithPosition:p];
//    
//}

//-(void)coreTextLabel:(DWCoreTextLabel *)label didSelectLink:(NSString *)link range:(NSRange)range linkType:(DWLinkType)linkType
//{
//    NSLog(@"%@ == %@ == %ld",link,NSStringFromRange(range),linkType);
//}
//
-(void)clickHeader
{
//    [[[UIAlertView alloc] initWithTitle:nil message:@"你点我头像嘎哈！" delegate:nil cancelButtonTitle:@"我错了" otherButtonTitles:nil] show];
}

-(void)clickPic
{
//    [[[UIAlertView alloc] initWithTitle:nil message:@"你点击了图片！" delegate:nil cancelButtonTitle:@"我知道了" otherButtonTitles:nil] show];
}

-(void)clickLink
{
//    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.jianshu.com/users/a56ec10f6603/latest_articles"]];
}

-(void)clickBlog
{
//    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://github.com/CodeWicky"]];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
