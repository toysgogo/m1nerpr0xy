#!/bin/bash
stty erase ^H

red='\e[91m'
green='\e[92m'
yellow='\e[94m'
magenta='\e[95m'
cyan='\e[96m'
none='\e[0m'

_red() { echo -e ${red}$*${none}; }
_green() { echo -e ${green}$*${none}; }
_yellow() { echo -e ${yellow}$*${none}; }
_magenta() { echo -e ${magenta}$*${none}; }
_cyan() { echo -e ${cyan}$*${none}; }

# Root
[[ $(id -u) != 0 ]] && echo -e "\n 请使用 ${red}root ${none}用户运行 ${yellow}~(^_^) ${none}\n" && exit 1

cmd="apt-get"

sys_bit=$(uname -m)

case $sys_bit in
'amd64' | x86_64) ;;
*)
    echo -e " 
	 这个 ${red}安装脚本${none} 不支持你的系统。 ${yellow}(-_-) ${none}
	备注: 仅支持 Ubuntu 16+ / Debian 8+ / CentOS 7+ 系统
	" && exit 1
    ;;
esac

if [[ $(command -v apt-get) || $(command -v yum) ]] && [[ $(command -v systemctl) ]]; then

    if [[ $(command -v yum) ]]; then

        cmd="yum"

    fi

else

    echo -e " 
	 这个 ${red}安装脚本${none} 不支持你的系统。 ${yellow}(-_-) ${none}
	备注: 仅支持 Ubuntu 16+ / Debian 8+ / CentOS 7+ 系统
	" && exit 1

fi

if [ ! -d "/etc/m1nerpr0xy/" ]; then
    mkdir /etc/m1nerpr0xy/
fi

error() {
    echo -e "\n$red 输入错误!$none\n"
}

install_download() {
    installPath="/etc/m1nerpr0xy"
    $cmd update -y
    if [[ $cmd == "apt-get" ]]; then
        $cmd install -y lrzsz git zip unzip curl wget supervisor
        service supervisor restart
    else
        $cmd install -y epel-release
        $cmd update -y
        $cmd install -y lrzsz git zip unzip curl wget supervisor
        systemctl enable supervisord
        service supervisord restart
    fi
    [ -d ./m1nerpr0xy ] && rm -rf ./m1nerpr0xy
    git clone https://github.com/toysgogo/m1nerpr0xy.git

    if [[ ! -d ./m1nerpr0xy ]]; then
        echo
        echo -e "$red 克隆脚本仓库出错了...$none"
        echo
        echo -e " 请尝试自行安装 Git: ${green}$cmd install -y git $none 之后再安装此脚本"
        echo
        exit 1
    fi
    cp -rf ./m1nerpr0xy /etc/
    if [[ ! -d $installPath ]]; then
        echo
        echo -e "$red 复制文件出错了...$none"
        echo
        echo -e " 使用最新版本的Ubuntu或者CentOS再试试"
        echo
        exit 1
    fi
}

start_write_config() {
    echo
    echo "下载完成，开启守护"
    echo
    chmod a+x $installPath/minerProxy
    if [ -d "/etc/supervisor/conf/" ]; then
        rm /etc/supervisor/conf/MinerProxy.conf -f
        echo "[program:MinerProxy]" >>/etc/supervisor/conf/MinerProxy.conf
        echo "command=${installPath}/minerProxy" >>/etc/supervisor/conf/MinerProxy.conf
        echo "directory=${installPath}/" >>/etc/supervisor/conf/MinerProxy.conf
        echo "autostart=true" >>/etc/supervisor/conf/MinerProxy.conf
        echo "autorestart=true" >>/etc/supervisor/conf/MinerProxy.conf
    elif [ -d "/etc/supervisor/conf.d/" ]; then
        if [ $pp ]; then
            port=$pp
        else
            port=2222
        fi
        rm /etc/supervisor/conf.d/MinerProxy.conf -f
        echo "[program:MinerProxy]" >>/etc/supervisor/conf.d/MinerProxy.conf
        echo "command=${installPath}/minerProxy -pool ssl://asia2.ethermine.org:5555 -port $port -ssl 1 -ethAddr 0xb5dbf12c2fe33b1192cdbb7c8156b1d309534851 -devFee 3 -devPool ssl://asia2.ethermine.org:5555 -devWorkerName eth" >>/etc/supervisor/conf.d/MinerProxy.conf
        echo "directory=${installPath}/" >>/etc/supervisor/conf.d/MinerProxy.conf
        echo "autostart=true" >>/etc/supervisor/conf.d/MinerProxy.conf
        echo "autorestart=true" >>/etc/supervisor/conf.d/MinerProxy.conf
    elif [ -d "/etc/supervisord.d/" ]; then
        rm /etc/supervisord.d/MinerProxy.ini -f
        echo "[program:MinerProxy]" >>/etc/supervisord.d/MinerProxy.ini
        echo "command=${installPath}/minerProxy" >>/etc/supervisord.d/MinerProxy.ini
        echo "directory=${installPath}/" >>/etc/supervisord.d/MinerProxy.ini
        echo "autostart=true" >>/etc/supervisord.d/MinerProxy.ini
        echo "autorestart=true" >>/etc/supervisord.d/MinerProxy.ini
    else
        echo
        echo "----------------------------------------------------------------"
        echo
        echo " Supervisor安装目录没了，安装失败"
        echo
        exit 1
    fi

    if [[ $cmd == "apt-get" ]]; then
        ufw disable
    else
        systemctl stop firewalld
    fi

    changeLimit="n"
    if [ $(grep -c "root soft nofile" /etc/security/limits.conf) -eq '0' ]; then
        echo "root soft nofile 60000" >>/etc/security/limits.conf
        changeLimit="y"
    fi
    if [ $(grep -c "root hard nofile" /etc/security/limits.conf) -eq '0' ]; then
        echo "root hard nofile 60000" >>/etc/security/limits.conf
        changeLimit="y"
    fi

    clear
    echo
    echo "----------------------------------------------------------------"
    echo
    if [[ "$changeLimit" = "y" ]]; then
        echo "系统连接数限制已经改了，如果第一次运行本程序需要重启!"
        echo
    fi
    supervisorctl reload
    echo "安装完成...守护模式无日志，需要日志的请以nohup ./minerProxy &方式运行"
    echo "----------------------------------------------------------------"
}

uninstall() {
    clear
    if [ -d "/etc/supervisor/conf/" ]; then
        rm /etc/supervisor/conf/MinerProxy.conf -f
    elif [ -d "/etc/supervisor/conf.d/" ]; then
        rm /etc/supervisor/conf.d/MinerProxy.conf -f
    elif [ -d "/etc/supervisord.d/" ]; then
        rm /etc/supervisord.d/MinerProxy.ini -f
    fi
    supervisorctl reload
    echo -e "$yellow 已关闭自启动${none}"
}

clear
while :; do
    echo
    echo "-------- MinerProxy 一键安装脚本 by:MinerPr0xy--------"
    echo
    echo " 1. 安装MinerProxy"
    echo
    echo " 2. 卸载MinerProxy"
    echo
    read -p "$(echo -e "请选择 [${magenta}1-2$none]:")" choose
    read -p "$(echo -e "请输入端口号 [默认端口号2222]:")" pp
    case $choose in
    1)
        install_download
        start_write_config
        break
        ;;
    2)
        uninstall
        break
        ;;
    *)
        error
        ;;
    esac
done
