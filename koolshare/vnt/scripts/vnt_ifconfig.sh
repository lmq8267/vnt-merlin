#!/bin/sh

export KSROOT=/koolshare
source $KSROOT/scripts/base.sh
# 获取 ifconfig 输出
vnt_ifconfig=$(ifconfig)

# 初始化结果字符串
result=""

# 使用 IFS 逐行读取 ifconfig 输出
IFS=$'\n'
for line in $vnt_ifconfig; do
    # 检测是否是网络接口
    if echo "$line" | grep -q 'Link encap:'; then
        # 获取网卡名
        interface=$(echo "$line" | awk '{print $1}')

        # 查找 IPv4 地址
        ipv4_addr=$(echo "$vnt_ifconfig" | grep -A 2 "$interface" | grep -o 'inet addr:[^ ]*' | cut -d ':' -f 2)

        # 如果有 IPv4 地址，则添加到结果
        if [ -n "$ipv4_addr" ]; then
            result="$result$interface|$ipv4_addr\n"
        else
            # 如果没有 IPv4 地址，查找 IPv6 地址
            ipv6_addr=$(echo "$vnt_ifconfig" | grep -A 2 "$interface" | grep -o 'inet6 addr: [^ ]*' | cut -d ' ' -f 3)
            if [ -n "$ipv6_addr" ]; then
                # 仅输出没有后缀的 IPv6 地址
                ipv6_addr_no_suffix=$(echo "$ipv6_addr" | cut -d '/' -f 1)
                result="$result$interface|$ipv6_addr_no_suffix\n"
            fi
        fi
    fi
done

# 输出结果，过滤掉没有 | 的行
if [ -n "$result" ]; then
    # 使用grep过滤result中的有效行
    result=$(echo -e "$result" | tr '\n' '&' | sed 's/&$//')
    echo -e "$result"
fi

http_response "$result"
