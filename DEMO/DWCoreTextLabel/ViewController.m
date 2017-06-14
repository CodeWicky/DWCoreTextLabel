//
//  ViewController.m
//  DWCoreTextLabel
//
//  Created by Wicky on 16/12/4.
//  Copyright © 2016年 Wicky. All rights reserved.
//

#import "ViewController.h"
#import "DWCoreTextLabel.h"
@interface ViewController ()<DWCoreTextLabelDelegate>

@property (nonatomic ,strong) DWCoreTextLabel * label;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    DWCoreTextLabel * label = [[DWCoreTextLabel alloc] initWithFrame:self.view.bounds];
    label.text = @"姓名：\t老司机\n性别：\t男\n年龄：\t18+\n现居地：\t北京\n爱好：\t女\n简历：你就想想一个逗逼程序员是什么样，老司机就是什么样。嗯，如果不了解程序员这个行业，你就想想逗逼什么样吧。\n\n欢迎各位女程序员前来骚扰，男程序员们申请个女号再来骚扰。\n简书地址：http://www.jianshu.com/users/a56ec10f6603/latest_articles\nGitHub：https://github.com/CodeWicky\nDWCoreTextLabel简介：\nDWCoreTextLabel最大的特点是这是一个支持图片环绕文本、添加文字图片点击事件的一个控件，它是基于CoreText致力于让你替换系统Label的一个日常化组件。目前作者正在努力完善其他功能中~恩，这之所以写这么多字，是因为我要展示一下环绕文字的效果。";
    label.backgroundColor = [UIColor colorWithRed:253 / 255.0 green:249 / 255.0 blue:218 / 255.0 alpha:1];
    label.textInsets = UIEdgeInsetsMake(10, 10, 10, 10);
    label.textColor = [UIColor blueColor];
    [self.view addSubview:label];
    label.exclusionPaths = @[[UIBezierPath bezierPathWithRect:CGRectMake(10, 10, 120, 120)]].mutableCopy;
    [label dw_InsertImage:[UIImage imageNamed:@"2.jpg"] size:CGSizeMake(414 - 50 - 20, 170) padding:25 descent:0 atLocation:91 target:self selector:@selector(clickPic)];
    [label dw_DrawImage:[UIImage imageNamed:@"oldDriver"] WithPath:[UIBezierPath bezierPathWithOvalInRect:CGRectMake(10,10, 120, 120)] margin:5 drawMode:(DWTextImageDrawModeCover) target:self selector:@selector(clickHeader)];
    [label dw_AddTarget:self selector:@selector(clickLink) toRange:NSMakeRange(126, 57)];
    [label dw_AddTarget:self selector:@selector(clickBlog) toRange:NSMakeRange(191, 28)];
    label.delegate = self;
    label.autoCheckLink = YES;
    NSDictionary * dic = @{NSForegroundColorAttributeName:[UIColor redColor]};
    label.activeTextAttributes = dic;
    NSDictionary * dic2 = @{NSForegroundColorAttributeName:[UIColor greenColor]};
    label.activeTextHighlightAttributes = dic2;
    UIBezierPath * path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(self.view.center.x, 575)];
    [path addLineToPoint:CGPointMake(self.view.center.x - 50, 625)];
    [path addLineToPoint:CGPointMake(self.view.center.x, 675)];
    [path addLineToPoint:CGPointMake(self.view.center.x + 50, 625)];
    [path closePath];
    [label dw_DrawImageWithUrl:@"http://upload-images.jianshu.io/upload_images/1835430-deee60e266a22d65.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240" WithPath:path margin:5 drawMode:(DWTextImageDrawModeSurround) target:nil selector:nil];
    
}

-(void)coreTextLabel:(DWCoreTextLabel *)label didSelectLink:(NSString *)link range:(NSRange)range linkType:(DWLinkType)linkType
{
    NSLog(@"%@ == %@ == %ld",link,NSStringFromRange(range),linkType);
}

-(void)clickHeader
{
    [[[UIAlertView alloc] initWithTitle:nil message:@"你点我头像嘎哈！" delegate:nil cancelButtonTitle:@"我错了" otherButtonTitles:nil] show];
}

-(void)clickPic
{
    [[[UIAlertView alloc] initWithTitle:nil message:@"你点击了图片！" delegate:nil cancelButtonTitle:@"我知道了" otherButtonTitles:nil] show];
}

-(void)clickLink
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.jianshu.com/users/a56ec10f6603/latest_articles"]];
}

-(void)clickBlog
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://github.com/CodeWicky"]];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
