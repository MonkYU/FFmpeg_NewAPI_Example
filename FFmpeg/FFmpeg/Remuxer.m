//
//  Remuxer.m
//  FFmpeg
//
//  Created by Lizeyu on 2018/3/12.
//  Copyright © 2018年 DataChart. All rights reserved.
//

#import "Remuxer.h"
#import "FFHeader.h"

@implementation Remuxer

- (void)reMuxer {
    AVOutputFormat *ofmt = NULL;
    AVFormatContext *ifmt_ctx = NULL, *ofmt_ctx = NULL;
    AVPacket pkt;
    const char *in_filename = "/Users/allen/Desktop/baby.mp4";
    const char *out_filename = "/Users/allen/Desktop/baby.flv";
    int ret = 0;
    av_register_all();
    ret = avformat_open_input(&ifmt_ctx, in_filename, 0, 0);
    if (ret < 0) {
        printf("avformat_open_input failed \n");
        exit(0);
    }
    ret = avformat_find_stream_info(ifmt_ctx, 0);
    if (ret < 0) {
        printf("avformat_find_stream_info failed \n");
        exit(0);
    }
    av_dump_format(ifmt_ctx, 0, in_filename, 0);
    
    /// 输出
    ret = avformat_alloc_output_context2(&ofmt_ctx, NULL, NULL, out_filename);
    if (ret < 0) {
        printf("avformat_alloc_output_context2 failed \n");
        exit(0);
    }
    ofmt = ofmt_ctx->oformat;
    for (int i = 0; i < ifmt_ctx->nb_streams; i++) {
        AVStream *in_stream = ifmt_ctx->streams[i];
        AVCodecParameters *in_parameter = in_stream->codecpar;
        AVCodec *in_codec = NULL;
        in_codec = avcodec_find_decoder(in_parameter->codec_id);
        if (!in_codec) {
            printf("avcodec_find_decoder failed \n");
            exit(0);
        }
        AVStream *out_stream = avformat_new_stream(ofmt_ctx, in_codec);
        if (!out_stream) {
            printf("failed allocating output stream \n");
            exit(0);
        }
        ret = avcodec_parameters_copy(out_stream->codecpar, in_stream->codecpar);
        if (ret < 0) {
            printf("avcodec_parameters_copy failed \n");
            exit(0);
        }
        out_stream->codecpar->codec_tag = 0;
    }
    av_dump_format(ofmt_ctx, 0, out_filename, 1);
    if (!(ofmt->flags & AVFMT_NOFILE)) {
        ret = avio_open(&ofmt_ctx->pb, out_filename, AVIO_FLAG_WRITE);
        if (ret < 0) {
            printf("could not open output file '%s'",out_filename);
            exit(0);
        }
    }
    ret = avformat_write_header(ofmt_ctx, NULL);
    if (ret < 0) {
        printf("error occurred when opening output file \n");
        exit(0);
    }
    int frame_index = 0;
    while (1) {
        AVStream *in_stream, *out_stream;
        ret = av_read_frame(ifmt_ctx, &pkt);
        if (ret < 0) {
            break;
        }
        in_stream = ifmt_ctx->streams[pkt.stream_index];
        out_stream = ofmt_ctx->streams[pkt.stream_index];
        /// copy packet
        /// 转换PTS/DTS (convert pts/dts)
        pkt.pts = av_rescale_q_rnd(pkt.pts, in_stream->time_base, out_stream->time_base, (AV_ROUND_NEAR_INF|AV_ROUND_PASS_MINMAX));
        pkt.dts = av_rescale_q_rnd(pkt.dts, in_stream->time_base, out_stream->time_base,(AV_ROUND_NEAR_INF|AV_ROUND_PASS_MINMAX));
        pkt.duration = av_rescale_q(pkt.duration, in_stream->time_base, out_stream->time_base);
        pkt.pos = -1;
        ret = av_interleaved_write_frame(ofmt_ctx, &pkt);
        if (ret < 0) {
            printf("error muxing packet \n");
            exit(0);
        }
        printf("write %8d frames to output file \n",frame_index);
        av_packet_unref(&pkt);
        frame_index++;
    }
    av_write_trailer(ofmt_ctx);
}

@end
