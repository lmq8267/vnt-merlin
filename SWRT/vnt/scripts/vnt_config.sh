#!/bin/sh

source /jffs/softcenter/scripts/base.sh
eval `dbus export vnt_`
eval `dbus export vnts_`
mkdir -p /tmp/upload
mkdir -p /home/root/log
touch /home/root/log/vnt-cli.log
touch /home/root/log/vnts.log
vnt_log=/home/root/log/vnt-cli.log
vnts_log=/home/root/log/vnts.log

vnt_enable=`dbus get vnt_enable`
vnts_enable=`dbus get vnts_enable`
vnt_wg_enable=`dbus get vnt_wg_enable`
vnt_proxy_enable=`dbus get vnt_proxy_enable`
vnt_W_enable=`dbus get vnt_W_enable`
vnt_finger_enable=`dbus get vnt_finger_enable`
vnt_relay_enable=`dbus get vnt_relay_enable`
vnt_first_latency_enable=`dbus get vnt_first_latency_enable`
vnt_tun_name=`dbus get vnt_tun_name`
vnts_finger_enable=`dbus get vnts_finger_enable`
vnt_cron_time=`dbus get vnt_cron_time`
vnt_cron_hour_min=`dbus get vnt_cron_hour_min`
vnts_cron_time=`dbus get vnts_cron_time`
vnts_cron_hour_min=`dbus get vnts_cron_hour_min`
vnt_local_dev=`dbus get vnt_local_dev`
vnt_token=`dbus get vnt_token`
vnt_compressor=`dbus get vnt_compressor`
vnt_mapping=`dbus get vnt_mapping`
vnts_token=`dbus get vnts_token`
vnt_ipmode=`dbus get vnt_ipmode`
vnt_static_ip=`dbus get vnt_static_ip`
vnt_desvice_id=`dbus get vnt_desvice_id`
vnt_desvice_name=`dbus get vnt_desvice_name`
vnt_localadd=`dbus get vnt_localadd`
vnt_peeradd=`dbus get vnt_peeradd`
vnt_serveraddr=`dbus get vnt_serveraddr`
vnt_stunaddr=`dbus get vnt_stunaddr`
vnt_ipv4_mode=`dbus get vnt_ipv4_mode`
vnt_cron_type=`dbus get vnt_cron_type`
vnts_cron_type=`dbus get vnts_cron_type`
vnt_port=`dbus get vnt_port`
vnts_port=`dbus get vnts_port`
vnt_mtu=`dbus get vnt_mtu`
vnt_passmode=`dbus get vnt_passmode`
vnt_key=`dbus get vnt_key`
vnt_path=`dbus get vnt_path`
vnts_path=`dbus get vnts_path`
vnts_mask=`dbus get vnts_mask`
vnts_gateway=`dbus get vnts_gateway`
vnts_web=`dbus get vnts_web_enable`
vnts_web_port=`dbus get vnts_web_port`
vnts_web_pass=`dbus get vnts_web_pass`
vnts_web_user=`dbus get vnts_web_user`
vnts_web_wan=`dbus get vnts_web_wan`
user_agent='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/117.0.0.0 Safari/537.36'
lanaddr=$(ifconfig br0|grep -Eo "inet addr.+"|awk -F ":| " '{print $3}' 2>/dev/null)
if [ -z "$vnt_path" ] ; then
   JFFS_AVAIL=$(df | grep -w "/jffs$" | awk '{print $4}')
   if [ "${JFFS_AVAIL}" -lt "4096" ];then
       vnt_path=/tmp/var/vnt-cli
      dbus set vnt_path=$vnt_path
   else
      vnt_path=/jffs/softcenter/bin/vnt-cli
      dbus set vnt_path=$vnt_path
   fi
fi
if [ -z "$vnts_path" ] ; then
   JFFS_AVAIL=$(df | grep -w "/jffs$" | awk '{print $4}')
   if [ "${JFFS_AVAIL}" -lt "5084" ];then
       vnts_path=/tmp/var/vnts
      dbus set vnts_path=$vnts_path
   else
      vnts_path=/jffs/softcenter/bin/vnts
      dbus set vnts_path=$vnts_path
   fi
fi
cputype=$(uname -ms | tr ' ' '_' | tr '[A-Z]' '[a-z]')
[ -n "$(echo $cputype | grep -E "linux.*armv.*")" ] && cpucore="arm"
[ -n "$(echo $cputype | grep -E "linux.*armv7.*")" ] && [ -n "$(cat /proc/cpuinfo | grep vfp)" ] && cpucore="armv7"
[ -n "$(echo $cputype | grep -E "linux.*aarch64.*|linux.*armv8.*")" ] && cpucore="aarch64"
scriptname=$(basename $0)
proxy_url="https://hub.gitmirror.com/"
proxy_url2="http://gh.ddlc.top/"
# 时间同步
fun_ntp_sync(){
    ntp_server=`nvram get ntp_server0`
    start_time="`date +%Y%m%d`"
    ntpclient -h ${ntp_server} -i3 -l -s > /dev/null 2>&1
    if [ "${start_time}"x = "`date +%Y%m%d`"x ]; then
        ntpclient -h ntp1.aliyun.com -i3 -l -s > /dev/null 2>&1
    fi
}

logg () {
   #logger -t "【vnt】" "$1"
   echo -e "\033[36;1m【$(TZ=UTC-8 date -R +%Y年%m月%d日\ %X)】: \033[0m\033[35;1m$1 \033[0m"
   if [ "$2" = "vnt-cli" ] ; then
   echo "【$(TZ=UTC-8 date -R +%Y年%m月%d日\ %X)】: $1 " >>$vnt_log
   fi
   if [ "$2" = "vnts" ] ; then
   echo "【$(TZ=UTC-8 date -R +%Y年%m月%d日\ %X)】: $1 " >>$vnts_log
   fi
}

