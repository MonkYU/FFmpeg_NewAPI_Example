//
//  YUV420pTORGB.m
//  FFMpegNewAPIExample
//
//  Created by Lizeyu on 2018/2/27.
//  Copyright © 2018年 DataChart. All rights reserved.
//

#import "YUV420pTORGB.h"
#import "FFHeader.h"
@implementation YUV420pTORGB

+ (void)yuv420PTORGB {
    char *inputFilePath = "/Users/allen/Desktop/baby.mp4";
    char *outputVideoFilePath = "/Users/allen/Desktop/baby.rgb";
    //  定义输出rgb文件宽高
    int width = 1280;
    int height = 720;
    FILE *outVideoFile = fopen(outputVideoFilePath, "wb");

    uint8_t *video_buffer;
    AVFormatContext *formatCtx = NULL;
    AVCodec *videoCodec = NULL;
    AVCodecContext *videoCodecCtx = NULL;
    AVCodecParameters *videoCodecParams = NULL;
    AVFrame *frame,*frameYUV;
    AVPacket packet;
    enum AVPixelFormat outPutFormat = AV_PIX_FMT_RGB24;
    struct SwsContext *swsContext = NULL;
    
    av_register_all();
    if (avformat_open_input(&formatCtx, inputFilePath, NULL, NULL) != 0) {
        printf("打开文件失败");
    }
    if (avformat_find_stream_info(formatCtx, NULL) != 0) {
        printf("获取文件信息失败");
        exit(0);
    }

    int stream_video_index = -1;

    for (int i = 0; i < formatCtx->nb_streams; i++) {
        if (formatCtx->streams[i]->codecpar->codec_type == AVMEDIA_TYPE_VIDEO) {
            stream_video_index = i;
        }
    }
    if (stream_video_index == -1) {
        printf("找不到视频流");
        exit(0);
    }
    videoCodecParams = formatCtx->streams[stream_video_index]->codecpar;
    videoCodec = avcodec_find_decoder(videoCodecParams->codec_id);

    if (!videoCodec) {
        printf("找不到视频解码器");
        exit(0);
    }
    videoCodecCtx = avcodec_alloc_context3(videoCodec);

    if (videoCodecCtx) {
        int ret = avcodec_parameters_to_context(videoCodecCtx, videoCodecParams);
        if (ret < 0) {
            printf("avcodec_parameters_to_context 视频");
            exit(0);
        }
    }

    if (avcodec_open2(videoCodecCtx, videoCodec, NULL) != 0) {
        printf("打开视频解码器失败");
        exit(0);
    }
    int ret = 0;
    
    frame = av_frame_alloc();
    frameYUV = av_frame_alloc();
    
    int video_frame_cnt = 0;
    video_buffer = (uint8_t *)malloc(av_image_get_buffer_size(outPutFormat, width, height, 1));
    av_image_fill_arrays(frameYUV->data, frameYUV->linesize, video_buffer, videoCodecCtx->pix_fmt, width, height, 1);

    av_init_packet(&packet);
    av_dump_format(formatCtx, 0, inputFilePath, 0);

    swsContext = sws_getContext(videoCodecCtx->width, videoCodecCtx->height, videoCodecCtx->pix_fmt, width, height, outPutFormat, SWS_BICUBIC, NULL, NULL, NULL);
    while (av_read_frame(formatCtx, &packet) >= 0) {
        // 视频流
        if (packet.stream_index == stream_video_index) {
            ret = avcodec_send_packet(videoCodecCtx, &packet);
            if (ret != 0) {
                printf("发送视频解析失败");
                exit(0);
            }
            ret = avcodec_receive_frame(videoCodecCtx, frame);
            if (ret != 0) {
                printf("获取解码后的视频帧失败");
                exit(0);
            }
            int size = width * height;
            sws_scale(swsContext, (const uint8_t *const *)frame->data, frame->linesize, 0, videoCodecCtx->height, frameYUV->data, frameYUV->linesize);
            fwrite(frameYUV->data[0], 1, size * 3, outVideoFile);
            printf("video frame index: %d\n",video_frame_cnt);
            video_frame_cnt++;
            av_packet_unref(&packet);
        }
    }
    printf("finish encode \n");
    avcodec_free_context(&videoCodecCtx);
    avformat_close_input(&formatCtx);
    sws_freeContext(swsContext);
}

@end
