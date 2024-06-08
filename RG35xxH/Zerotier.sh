#!/bin/bash
#make by aclyyx
# ANBERNIC-RG35xx-h

if [ ! -f /usr/bin/mpv ]; then
    echo "Error: The necessary playback files are missing and the program cannot run."
    exit 1
fi
. /mnt/mod/ctrl/configs/key_config &>/dev/null
progdir=$(dirname "$0")
networkId=$(cat $progdir/zt-network-id.txt)

# 安装 zerotier
function install_zt() {
    if ! type zerotier-one >/dev/null 2>&1; then
        echo '正在安装 Zerotier';
        sync
        mpv --really-quiet --image-display-duration=3 "${progdir}/res/ztinstalling-0.png"
        if ! type curl >/dev/null 2>&1; then
            echo '正在安装 curl';
            apt-get update -y
            apt install curl -y
        fi
        curl -s https://install.zerotier.com | bash
        installer -pkg "${progdir}/res/ZeroTier One.pkg" -target /
        systemctl stop zerotier-one.service
        systemctl disable zerotier-one.service
        sync
        mpv --really-quiet --image-display-duration=3 "${progdir}/res/zt-0.png"
    fi
}
function enable_zt() {
    if type zerotier-one >/dev/null 2>&1; then
        # 正在开启
        sync
        mpv --really-quiet --image-display-duration=3 "${progdir}/res/ztstarting-0.png"
        systemctl start zerotier-one.service
        systemctl enable zerotier-one.service
        echo '已启动 Zerotier 服务';
        # 等待zt服务启动
        echo '3'; sleep 1s;
        echo '2'; sleep 1s;
        echo '1'; sleep 1s;
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
        status_zt $1
        sync
        mpv --really-quiet --image-display-duration=3 "${progdir}/res/ztdone-0.png"
    fi
}
function disable_zt() {
    if type zerotier-one >/dev/null 2>&1; then
        # 正在关闭
        sync
        mpv --really-quiet --image-display-duration=3 "${progdir}/res/ztstopping-0.png"
        systemctl stop zerotier-one.service
        systemctl disable zerotier-one.service
        echo '已停止 Zerotier 服务';
        status_zt $1
        sync
        mpv --really-quiet --image-display-duration=3 "${progdir}/res/ztdone-0.png"
    fi
}
function leave_zt() {
    # 正在离开
    sync
    mpv --really-quiet --image-display-duration=3 "${progdir}/res/ztleaving-0.png"
    # 判断是否启动zt服务
    if ! systemctl status zerotier-one.service >/dev/null 2>&1; then
        systemctl start zerotier-one.service
    fi
    # 判断是否加入网络
    if zerotier-cli listnetworks |grep $networkId >/dev/null 2>&1; then
        echo '已加入网络，退出网络 '$networkId;
        zerotier-cli leave $networkId;
    fi
    # 关闭
    disable_zt $1
    # 卸载 zt
    dpkg -P zerotier-one
    sleep 1s;
    rm -rf /var/lib/zerotier-one/
}
function status_zt() {
    if systemctl status zerotier-one.service >/dev/null 2>&1; then
        echo 'Zerotier启动成功';
        mv "$0" "$progdir/Zerotier-已开启.sh"
    else
        echo 'Zerotier停止完成';
        mv "$0" "$progdir/Zerotier-已关闭.sh"
    fi
}

pkill -f mpv
pkill -f evtest
if type zerotier-one >/dev/null 2>&1; then
    # 显示开关图片
    mpv --really-quiet --image-display-duration=6000 "${progdir}/res/zt-0.png" &
else
    # 显示安装zt图片
    mpv --really-quiet --image-display-duration=6000 "${progdir}/res/ztnone-0.png" &
fi

while true
do
    Test_Button_A
    if [ "$?" -eq "10" ]; then
        pkill -f mpv
        disable_zt $1
        break
    fi
    Test_Button_B
    if [ "$?" -eq "10" ]; then
        pkill -f mpv
        leave_zt $1
        break
    fi
    Test_Button_X
    if [ "$?" -eq "10" ]; then
        pkill -f mpv
        install_zt $1
    fi
    Test_Button_Y
    if [ "$?" -eq "10" ]; then
        pkill -f mpv
        enable_zt $1
        break
    fi
    Test_Button_FUNC
    if [ "$?" -eq "10" ]; then
        status_zt $1
        break
    fi
done
pkill -f mpv
pkill -f evtest
exit 0