# 自启
fun_nat_start(){
    if [ "${vnt_enable}"x = "1"x ] || [ "${vnts_enable}"x = "1"x ];then
	    [ ! -L "/jffs/softcenter/init.d/S99vnt.sh" ] && ln -sf /jffs/softcenter/scripts/vnt_config.sh /jffs/softcenter/init.d/S99vnt.sh
            #[ ! -L "/jffs/softcenter/init.d/N29vnt.sh" ] && ln -sf /jffs/softcenter/scripts/vnt_config.sh /jffs/softcenter/init.d/N29vnt.sh
	    #如果出现开机不自启，尝试去掉上方代码前的 # 号试试
    fi
}
# 定时任务
fun_crontab(){
    if [ "${vnt_enable}" != "1" ] || [ "${vnt_cron_time}"x = "0"x ];then
        [ -n "$(cru l | grep vnt_monitor)" ] && cru d vnt_monitor
    fi
    if [ "${vnts_enable}" != "1" ] || [ "${vnts_cron_time}"x = "0"x ];then
        [ -n "$(cru l | grep vnts_monitor)" ] && cru d vnts_monitor
    fi
     if [ "${vnt_cron_hour_min}" == "min" ] && [ "${vnt_cron_time}"x != "0"x ] ; then
        if [ "${vnt_cron_type}" == "watch" ]; then
        	cru a vnt_monitor "*/"${vnt_cron_time}" * * * * /bin/sh /jffs/softcenter/scripts/vnt_config.sh watchvnt"
        elif [ "${vnt_cron_type}" == "start" ]; then
            cru a vnt_monitor "*/"${vnt_cron_time}" * * * * /bin/sh /jffs/softcenter/scripts/vnt_config.sh restartvnt"
    	fi
    elif [ "${vnt_cron_hour_min}" == "hour" ] && [ "${vnt_cron_time}"x != "0"x ] ; then
        if [ "${vnt_cron_type}" == "watch" ]; then
            cru a vnt_monitor "0 */"${vnt_cron_time}" * * * /bin/sh /jffs/softcenter/scripts/vnt_config.sh watchvnt"
        elif [ "${vnt_cron_type}" == "start" ]; then
            cru a vnt_monitor "0 */"${vnt_cron_time}" * * * /bin/sh /jffs/softcenter/scripts/vnt_config.sh restartvnt"
        fi
    fi
      if [ "${vnts_cron_hour_min}" == "min" ] && [ "${vnts_cron_time}"x != "0"x ] ; then
        if [ "${vnts_cron_type}" == "watch" ]; then
        	cru a vnts_monitor "*/"${vnts_cron_time}" * * * * /bin/sh /jffs/softcenter/scripts/vnt_config.sh watchvnts"
        elif [ "${vnts_cron_type}" == "start" ]; then
            cru a vnts_monitor "*/"${vnts_cron_time}" * * * * /bin/sh /jffs/softcenter/scripts/vnt_config.sh restartvnts"
    	fi
    elif [ "${vnts_cron_hour_min}" == "hour" ] && [ "${vnts_cron_time}"x != "0"x ] ; then
        if [ "${vnts_cron_type}" == "watch" ]; then
            cru a vnts_monitor "0 */"${vnts_cron_time}" * * * /bin/sh /jffs/softcenter/scripts/vnt_config.sh watchvnts"
        elif [ "${vnts_cron_type}" == "start" ]; then
            cru a vnts_monitor "0 */"${vnts_cron_time}" * * * /bin/sh /jffs/softcenter/scripts/vnt_config.sh restartvnts"
        fi
    fi
}

# 关闭进程（先用默认信号，再使用9）
onkillvnt(){
    PID=$(pidof vnt-cli)
    [ -n "$(cru l | grep vnt_monitor)" ] && cru d vnt_monitor
    if [ -n "${PID}" ];then
		
		kill -9 "${PID}" >/dev/null 2>&1
                killall vnt-cli >/dev/null 2>&1
    fi
    [ -n "$(cru l | grep vnt_rules)" ] && cru d vnt_rules
    [ -n "$(cru l | grep vnt_rules2)" ] && cru d vnt_rules2
    [ -n "$(cru l | grep vnt_rules3)" ] && cru d vnt_rules3
    if [ ! -z "$vnt_tun_name" ] ; then
       vnt_tunname="${vnt_tun_name}"
    else
       vnt_tunname="vnt-tun"
    fi
   iptables -D INPUT -i ${vnt_tunname} -j ACCEPT 2>/dev/null
   iptables -D FORWARD -i ${vnt_tunname} -o ${vnt_tunname} -j ACCEPT 2>/dev/null
   iptables -D FORWARD -i ${vnt_tunname} -j ACCEPT 2>/dev/null
   iptables -t nat -D POSTROUTING -o ${vnt_tunname} -j MASQUERADE 2>/dev/null
   iptables -D OUTPUT -p tcp -j ACCEPT 2>/dev/null
   ip6tables -D OUTPUT -p tcp -j ACCEPT 2>/dev/null
   [ ! -z "$vnt_static_ip" ] && [ ! -z "$lanaddr" ] && iptables -t nat -D PREROUTING -p tcp -d ${vnt_static_ip} --dport 80 -j DNAT --to-destination ${lanaddr}:80 2>/dev/null
    if [ ! -z "$vnt_port" ] ; then
         if [ ! -z "$(echo $vnt_port | grep ',' )" ] ; then
	     vnt_tcp_port="${vnt_port%%,*}"
	 else
             vnt_tcp_port="$vnt_port"
         fi
	 iptables -D INPUT -p tcp --dport $vnt_tcp_port -j ACCEPT 2>/dev/null
         ip6tables -D INPUT -p tcp --dport $vnt_tcp_port -j ACCEPT 2>/dev/null
    fi
}
onkillvnts(){
    PIDS=$(pidof vnts)
    [ -n "$(cru l | grep vnts_monitor)" ] && cru d vnts_monitor
    if [ -n "${PIDS}" ];then
		kill -9 "${PIDS}" >/dev/null 2>&1
    fi
    killall -9 vnts 2>/dev/null
    [ -n "$(cru l | grep vnts_rules)" ] && cru d vnts_rules 
    [ -n "$(cru l | grep vnts_rules2)" ] && cru d vnts_rules2
    [ -n "$(cru l | grep vnts_rules3)" ] && cru d vnts_rules3
    iptables -D INPUT -p tcp --dport $vnts_port -j ACCEPT 2>/dev/null
    iptables -D INPUT -p udp --dport $vnts_port -j ACCEPT 2>/dev/null
    ip6tables -D INPUT -p tcp --dport $vnts_port -j ACCEPT 2>/dev/null
    ip6tables -D INPUT -p udp --dport $vnts_port -j ACCEPT 2>/dev/null
    iptables -D OUTPUT -p tcp --dport $vnts_port -j ACCEPT 2>/dev/null
    iptables -D OUTPUT -p udp --dport $vnts_port -j ACCEPT 2>/dev/null
    ip6tables -D OUTPUT -p tcp --dport $vnts_port -j ACCEPT 2>/dev/null
    ip6tables -D OUTPUT -p udp --dport $vnts_port -j ACCEPT 2>/dev/null
    if [ "$vnts_web" = 1 ] && [ ! -z "$vnts_web_port" ] && [ "$vnts_web_wan" = 1 ] ; then
      iptables -D INPUT -p tcp --dport $vnts_web_port -j ACCEPT 2>/dev/null
      ip6tables -D INPUT -p tcp --dport $vnts_web_port -j ACCEPT 2>/dev/null
      iptables -D OUTPUT -p tcp --dport $vnts_web_port -j ACCEPT 2>/dev/null
      ip6tables -D OUTPUT -p tcp --dport $vnts_web_port -j ACCEPT 2>/dev/null
   fi
} 
# 停止并清理
onstop(){
	onkillvnt
	onkillvnts
	logger "【软件中心】：关闭 vnt..."
        [ -z "$(pidof vnt-cli)" ] && logg "客户端已停止运行" "vnt-cli"
        [ -z "$(pidof vnts)" ] &&  logg "服务端已停止运行" "vnts"
}

