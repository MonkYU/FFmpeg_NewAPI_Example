//
//  PCMResample.m
//  FFMpegNewAPIExample
//
//  Created by Lizeyu on 2018/2/27.
//  Copyright © 2018年 DataChart. All rights reserved.
//

#import "PCMResample.h"
#import "FFHeader.h"

@implementation PCMResample

+ (void)pcmResample {
    

    char *inputFilePath = "/Users/allen/Desktop/baby.mp4";
    char *outputAudioFilePath = "/Users/allen/Desktop/baby.pcm";

    FILE *outAudioFile = fopen(outputAudioFilePath, "wb");
    int ret = 0;
    int channels = 1;
    int out_sample_rate = 44100;
    
    AVFormatContext *formatCtx = NULL;
    AVCodec *audioCodec = NULL;
    AVCodecContext *audioCodecCtx = NULL;
    AVCodecParameters *audioCodecParams = NULL;
    AVFrame *audioInFrame = NULL;
    AVPacket packet;
    AVFrame *audioOutFrame = NULL;
    enum AVSampleFormat outPutResampleFormat = AV_SAMPLE_FMT_FLTP;
    struct SwrContext *swrContext = NULL;

    av_register_all();
    if (avformat_open_input(&formatCtx, inputFilePath, NULL, NULL) != 0) {
        printf("打开文件失败");
        exit(0);
    }
    if (avformat_find_stream_info(formatCtx, NULL) != 0) {
        printf("获取文件信息失败");
        exit(0);
    }

    int stream_audio_index = -1;

    for (int i = 0; i < formatCtx->nb_streams; i++) {
        if (formatCtx->streams[i]->codecpar->codec_type == AVMEDIA_TYPE_AUDIO) {
            stream_audio_index = i;
        }
    }

    if (stream_audio_index == -1) {
        printf("找不到音频流");
        exit(0);
    }

    audioCodecParams = formatCtx->streams[stream_audio_index]->codecpar;
    audioCodec = avcodec_find_decoder(audioCodecParams->codec_id);
    if (!audioCodec) {
        printf("找不到音频解码器\n");
        exit(0);
    }
    audioCodecCtx = avcodec_alloc_context3(audioCodec);
    if (audioCodecCtx) {
        int ret = avcodec_parameters_to_context(audioCodecCtx, audioCodecParams);
        if (ret < 0) {
            printf("avcodec_parameters_to_context 音频出错");
            exit(0);
        }
    }
    if (avcodec_open2(audioCodecCtx, audioCodec, NULL)) {
        printf("打开音频解码器失败");
        exit(0);
    }

    av_init_packet(&packet);
    av_dump_format(formatCtx, 0, inputFilePath, 0);
    audioOutFrame = av_frame_alloc();
    audioInFrame = av_frame_alloc();

    int out_buffer_size = av_samples_get_buffer_size(NULL, channels, 1024, outPutResampleFormat, 0);
    uint8_t *audio_out_buffer = (uint8_t *)av_malloc(out_buffer_size);
    audioOutFrame->nb_samples = 1024;
    ret = avcodec_fill_audio_frame(audioOutFrame, channels, outPutResampleFormat, audio_out_buffer, out_buffer_size, 0);

    if (ret < 0) {
        printf("av_samples_fill_arrays failed");
        exit(0);
    }

    int64_t out_channel_layout = AV_CH_LAYOUT_MONO; // 单声道MONO 双声道 STEREO
    swrContext = swr_alloc_set_opts(NULL, out_channel_layout, outPutResampleFormat, out_sample_rate, audioCodecCtx->channel_layout, audioCodecCtx->sample_fmt, audioCodecCtx->sample_rate, 0, NULL);
    swr_init(swrContext);
    
    int audio_frame_cnt = 0;
    
    while (av_read_frame(formatCtx, &packet) >= 0) {
        /// 音频流
        if (packet.stream_index == stream_audio_index) {
            ret = avcodec_send_packet(audioCodecCtx, &packet);
            if (ret != 0) {
                printf("avcodec_send_packet failed");
                exit(0);
            }
            ret = avcodec_receive_frame(audioCodecCtx, audioInFrame);
            if (ret != 0) {
                printf("avcodec_send_packet failed");
                exit(0);
            }
            if (av_sample_fmt_is_planar(audioInFrame->format)) {
                int out_samples = swr_convert(swrContext, audioOutFrame->data, audioOutFrame->nb_samples, (const uint8_t **)audioInFrame->data, audioInFrame->nb_samples);
                printf("decode audio frame: %d out_samples: %d \n",audio_frame_cnt,out_samples);
                fwrite(audioOutFrame->data[0], 1, audioOutFrame->linesize[0], outAudioFile);
                audio_frame_cnt++;
            }
        }
        av_packet_unref(&packet);
    }
    printf("resample success \n");
    avcodec_free_context(&audioCodecCtx);
    avformat_close_input(&formatCtx);
    swr_free(&swrContext);
}
@end
