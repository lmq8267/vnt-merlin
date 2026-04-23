#!/bin/sh

export KSROOT=/koolshare
source $KSROOT/scripts/base.sh
vnt_pid=`pidof vnt-cli`
if [ -n "$vnt_pid" ];then
        cliver=`dbus get vntcli_version`
        [ ! -z "$cliver" ] && cliver="vnt-cli $cliver "
	vntcli_log="$cliver<span style='color:  #7FFF00'>运行中 PID：$vnt_pid </span>"
else
	vntcli_log="<span style='color:  #FF0000'>未运行</span>"
fi
vnts_pid=`pidof vnts`

if [ -n "$vnts_pid" ];then
        sver=`dbus get vnts_version`
        [ ! -z "$sver" ] && sver="vnts $sver "
	vnts_log="$sver<span style='color:  #7FFF00'>运行中 PID：$vnts_pid </span>"
else
	vnts_log="<span style='color:  #FF0000'>未运行</span>"
fi
http_response "$vntcli_log | $vnts_log"