fun_updatevnt(){
tag=""
curltest=`which curl`
if [ -z "$curltest" ] || [ ! -s "`which curl`" ] ; then
   tag="$( wget -T 5 -t 3 --user-agent "$user_agent" --max-redirect=0 --output-document=- https://api.github.com/repos/lmq8267/vnt-cli/releases/latest  2>&1 | grep 'tag_name' | cut -d\" -f4 )"
   [ -z "$tag" ] && tag="$( wget -T 5 -t 3 --user-agent "$user_agent" --quiet --output-document=-  https://api.github.com/repos/lmq8267/vnt-cli/releases/latest  2>&1 | grep 'tag_name' | cut -d\" -f4 )"
   [ -z "$tag" ] && tag="$( wget -T 5 -t 3 --output-document=-  https://api.github.com/repos/lmq8267/vnt-cli/releases/latest  2>&1 | grep 'tag_name' | cut -d\" -f4 )"
else
    tag="$( curl --connect-timeout 3 --user-agent "$user_agent"  https://api.github.com/repos/lmq8267/vnt-cli/releases/latest  2>&1 | grep 'tag_name' | cut -d\" -f4 )"
    [ -z "$tag" ] && tag="$( curl -L --connect-timeout 3 --user-agent "$user_agent" -s https://api.github.com/repos/lmq8267/vnt-cli/releases/latest  2>&1 | grep 'tag_name' | cut -d\" -f4 )"
    [ -z "$tag" ] && tag="$( curl -k -L --connect-timeout 20 -s https://api.github.com/repos/lmq8267/vnt-cli/releases/latest | grep 'tag_name' | cut -d\" -f4 )"
fi
[ -z "$tag" ] && tag="$( curl -k -L --connect-timeout 20 --silent https://api.github.com/repos/lmq8267/vnt-cli/releases/latest | grep 'tag_name' | cut -d\" -f4 )"
[ -z "$tag" ] && tag="$(curl -k --silent "https://api.github.com/repos/lmq8267/vnt-cli/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')"
logg "开始下载更新版本.." "vnt-cli" 
[ -z "$tag" ] && tag=v1.2.16
[ -x "${vnt_path}" ] || chmod 755 ${vnt_path}
vntcli_ver="$(${vnt_path} -h | grep version | awk -F ':' {'print $2'})"
if [ ! -z "$vntcli_ver" ] && [ ! -z "$tag" ] || [ ! -f "$vnt_path" ] ; then
 if [ "$vntcli_ver"x != "$(echo $tag | tr -d 'v \n')"x ] ; then
   logg "发现新版本 vnt-cli_${tag} 开始下载..." "vnt-cli" 
   case "${cpucore}" in 
    "arm")  
      curl -L -k -o /tmp/vnt-cli --connect-timeout 10 --retry 3 "${proxy_url}https://github.com/lmq8267/vnt-cli/releases/download/${tag}/vnt-cli_arm-unknown-linux-musleabi" || curl -L -k -o /tmp/vnt-cli --connect-timeout 10 --retry 3 "${proxy_url2}https://github.com/lmq8267/vnt-cli/releases/download/${tag}/vnt-cli_arm-unknown-linux-musleabi"
    ;;
    "armv7")  
      curl -L -k -o /tmp/vnt-cli --connect-timeout 10 --retry 3 "${proxy_url}https://github.com/lmq8267/vnt-cli/releases/download/${tag}/vnt-cli_armv7-unknown-linux-musleabi" || curl -L -k -o /tmp/vnt-cli --connect-timeout 10 --retry 3 "${proxy_url2}https://github.com/lmq8267/vnt-cli/releases/download/${tag}/vnt-cli_armv7-unknown-linux-musleabi"
    ;;
   "aarch64")  
     curl -L -k -o /tmp/vnt-cli --connect-timeout 10 --retry 3 "${proxy_url}https://github.com/lmq8267/vnt-cli/releases/download/${tag}/vnt-cli_aarch64-unknown-linux-musl" || curl -L -k -o /tmp/vnt-cli --connect-timeout 10 --retry 3 "${proxy_url2}https://github.com/lmq8267/vnt-cli/releases/download/${tag}/vnt-cli_aarch64-unknown-linux-musl" 
   ;;
   *)
     logg "未知cpu架构，无法下载..." "vnt-cli" 
   ;;
   esac
    chmod 755  /tmp/vnt-cli
   if [[ "$(/tmp/vnt-cli -h 2>&1 | wc -l)" -lt 3 ]] ; then
     logg "下载失败，无法更新..." "vnt-cli"
   else
     vntcli_ver="$(/tmp/vnt-cli -h | grep version | awk -F ':' {'print $2'})"
     if [ ! -z "$vntcli_ver" ] ; then
     cp -rf /tmp/vnt-cli ${vnt_path}
     dbus set vntcli_version=$vntcli_ver
     logg "已成功更新至${vntcli_ver}" "vnt-cli"
     fi
