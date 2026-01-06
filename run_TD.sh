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

ruby ${instdir}/watchNewProg.rb $*
echo "---------------------------------------------"
ruby ${instdir}/makeTarget.rb -M
echo "---------------------------------------------"
echo
ruby ${instdir}/TVerDown.rb $*





