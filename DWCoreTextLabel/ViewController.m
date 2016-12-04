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
    DWCoreTextLabel * label = [[DWCoreTextLabel alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
    label.backgroundColor = [UIColor redColor];
    label.center = self.view.center;
//    label.textAlignment = NSTextAlignmentRight;
//    label.textVerticalAlignment = DWTextVerticalAlignmentTop;
    label.text = @"我";
    label.textInsets = UIEdgeInsetsMake(10, 10, 10, 10);
//    label.attributedText = [[NSAttributedString alloc] initWithString:@"我们"];
    label.textColor = [UIColor yellowColor];
    [self.view addSubview:label];

}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