fi
else
  logg "当前版本${vntcli_ver} 最新版本${tag} 相同，无需更新 ..." "vnt-cli"
fi
else
  logg "获取当前版本${vntcli_ver} 最新版本${tag} 失败，无法更新 ..." "vnt-cli" 
fi
}

fun_updatevnts(){
tag=""
curltest=`which curl`
if [ -z "$curltest" ] || [ ! -s "`which curl`" ] ; then
   tag="$( wget -T 5 -t 3 --user-agent "$user_agent" --max-redirect=0 --output-document=- https://api.github.com/repos/lmq8267/vnts/releases/latest  2>&1 | grep 'tag_name' | cut -d\" -f4 )"
   [ -z "$tag" ] && tag="$( wget -T 5 -t 3 --user-agent "$user_agent" --quiet --output-document=-  https://api.github.com/repos/lmq8267/vnts/releases/latest  2>&1 | grep 'tag_name' | cut -d\" -f4 )"
   [ -z "$tag" ] && tag="$( wget -T 5 -t 3 --output-document=-  https://api.github.com/repos/lmq8267/vnts/releases/latest  2>&1 | grep 'tag_name' | cut -d\" -f4 )"
else
    tag="$( curl --connect-timeout 3 --user-agent "$user_agent"  https://api.github.com/repos/lmq8267/vnts/releases/latest  2>&1 | grep 'tag_name' | cut -d\" -f4 )"
    [ -z "$tag" ] && tag="$( curl -L --connect-timeout 3 --user-agent "$user_agent" -s https://api.github.com/repos/lmq8267/vnts/releases/latest  2>&1 | grep 'tag_name' | cut -d\" -f4 )"
    [ -z "$tag" ] && tag="$( curl -k -L --connect-timeout 20 -s https://api.github.com/repos/lmq8267/vnts/releases/latest | grep 'tag_name' | cut -d\" -f4 )"
fi
[ -z "$tag" ] && tag="$( curl -k -L --connect-timeout 20 --silent https://api.github.com/repos/lmq8267/vnts/releases/latest | grep 'tag_name' | cut -d\" -f4 )"
[ -z "$tag" ] && tag="$(curl -k --silent "https://api.github.com/repos/lmq8267/vnts/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')"
logg "开始下载更新版本.." "vnts" 
[ -z "$tag" ] && tag=1.2.13
[ -x "${vnts_path}" ] || chmod 755 ${vnts_path}
vnts_ver="$(${vnts_path} -V | awk -F 'version: ' '{print $2}' | tr -d ' \n')"
if [ ! -z "$vnts_ver" ] && [ ! -z "$tag" ] || [ ! -f "$vnts_path" ]  ; then
 if [ "$vnts_ver"x != "$(echo $tag | tr -d 'v \n')"x ] ; then
   logg "发现新版本 vnts_${tag} 开始下载..." "vnts" 
   case "${cpucore}" in 
    "arm")  
      curl -L -k -o /tmp/vnts --connect-timeout 10 --retry 3 "${proxy_url}https://github.com/lmq8267/vnts/releases/download/${tag}/vnts_arm-unknown-linux-musleabi" || curl -L -k -o /tmp/vnts --connect-timeout 10 --retry 3 "${proxy_url2}https://github.com/lmq8267/vnts/releases/download/${tag}/vnts_arm-unknown-linux-musleabi"
    ;;
    "armv7")  
      curl -L -k -o /tmp/vnts --connect-timeout 10 --retry 3 "${proxy_url}https://github.com/lmq8267/vnts/releases/download/${tag}/vnts_armv7-unknown-linux-musleabi" || curl -L -k -o /tmp/vnts --connect-timeout 10 --retry 3 "${proxy_url2}https://github.com/lmq8267/vnts/releases/download/${tag}/vnts_armv7-unknown-linux-musleabi"
    ;;
   "aarch64")  
     curl -L -k -o /tmp/vnts --connect-timeout 10 --retry 3 "${proxy_url}https://github.com/lmq8267/vnts/releases/download/${tag}/vnts_aarch64-unknown-linux-musl" || curl -L -k -o /tmp/vnts --connect-timeout 10 --retry 3 "${proxy_url2}https://github.com/lmq8267/vnts/releases/download/${tag}/vnts_aarch64-unknown-linux-musl" 
   ;;
   *)
     logg "未知cpu架构，无法下载..." "vnts" 
   ;;
   esac
    chmod 755  /tmp/vnts
   if [[ "$(/tmp/vnts -h 2>&1 | wc -l)" -lt 3 ]] ; then
     logg "下载失败，无法更新..." "vnts"
   else
     vnts_ver="$(/tmp/vnts -V | awk -F 'version: ' '{print $2}' | tr -d ' \n')"
     if [ ! -z "$vnts_ver" ] ; then
     mv -f /tmp/vnts ${vnts_path}
     dbus set vnts_version=$vnts_ver
     logg "已成功更新至${vnts_ver}" "vnts"
    fi
   fi
else
   logg "当前版本${vnts_ver} 最新版本${tag} 相同，无需更新 ..." "vnts"
fi
else
  logg "获取当前版本${vnts_ver} 最新版本${tag} 失败，无法更新 ..." "vnts" 
fi
}

