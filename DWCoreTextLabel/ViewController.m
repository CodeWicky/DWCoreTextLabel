//
//  ViewController.m
//  DWCoreTextLabel
//
//  Created by Wicky on 16/12/4.
//  Copyright © 2016年 Wicky. All rights reserved.
//

#import "ViewController.h"
#import "DWCoreTextLabel.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    DWCoreTextLabel * label = [[DWCoreTextLabel alloc] initWithFrame:self.view.bounds];
//    label.center = self.view.center;
    label.textAlignment = NSTextAlignmentRight;
//    label.textVerticalAlignment = DWTextVerticalAlignmentTop;
    label.text = @"fdasfds发fadfalkja;dlkjadf;ladsf;klajsdflk;j;l;;f;dalskjfm;alkmakjm;lfkajm;kfcasdlkfmlaksdfdsjcfl;adfmdalmdfkacjd;m;smfaksj";
    label.textInsets = UIEdgeInsetsMake(10, 10, 10, 10);
    label.numberOflines = 3;
//    label.lineBreakMode = NSLineBreakByTruncatingTail;
//    label.attributedText = [[NSAttributedString alloc] initWithString:@"我们"];
    label.textColor = [UIColor blueColor];
    [self.view addSubview:label];
    label.exclusionPaths = @[[UIBezierPath bezierPathWithRect:CGRectMake(0, 10, 100, 100)],[UIBezierPath bezierPathWithOvalInRect:CGRectMake(100, 350, 200, 100)]].mutableCopy;
    [label drawImage:[UIImage imageNamed:@"2.jpg"] atFrame:CGRectMake(100, 100, 100, 100) drawMode:(DWTextImageDrawModeCover)];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
