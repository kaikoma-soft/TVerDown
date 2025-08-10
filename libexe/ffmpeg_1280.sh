#!/bin/sh

#set -x

ffmpeg -y -i \
       "${INPUT}"  \
       -vf scale=1280:-1 \
       -c:v hevc -crf 26 -tune animation -c:a copy \
       "${OUTPUT}"