fun_start_vnt(){
    fun_nat_start
    [ ! -f "${vnt_path}" ] && fun_updatevnt
    [ -x "${vnt_path}" ] || chmod 755 ${vnt_path}
    [[ "$($vnt_path -h 2>&1 | wc -l)" -lt 3 ]] && rm -rf ${vnt_path} && fun_updatevnt && fun_start_vnt
    vntcmd=""
    vntcli_ver="$(${vnt_path} -h | grep version | awk -F ':' {'print $2'})"
    dbus set vntcli_version=$vntcli_ver
    logg "开始启动vnt-cli_${vntcli_ver}" “vnt-cli”
    [ ! -L "/home/root/log/vnt-cli.0.log" ] && ln -sf /home/root/log/vnt-cli.log /home/root/log/vnt-cli.0.log
    [ ! -L "/home/root/log/vnt-cli.1.log" ] && ln -sf /home/root/log/vnt-cli.log /home/root/log/vnt-cli.1.log
    [ ! -L "/tmp/upload/vnt-cli.log" ] && ln -sf /home/root/log/vnt-cli.log /tmp/upload/vnt-cli.log
    log_path="$(dirname $vnt_path)"
    log_path="${log_path}/log4rs.yaml"
    if [ ! -f "$log_path" ] ; then
    cat > $log_path <<EOF
refresh_rate: 30 seconds
appenders:
  rolling_file:
    kind: rolling_file
    path: /home/root/log/vnt-cli.log
    append: true
    encoder:
      pattern: "{d(%Y-%m-%d %H:%M:%S vnt:)} [{f}:{L}] {h({l})} {M}:{m}{n}"
    policy:
      kind: compound
      trigger:
        kind: size
        limit: 1 mb
      roller:
        kind: fixed_window
        pattern: /home/root/log/vnt-cli.{}.log
        base: 1
        count: 2

root:
  level: info
  appenders:
    - rolling_file
EOF
    fi
    [ ! -z "$vnt_token" ] && vntcmd=" -k $vnt_token "
    [ "$vnt_ipmode" = "static" ] && [ ! -z "$vnt_static_ip" ] && vntcmd="$vntcmd --ip $vnt_static_ip "
    [ ! -z "$vnt_desvice_id" ] && vntcmd="$vntcmd -d $vnt_desvice_id "
    [ ! -z "$vnt_desvice_name" ] && vntcmd="$vntcmd -n $vnt_desvice_name "
    [ ! -z "$vnt_serveraddr" ] && vntcmd="$vntcmd -s $vnt_serveraddr "
    [ ! -z "$vnt_local_dev" ] && [ "$vnt_local_dev" != "不绑定" ] && vntcmd="$vntcmd --local-dev $vnt_local_dev "
    [ "$vnt_ipv4_mode" != "auto" ] && vntcmd="$vntcmd --punch $vnt_ipv4_mode "
    [ ! -z "$vnt_mtu" ] && vntcmd="$vntcmd -u $vnt_mtu "
    [ ! -z "$vnt_port" ] && vntcmd="$vntcmd --ports $vnt_port "
    [ ! -z "$vnt_key" ] && vntcmd="$vntcmd -w $vnt_key "
    [ "$vnt_proxy_enable" = "1" ] && vntcmd="$vntcmd --no-proxy "
    [ "$vnt_W_enable" = "1" ] && vntcmd="$vntcmd -W "
    [ "$vnt_passmode" != "off" ] && vntcmd="$vntcmd --model $vnt_passmode "
    [ "$vnt_finger_enable" = "1" ] && vntcmd="$vntcmd --finger "
    [ "$vnt_relay_enable" != "all" ] && vntcmd="$vntcmd --use-channel $vnt_relay_enable "
    [ "$vnt_compressor" != "off" ] && vntcmd="$vntcmd --compressor $vnt_compressor "
    if [ ! -z "$vnt_tun_name" ] ; then
       vnt_tunname="${vnt_tun_name}"
    else
       vnt_tunname="vnt-tun"
    fi
    [ "$vnt_wg_enable" = "1" ] && vntcmd="$vntcmd --allow-wg"
    [ "$vnt_first_latency_enable" = "1" ] && vntcmd="$vntcmd --first-latency"
    if [ ! -z "$vnt_localadd" ] ; then
       if echo "$vnt_localadd" | grep -q '|'; then
          localadd=""
         for val in $(echo $vnt_localadd | awk -F"|" '{for (i=1;i<=NF;i++) print $i}'); do
          localadd="$localadd -o $val"
          done
          localadd=$localadd
          vntcmd="$vntcmd $localadd "
      else
         vntcmd="$vntcmd -o $vnt_localadd "
       fi
    fi
    if [ ! -z "$vnt_peeradd" ] ; then
       if echo "$vnt_peeradd" | grep -q '|'; then
          peeradd=""
         for peerval in $(echo $vnt_peeradd | awk -F"|" '{for (i=1;i<=NF;i++) print $i}'); do
          peeradd="$peeradd -i $peerval"
          done
          peeradd=$peeradd
          vntcmd="$vntcmd $peeradd "
      else
         vntcmd="$vntcmd -i $vnt_peeradd "
       fi
    fi
    if [ ! -z "$vnt_stunaddr" ] ; then
       if echo "$vnt_stunaddr" | grep -q '|'; then
          stunaddr=""
         for stunval in $(echo $vnt_stunaddr | awk -F"|" '{for (i=1;i<=NF;i++) print $i}'); do
          stunaddr="$peeradd -e $stunval"
          done
          stunaddr=$stunaddr
          vntcmd="$vntcmd $stunaddr "
      else
         vntcmd="$vntcmd -e $vnt_stunaddr "
       fi
    fi
    if [ ! -z "$vnt_stunaddr" ] ; then
       if echo "$vnt_stunaddr" | grep -q '|'; then
          stunaddr=""
         for stunval in $(echo $vnt_stunaddr | awk -F"|" '{for (i=1;i<=NF;i++) print $i}'); do
          stunaddr="$peeradd -e $stunval"
          done
          stunaddr=$stunaddr
          vntcmd="$vntcmd $stunaddr "
      else
         vntcmd="$vntcmd -e $vnt_stunaddr "
       fi
    fi
    if [ ! -z "$vnt_mapping" ] ; then
       if echo "$vnt_mapping" | grep -q '|'; then
          mapping=""
         for mapval in $(echo $vnt_mapping | awk -F"|" '{for (i=1;i<=NF;i++) print $i}'); do
          mapping="$mapping --mapping $mapval"
          done
          mapping=$mapping
          vntcmd="$vntcmd $mapping "
      else
         vntcmd="$vntcmd --mapping $vnt_mapping "
       fi
    fi
    dbus set vnt_startcmd="$vnt_path $vntcmd"
    logg "当前客户端启动参数 $vnt_path $vntcmd " "vnt-cli"
    if [ "$(lsmod |grep tun |grep -wc tun)" == "0" ]; then
		insmod tun
    fi
    cd $(dirname $vnt_path)
    
    killall vnt-cli 2>/dev/null
    ./vnt-cli ${vntcmd} >>/home/root/log/vnt-cli.log 2>&1 &
   sleep 5
   [ ! -z "$(pidof vnt-cli)" ] && logg "vnt-cli_${vntcli_ver}客户端启动成功！" "vnt-cli" 
   echo `date +%s` > /tmp/vnt_time
   iptables -t nat -I POSTROUTING -o ${vnt_tunname} -j MASQUERADE
   iptables -I FORWARD -o ${vnt_tunname} -j ACCEPT
   iptables -I FORWARD -i ${vnt_tunname} -j ACCEPT
   iptables -I INPUT -i ${vnt_tunname} -j ACCEPT
   [ ! -z "$vnt_static_ip" ] && [ ! -z "$lanaddr" ] && iptables -t nat -I PREROUTING -p tcp -d ${vnt_static_ip} --dport 80 -j DNAT --to-destination ${lanaddr}:80
   [ "$vnt_proxy_enable" = "1" ] && echo 1 > /proc/sys/net/ipv4/ip_forward
   [ -z "$(cru l | grep vnt_rules)" ] && cru a vnt_rules "*/2 * * * * test -z \"\$(iptables -L -n -v | grep '$vnt_tunname')\" && /bin/sh /jffs/softcenter/scripts/vnt_config.sh restartvnt"
   if [ "$vnt_udp_mode" = "tcp" ] ; then
    #tcp直连需要放行端口，也就是客户端监听端口第一个，如果没有指定端口默认是随机的，所以放行所有tcp端口出去
      iptables -I OUTPUT -p tcp -j ACCEPT
      ip6tables -I OUTPUT -p tcp -j ACCEPT
      [ -z "$(cru l | grep vnt_rules2)" ] && cru a vnt_rules2 "*/2 * * * * iptables -C OUTPUT -p tcp -j ACCEPT || iptables -I OUTPUT -p tcp -j ACCEPT ; ip6tables -C OUTPUT -p tcp -j ACCEPT || ip6tables -I OUTPUT -p tcp -j ACCEPT"
      #进来的端口就不能放行所有，想要tcp直连那就只能指定客户端监听端口，放行这个端口进来
      if [ ! -z "$vnt_port" ] ; then
         if [ ! -z "$(echo $vnt_port | grep ',' )" ] ; then
	     vnt_tcp_port="${vnt_port%%,*}"
	 else
             vnt_tcp_port="$vnt_port"
         fi
	 iptables -I INPUT -p tcp --dport $vnt_tcp_port -j ACCEPT
         ip6tables -I INPUT -p tcp --dport $vnt_tcp_port -j ACCEPT
	 [ -z "$(cru l | grep vnt_rules3)" ] && cru a vnt_rules3 "*/2 * * * * iptables -C INPUT -p tcp --dport $vnt_tcp_port -j ACCEPT || iptables -I INPUT -p tcp --dport $vnt_tcp_port -j ACCEPT ; ip6tables -C INPUT -p tcp --dport $vnt_tcp_port -j ACCEPT || ip6tables -I INPUT -p tcp --dport $vnt_tcp_port -j ACCEPT"
      fi
   fi
}

