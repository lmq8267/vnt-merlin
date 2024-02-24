#! /bin/sh

export KSROOT=/koolshare
source $KSROOT/scripts/base.sh
eval `dbus export vnt_`
en=`dbus get vnt_enable`
en2=`dbus get vnts_enable`
if [ "${en}"x = "1"x ] || [ "${en2}"x = "1"x ] ; then
    sh /koolshare/scripts/vnt_config.sh stop
fi
confs=`dbus list vnt|cut -d "=" -f1`

for conf in $confs
do
	dbus remove $conf
done

sleep 1
find /koolshare/init.d/ -name "*vnt*" | xargs rm -rf
rm -rf /koolshare/scripts/vnt*
rm -rf /koolshar/init.d/?99vnt.sh
rm -rf /koolshare/bin/vnt*
rm -rf /koolshare/webs/Module_vnt.asp
rm -rf /koolshare/res/icon-vnt.png

echo "【$(TZ=UTC-8 date -R +%Y年%m月%d日\ %X)】: 卸载完成，江湖有缘再见~"
rm -rf /koolshare/scripts/uninstall_vnt.sh
