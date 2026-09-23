#!/bin/sh

#
#   TVerDown 実行
#
#set -x

instdir=`dirname $0`

if [ ! -d "$HOME/.config/TVerDown" ]
then
   export TVERDOWN_CONF_DIR="${instdir}/config"
fi

if [ "$1" = "--httpd" ]
then
    shift
    ruby ${instdir}/httpd.rb $* > /tmp/TVerdown-httpd.log 2>&1 &
    exit
fi

# for Ver2
ruby ${instdir}/watchNewProg2.rb $*
echo
echo "---------------------------------------------"
echo
ruby ${instdir}/TVerDown2.rb $*


# for Ver1
# ruby ${instdir}/old/watchNewProg.rb $*
# echo "---------------------------------------------"
# ruby ${instdir}/old/makeTarget.rb -M
# echo "---------------------------------------------"
# echo
# ruby ${instdir}/old/TVerDown.rb $*