fun_start_vnts(){
    fun_nat_start
    [ ! -f "${vnts_path}" ] && fun_updatevnts
    [ -x "${vnts_path}" ] || chmod 755 ${vnts_path}
    [[ "$($vnts_path -h 2>&1 | wc -l)" -lt 3 ]] && rm -rf ${vnts_path} && fun_updatevnts && fun_start_vnts
    vntscmd=""
    vnts_ver="$(${vnts_path} -V | awk '{print $2}')"
    dbus set vnts_version=$vnts_ver
    logg "开始启动vnts_${vnts_ver}" “vnts”
    [ ! -L "/home/root/log/vnts.0.log" ] && ln -sf /home/root/log/vnts.log /home/root/log/vnts.0.log
    [ ! -L "/home/root/log/vnts.1.log" ] && ln -sf /home/root/log/vnts.log /home/root/log/vnts.1.log
    [ ! -L "/tmp/upload/vnts.log" ] && ln -sf /home/root/log/vnts.log /tmp/upload/vnts.log
    [ ! -z "$vnts_port" ] && vntscmd="$vntscmd --port $vnts_port "
    [ ! -z "$vnts_mask" ] && vntscmd="$vntscmd --netmask $vnts_mask "
    [ ! -z "$vnts_gateway" ] && vntscmd="$vntscmd --gateway $vnts_gateway "
     if [ ! -z "$vnts_token" ] ; then
       if echo "$vnts_token" | grep -q '|'; then
          stoken=""
         for tokenval in $(echo $vnts_token | awk -F"|" '{for (i=1;i<=NF;i++) print $i}'); do
          stoken="$stoken --white-token $tokenval"
          done
          stoken=$stoken
          vntscmd="$vntcmd $stoken "
      else
         vntscmd="$vntscmd --white-token $vnts_token "
       fi
    fi
    if [ "$vnts_web" = 1 ] ; then
       [ ! -z "$vnts_web_port" ] && vntscmd="$vntscmd --web-port $vnts_web_port "
       [ ! -z "$vnts_web_user" ] && vntscmd="$vntscmd --username $vnts_web_user "
       [ ! -z "$vnts_web_pass" ] && vntscmd="$vntscmd --password $vnts_web_pass "
     else
       vntscmd="$vntscmd --web-port 0 "
    fi
    dbus set vnt_startcmds="$vnts_path $vntscmd"
    log_path="$(dirname $vnts_path)"
    mkdir -p ${log_path}/log
    log_path="${log_path}/log/log4rs.yaml"
     if [ ! -f "$log_path" ] ; then
    cat > $log_path <<EOF
refresh_rate: 30 seconds
appenders:
  rolling_file:
    kind: rolling_file
    path: /home/root/log/vnts.log
    append: true
    encoder:
      pattern: "{d(%Y-%m-%d %H:%M:%S vnts:)} [{f}:{L}] {h({l})} {M}:{m}{n}"
    policy:
      kind: compound
      trigger:
        kind: size
        limit: 1 mb
      roller:
        kind: fixed_window
        pattern: /home/root/log/vnts.{}.log
        base: 1
        count: 2

root:
  level: info
  appenders:
    - rolling_file
EOF
    fi
    logg "当前服务端启动参数 ${vnts_path} ${vntscmd} " "vnts"
    cd $(dirname $vnts_path)
    killall -9 vnts 2>/dev/null
    ./vnts ${vntscmd} >>/home/root/log/vnts.log 2>&1 &
   sleep 5
   [ ! -z "$(pidof vnts)" ] && logg "vnts_${vnts_ver}服务端启动成功！" "vnts"
   echo `date +%s` > /tmp/vnts_time
   iptables -I INPUT -p tcp --dport $vnts_port -j ACCEPT 2>/dev/null
   iptables -I INPUT -p udp --dport $vnts_port -j ACCEPT 2>/dev/null
   ip6tables -I INPUT -p tcp --dport $vnts_port -j ACCEPT 2>/dev/null
   ip6tables -I INPUT -p udp --dport $vnts_port -j ACCEPT 2>/dev/null
   iptables -I OUTPUT -p tcp --dport $vnts_port -j ACCEPT 2>/dev/null
   iptables -I OUTPUT -p udp --dport $vnts_port -j ACCEPT 2>/dev/null
   ip6tables -I OUTPUT -p tcp --dport $vnts_port -j ACCEPT 2>/dev/null
   ip6tables -I OUTPUT -p udp --dport $vnts_port -j ACCEPT 2>/dev/null
   if [ -z "$(cru l | grep vnts_rules)" ] && [ ! -z "$vnts_port" ] ; then
      cru a vnts_rules "*/2 * * * * iptables -C INPUT -p tcp --dport $vnts_port -j ACCEPT || iptables -I INPUT -p tcp --dport $vnts_port -j ACCEPT ; iptables -C INPUT -p udp --dport $vnts_port -j ACCEPT || iptables -I INPUT -p udp --dport $vnts_port -j ACCEPT ; ip6tables -C INPUT -p tcp --dport $vnts_port -j ACCEPT || ip6tables -I INPUT -p tcp --dport $vnts_port -j ACCEPT ; ip6tables -C INPUT -p udp --dport $vnts_port -j ACCEPT || ip6tables -I INPUT -p udp --dport $vnts_port -j ACCEPT"
   fi
   if [ -z "$(cru l | grep vnts_rules2)" ] && [ ! -z "$vnts_port" ] ; then
      cru a vnts_rules2 "*/2 * * * * iptables -C OUTPUT -p tcp --dport $vnts_port -j ACCEPT || iptables -I OUTPUT -p tcp --dport $vnts_port -j ACCEPT ; iptables -C OUTPUT -p udp --dport $vnts_port -j ACCEPT || iptables -I OUTPUT -p udp --dport $vnts_port -j ACCEPT ; ip6tables -C OUTPUT -p tcp --dport $vnts_port -j ACCEPT || ip6tables -I OUTPUT -p tcp --dport $vnts_port -j ACCEPT ; ip6tables -C OUTPUT -p udp --dport $vnts_port -j ACCEPT || ip6tables -I OUTPUT -p udp --dport $vnts_port -j ACCEPT"
   fi
   if [ "$vnts_web" = 1 ] && [ ! -z "$vnts_web_port" ] && [ "$vnts_web_wan" = 1 ] ; then
     iptables -I INPUT -p tcp --dport $vnts_web_port -j ACCEPT 2>/dev/null
     ip6tables -I INPUT -p tcp --dport $vnts_web_port -j ACCEPT 2>/dev/null
     iptables -I OUTPUT -p tcp --dport $vnts_web_port -j ACCEPT 2>/dev/null
     ip6tables -I OUTPUT -p tcp --dport $vnts_web_port -j ACCEPT 2>/dev/null
     if [ -z "$(cru l | grep vnts_rules3)" ] ; then
        cru a vnts_rules3 "*/2 * * * * iptables -C OUTPUT -p tcp --dport $vnts_web_port -j ACCEPT || iptables -I OUTPUT -p tcp --dport $vnts_web_port -j ACCEPT ; iptables -C INPUT -p tcp --dport $vnts_web_port -j ACCEPT || iptables -I INPUT -p tcp --dport $vnts_web_port -j ACCEPT ; ip6tables -C OUTPUT -p tcp --dport $vnts_web_port -j ACCEPT || ip6tables -I OUTPUT -p tcp --dport $vnts_web_port -j ACCEPT ; ip6tables -C INPUT -p tcp --dport $vnts_web_port -j ACCEPT || ip6tables -I INPUT -p tcp --dport $vnts_web_port -j ACCEPT"
     fi
   fi
}

