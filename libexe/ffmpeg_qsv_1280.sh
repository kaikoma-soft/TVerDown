#!/bin/sh

#set -x

ffmpeg -y -hwaccel qsv -c:v h264_qsv -i \
       "${INPUT}"  \
       -vf scale_qsv=w=1280:h=-1,hwdownload,format=nv12 \
       -pix_fmt yuv420p -c:v hevc -crf 26 -tune animation  -c:a copy \
       "${OUTPUT}"


