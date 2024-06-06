#!/bin/bash
#make by aclyyx
# ANBERNIC-RG35xx-h

progdir=$(cd $(dirname $0); pwd)
networkId=$(cat $progdir/zt-network-id.txt)

echo $networkId > $progdir/a.txt
echo $progdir

# 判断是否安装 zerotier
if ! type zerotier-one >/dev/null 2>&1; then
    echo '正在安装 Zerotier';
    curl -s https://install.zerotier.com | bash;
else
    echo '已安装 Zerotier';
    # 判断是否启动zt服务
    if ! systemctl status zerotier-one.service >/dev/null 2>&1; then
        systemctl start zerotier-one.service
        systemctl enable zerotier-one.service
        echo '已启动 Zerotier 服务';
    else
        systemctl stop zerotier-one.service
        systemctl disable zerotier-one.service
        echo '已停止 Zerotier 服务';
    fi
fi

# 等待zt服务启动
echo '3';
sleep 1s;
echo '2';
sleep 1s;
echo '1';
sleep 1s;
echo '0';

# 判断是否启动zt服务
if systemctl status zerotier-one.service >/dev/null 2>&1; then
    # 判断是否加入网络
    if ! zerotier-cli listnetworks |grep $networkId >/dev/null 2>&1; then
        echo '正在加入网络 '$networkId;
        zerotier-cli join $networkId;
    else
        echo '已加入网络 '$networkId;
    fi
fi

if systemctl status zerotier-one.service >/dev/null 2>&1; then
    echo 'Zerotier启动成功';
    mv "$0" "$progdir/Zerotier-已开启.sh"
else
    echo 'Zerotier停止完成';
    mv "$0" "$progdir/Zerotier-已关闭.sh"
fi