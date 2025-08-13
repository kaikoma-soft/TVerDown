#!/bin/sh
#
#   x265 変換の実行
#
#set -x

TMP="/tmp/tmp.$$"

ps -aef > $TMP
if grep ffmpeg $TMP > /dev/null
then
    rm -f $TMP
    exit
fi
rm -f $TMP


instdir=`dirname $0`

if [ ! -d "$HOME/.config/TVerDown" ]
then
   export TVERDOWN_CONF_DIR="${instdir}/config"
fi

ruby ${instdir}/x265conv.rb -M 1 $*