fun_start_stop(){

 if [ "${vnt_enable}" = "1" ] ; then
  fun_start_vnt
 else
   onkillvnt
 fi
  if [ "${vnts_enable}" = "1" ] ; then
    fun_start_vnts
    else
    onkillvnts
    fi
}

vnt_info(){
 cd $(dirname $vnt_path)
 ./vnt-cli --info >/tmp/upload/vnt_info.log
}
vnt_all(){
 cd $(dirname $vnt_path)
 ./vnt-cli --all >/tmp/upload/vnt_all.log 
}
vnt_list(){
  cd $(dirname $vnt_path)
 ./vnt-cli --list >/tmp/upload/vnt_list.log
}
vnt_route(){
  cd $(dirname $vnt_path)
 ./vnt-cli --route >/tmp/upload/vnt_route.log
}
vnt_cmds(){
  vntcpu="$(top -b -n1 | grep -E "$(pidof vnt-cli)" 2>/dev/null| grep -v grep | awk '{for (i=1;i<=NF;i++) {if ($i ~ /vnt-cli/) break; else cpu=i}} END {print $cpu}')"
  [ ! -z "$vntcpu" ] && echo "vnt-cli CPU占用 ${vntcpu}% " >/tmp/upload/vnt_cmd.log
  vntram="$(cat /proc/$(pidof vnt-cli | awk '{print $NF}')/status|grep -w VmRSS|awk '{printf "%.2fMB\n", $2/1024}')"
  [ ! -z "$vntram" ] && echo "vnt-cli 内存占用 ${vntram}" >>/tmp/upload/vnt_cmd.log
  vnttime=$(cat /tmp/vnt_time) 
  if [ -n "$vnttime" ] ; then
  time=$(( `date +%s`-vnttime))
  day=$((time/86400))
   [ "$day" = "0" ] && day=''|| day=" $day天"
   time=`date -u -d @${time} +%H小时%M分%S秒`
   fi
   [ ! -z "$time" ] && echo "vnt-cli 已运行 $time" >>/tmp/upload/vnt_cmd.log 2>&1
   cmdtart=`dbus get vnt_startcmd`
   [ ! -z "$cmdtart" ] && echo "vnt-cli启动参数  $cmdtart" >>/tmp/upload/vnt_cmd.log 2>&1
   echo "流量统计：" >>/tmp/upload/vnt_cmd.log 2>&1
   cd $(dirname $vnt_path)
   ./vnt-cli --chart_a >>/tmp/upload/vnt_cmd.log 2>&1
}
vnts_cmds(){
  vntscpu="$(top -b -n1 | grep -E "$(pidof vnts)" 2>/dev/null| grep -v grep | awk '{for (i=1;i<=NF;i++) {if ($i ~ /vnts/) break; else cpu=i}} END {print $cpu}')"
  [ ! -z "$vntscpu" ] && echo "vnts CPU占用 ${vntscpu}% " >/tmp/upload/vnts_cmd.log
  vntsram="$(cat /proc/$(pidof vnts | awk '{print $NF}')/status|grep -w VmRSS|awk '{printf "%.2fMB\n", $2/1024}')"
  [ ! -z "$vntsram" ] && echo "vnts 内存占用 ${vntsram}" >>/tmp/upload/vnts_cmd.log
  vntstime=$(cat /tmp/vnts_time) 
  if [ -n "$vntstime" ] ; then
  time=$(( `date +%s`-vntstime))
  day=$((time/86400))
   [ "$day" = "0" ] && day=''|| day=" $day天"
   time=`date -u -d @${time} +%H小时%M分%S秒`
   fi
   [ ! -z "$time" ] && echo "已运行 $time" >>/tmp/upload/vnts_cmd.log 2>&1
   cmdstart=`dbus get vnt_startcmds`
   [ ! -z "$cmdstart" ] && echo "vnts启动参数  $cmdstart" >>/tmp/upload/vnts_cmd.log 2>&1
}

