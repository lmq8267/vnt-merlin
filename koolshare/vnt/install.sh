#! /bin/sh

source /koolshare/scripts/base.sh
eval `dbus export vnt_`
eval `dbus export vnts_`
alias echo_date='echo 【$(TZ=UTC-8 date -R +%Y年%m月%d日\ %X)】:'

DIR=$(cd $(dirname $0); pwd)

en=`dbus get vnt_enable`
en2=`dbus get vnts_enable`

if [ ! -d "/koolshare" ] ; then
  echo_date "你的固件不是koolshare梅林，无法安装此插件包，请正确选择插件包！"
  rm -rf /tmp/vnt* >/dev/null 2>&1
  exit 1
fi
if [ "${en}"x = "1"x ] || [ "${en2}"x = "1"x ] ; then
    sh /koolshare/scripts/vnt_config.sh stop
fi
find /koolshare/init.d/ -name "*vnt.sh*"|xargs rm -rf
cd /tmp

cp -rf /tmp/vnt/scripts/* /koolshare/scripts/
cp -rf /tmp/vnt/webs/* /koolshare/webs/
cp -rf /tmp/vnt/res/* /koolshare/res/
cp /tmp/vnt/uninstall.sh /koolshare/scripts/uninstall_vnt.sh
ln -sf /koolshare/scripts/vnt_config.sh /koolshare/init.d/S49vnt.sh


chmod +x /koolshare/scripts/vnt_*
chmod +x /koolshare/scripts/uninstall_vnt.sh
chmod +x /koolshare/init.d/S49vnt.sh
dbus set softcenter_module_vnt_description=简便高效的异地组网、内网穿透工具
dbus set softcenter_module_vnt_install=1
dbus set softcenter_module_vnt_name=vnt
dbus set softcenter_module_vnt_title=vnt
dbus set softcenter_module_vnt_version="$(cat $DIR/version)"

sleep 1
echo_date "vnt 插件安装完毕！"
rm -rf /tmp/vnt* >/dev/null 2>&1
en=`dbus get vnt_enable`
en2=`dbus get vnts_enable`
if [ "${en}"x = "1"x ] || [ "${en2}"x = "1"x ] ; then
    sh /koolshare/scripts/vnt_config.sh restart
fi
exit 0
