#!/bin/bash
#make by aclyyx
# ANBERNIC-RG35xx-h-MOD

progdir=$(cd $(dirname $0); pwd)
if [ ! -f /usr/bin/mpv ]; then
    echo "Error: The necessary playback files are missing and the program cannot run.">>${progdir}/a.txt
    exit 1
fi
# . /mnt/mod/ctrl/configs/functions &>>${progdir}/a.txt 2>&1
networkId=$(cat $progdir/zt-network-id.txt)

# 安装 zerotier
function install_zt() {
    if ! type zerotier-one >/dev/null 2>&1; then
        echo '正在安装 Zerotier';
        sync
        [ -z ${1} ] && mpv $rotate_28 --really-quiet --image-display-duration=3 "${progdir}/res/ztinstalling-${LANG_CUR}.png"
        curl -s https://install.zerotier.com | bash;
        systemctl stop zerotier-one.service
        systemctl disable zerotier-one.service
        sync
        [ -z ${1} ] && mpv $rotate_28 --really-quiet --image-display-duration=3 "${progdir}/res/zt-${LANG_CUR}.png"
    fi
}
function enable_zt() {
    if type zerotier-one >/dev/null 2>&1; then
        # 正在开启
        sync
        [ -z ${1} ] && mpv $rotate_28 --really-quiet --image-display-duration=3 "${progdir}/res/ztstarting-${LANG_CUR}.png"
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
        [ -z ${1} ] && mpv $rotate_28 --really-quiet --image-display-duration=3 "${progdir}/res/ztdone-${LANG_CUR}.png"
    fi
}
function disable_zt() {
    if type zerotier-one >/dev/null 2>&1; then
        # 正在关闭
        sync
        [ -z ${1} ] && mpv $rotate_28 --really-quiet --image-display-duration=3 "${progdir}/res/ztstopping-${LANG_CUR}.png"
        systemctl stop zerotier-one.service
        systemctl disable zerotier-one.service
        echo '已停止 Zerotier 服务';
        status_zt $1
        sync
        [ -z ${1} ] && mpv $rotate_28 --really-quiet --image-display-duration=3 "${progdir}/res/ztdone-${LANG_CUR}.png"
    fi
}
function leave_zt() {
    # 正在离开
    sync
    [ -z ${1} ] && mpv $rotate_28 --really-quiet --image-display-duration=3 "${progdir}/res/ztleaving-${LANG_CUR}.png"
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
        [ $LANG_CUR -eq 0 ] && mv "$0" "$progdir/Zerotier-已开启.sh"
        [ $LANG_CUR -eq 3 ] && mv "$0" "$progdir/Zerotier-オープン.sh"
        [ $LANG_CUR -eq 2 ] && mv "$0" "$progdir/Zerotier-ON.sh"
    else
        echo 'Zerotier停止完成';
        [ $LANG_CUR -eq 0 ] && mv "$0" "$progdir/Zerotier-已关闭.sh"
        [ $LANG_CUR -eq 3 ] && mv "$0" "$progdir/Zerotier-閉じる.sh"
        [ $LANG_CUR -eq 2 ] && mv "$0" "$progdir/Zerotier-OFF.sh"
    fi
}

pkill -f mpv
pkill -f evtest
if type zerotier-one >/dev/null 2>&1; then
    # 显示开关图片
    mpv $rotate_28 --really-quiet --image-display-duration=6000 "${progdir}/res/zt-${LANG_CUR}.png" &
else
    # 显示安装zt图片
    mpv $rotate_28 --really-quiet --image-display-duration=6000 "${progdir}/res/ztnone-${LANG_CUR}.png" &
fi
get_devices

(
     for INPUT_DEVICE in ${INPUT_DEVICES[@]}
     do
     evtest "${INPUT_DEVICE}" 2>&1 &
     done
     wait
) | while read line; do
    case $line in
        (${CONTROLLER_DISCONNECTED})
        echo "Reloading due to ${CONTROLLER_DEVICE} reattach..." 2>&1
        get_devices
        ;;
        (${DEVICE_DISCONNECTED})
        echo "Reloading due to ${DEVICE} reattach..." 2>&1
        get_devices
        ;;
        (${X_KEY})
            if [[ "${line}" =~ ${PRESS} ]]; then
                continue
            elif [[ "${line}" =~ ${RELEASE} ]]; then
                pkill -f mpv
                install_zt $1
            fi
        ;;
        (${A_KEY})
            if [[ "${line}" =~ ${PRESS} ]]; then
                continue
            elif [[ "${line}" =~ ${RELEASE} ]]; then
                pkill -f mpv
                disable_zt $1
                user_quit
            fi
        ;;
        (${Y_KEY})
            if [[ "${line}" =~ ${PRESS} ]]; then
                continue
            elif [[ "${line}" =~ ${RELEASE} ]]; then
                pkill -f mpv
                enable_zt $1
                user_quit
            fi
        ;;
        (${B_KEY})
            if [[ "${line}" =~ ${PRESS} ]]; then
                continue
            elif [[ "${line}" =~ ${RELEASE} ]]; then
                pkill -f mpv
                leave_zt $1
                user_quit
            fi
        ;;
        (${FUNC_KEY_EVENT})
            if [[ "${line}" =~ ${PRESS} ]]; then
                continue
            elif [[ "${line}" =~ ${RELEASE} ]]; then
                status_zt $1
                user_quit
            fi
        ;;
    esac
done