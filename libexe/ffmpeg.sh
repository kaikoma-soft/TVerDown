#!/bin/sh

#set -x

ffmpeg -y -i \
       "${INPUT}"  \
       -c:v hevc -crf 26 -c:a copy \
       "${OUTPUT}"

