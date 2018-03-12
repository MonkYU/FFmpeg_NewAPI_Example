//
//  ViewController.m
//  FFmpeg
//
//  Created by Lizeyu on 2018/2/27.
//  Copyright © 2018年 DataChart. All rights reserved.
//

#import "ViewController.h"
#import "PCMResample.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    PCMResample *pcm = [[PCMResample alloc] init];
    [pcm pcmResample];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