case $ACTION in
start)

    logger "【软件中心】：启动 vnt..."
	fun_start_stop
	fun_nat_start
	fun_crontab
	;;
stop)
	onstop
	;;
restart)
        onstop
        fun_start_stop
	fun_nat_start
	fun_crontab
	;;
watchvnt)
    [ -n "$(pidof vnt-cli)" ] && exit
    logger "【软件中心】定时任务：进程掉线，重新启动 vnt..."
    if [ "${vnt_enable}" != "1" ] ; then
   onkillvnt
   exit
   fi
   fun_start_vnt
	;;
watchvnts)
    [ -n "$(pidof vnts)" ] && exit
    logger "【软件中心】定时任务：进程掉线，重新启动 vnt..."
if [ "${vnts_enable}" != "1" ] ; then
   onkillvnts   
   exit  
fi
    fun_start_vnts
	;;
vinfo)
        vnt_info
	http_response "$1"
    ;;
all)
        vnt_all
	http_response "$1"
    ;;
list)
        vnt_list
	http_response "$1"
    ;;
route)
       vnt_route
	http_response "$1"
    ;;
vnt_cli)
        vnt_cmds
	http_response "$1"
    ;;
vnts)
        vnts_cmds
	http_response "$1"
    ;;
clearvntlog)
        true >${vnt_log}
	http_response "$1"
    ;;
clearvntslog)
       true >${vnts_log}
	http_response "$1"
    ;;
updatevnt)
        fun_updatevnt
	http_response "$1"
    ;;
updatevnts)
        fun_updatevnts
	http_response "$1"
    ;;
restartvnt)
if [ "${vnt_enable}" != "1" ] ; then
   onkillvnt
   http_response "$1"
   exit 
fi

	fun_start_vnt
	http_response "$1"
    ;;
restartvnts)

if [ "${vnts_enable}" != "1" ] ; then
   onkillvnts  
   http_response "$1"
   exit   
fi
	fun_start_vnts
	http_response "$1"
    ;;
esac
# 界面提交的参数
case $2 in
1)
        logger "【软件中心】：启动 vnt..."
	fun_start_stop
	fun_nat_start
	fun_crontab
	http_response "$1"
	;;
start)
    if [ "${vnt_enable}" != "1" ] ; then
   onkillvnt

fi
if [ "${vnts_enable}" != "1" ] ; then
   onkillvnts
  
fi
    logger "【软件中心】：启动 vnt..."
	fun_start_stop
	fun_nat_start
	fun_crontab
	;;
stop)
	onstop
	;;
restart)
        onstop
        fun_start_stop
	fun_nat_start
	fun_crontab
	;;
vinfo)
        vnt_info
	http_response "$1"
    ;;
all)
        vnt_all 
	http_response "$1"
    ;;
list)
        vnt_list
	http_response "$1"
    ;;
route)
       vnt_route
	http_response "$1"
    ;;
vnt_cli)
        vnt_cmds
	http_response "$1"
    ;;
vnts)
        vnts_cmds
	http_response "$1"
    ;;
clearvntlog)
        true >${vnt_log}
	http_response "$1"
    ;;
clearvntslog)
       true >${vnts_log}
	http_response "$1"
    ;;
updatevnt)
	http_response "$1"
        fun_updatevnt
    ;;
updatevnts)
	http_response "$1"
        fun_updatevnts
    ;;
restartvnt)
       if [ "${vnt_enable}" != "1" ] ; then
   onkillvnt
   http_response "$1"
   exit 
fi
	http_response "$1"
	fun_start_vnt
    ;;
restartvnts)
	if [ "${vnts_enable}" != "1" ] ; then
   onkillvnts
   http_response "$1"
   exit 
fi
	http_response "$1"
	fun_start_vnts
    ;;
esac
