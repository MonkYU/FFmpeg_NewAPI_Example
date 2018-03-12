//
//  ServerSourceToYUV.m
//  FFmpeg
//
//  Created by Lizeyu on 2018/2/28.
//  Copyright © 2018年 DataChart. All rights reserved.
//

#import "ServerSourceToYUV.h"
#import "FFHeader.h"

@implementation ServerSourceToYUV

+ (void)writeServerSourceToLocalFile:(NSString *)serverAddress {
    int ret = 0;
    int videoStreamIndex = -1;
    int audioStreamIndex = -1;
    const char *serverUrl = [serverAddress UTF8String];
    
}

@end
