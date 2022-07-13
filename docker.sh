#!/usr/bin/env bash

if [[ $EUID -ne 0 ]]
then
    clear
    echo "错误：本脚本需要 root 权限执行。" 1>&2
    exit 1
fi

a=$(curl --noproxy '*' -sSL https://api.myip.com/)
b="China"
if [[ $a == *$b* ]]
then
  echo "错误：本脚本不支持境内服务器使用。" 1>&2
  exit 1
fi

welcome () {
    echo
    echo "安装即将开始"
    echo "如果您想取消安装，"
    echo "请在 5 秒钟内按 Ctrl+C 终止此脚本。"
    echo
    sleep 5
}

docker_check () {
    echo "正在检查 Docker 安装情况 . . ."
    if command -v docker >> /mnt/mmcblk2p4/null 2>&1;
    then
        echo "Docker 似乎存在, 安装过程继续 . . ."
    else
        echo "Docker 未安装在此系统上"
        echo "请安装 Docker 并将自己添加到 Docker"
        echo "分组并重新运行此脚本。"
        exit 1
    fi
}

access_check () {
    echo "测试 Docker 环境 . . ."
    if [ -w /var/run/docker.sock ]
    then
        echo "该用户可以使用 Docker , 安装过程继续 . . ."
    else
        echo "该用户无权访问 Docker，或者 Docker 没有运行。 请添加自己到 Docker 分组并重新运行此脚本。"
        exit 1
    fi
}

build_docker () {
    printf "请输入 PagerMaid 容器的名称："
    read -r container_name <&1
    echo "正在拉取 Docker 镜像 . . ."
    docker rm -f "$container_name" > /mnt/mmcblk2p4/null 2>&1
    docker pull mrwangzhe/pagermaid_modify
}

start_docker () {
    echo "正在启动 Docker 容器 . . ."
    docker run -dit --restart=always --name="$container_name" --hostname="$container_name" mrwangzhe/pagermaid_modify <&1
    echo
    echo "开始配置参数 . . ."
    echo "在登录后，请按 Ctrl + C 使容器在后台模式下重新启动。"
    sleep 3
    docker exec -it $container_name bash utils/docker-config.sh
    echo
    echo "Docker 创建完毕。"
    echo
}

data_persistence () {
    echo "数据持久化可以在升级或重新部署容器时保留配置文件和插件。"
    printf "请确认是否进行数据持久化操作 [Y/n] ："
    read -r persistence <&1
    case $persistence in
        [yY][eE][sS] | [yY])
            printf "请输入将数据保留在宿主机哪个路径（绝对路径），同时请确保该路径下没有名为 workdir 的文件夹 ："
            read -r data_path <&1
            if [ -d $data_path ]; then
                if [[ -z $container_name ]]; then
                    printf "请输入 PagerMaid 容器的名称："
                    read -r container_name <&1
                fi
                if docker inspect $container_name &>/mnt/mmcblk2p4/null; then
                    docker cp $container_name:/pagermaid/workdir $data_path
                    docker stop $container_name &>/mnt/mmcblk2p4/null
                    docker rm $container_name &>/mnt/mmcblk2p4/null
                    docker run -dit -e PUID=$PUID -e PGID=$PGID -v $data_path/workdir:/pagermaid/workdir --restart=always --name="$container_name" --hostname="$container_name" mrwangzhe/pagermaid_modify <&1
                    echo
                    echo "数据持久化操作完成。"
                    echo 
                    shon_online
                else
                    echo "不存在名为 $container_name 的容器，退出。"
                    exit 1
                fi
            else
                echo "路径 $data_path 不存在，退出。"
                exit 1
            fi
            ;;
        [nN][oO] | [nN])
            echo "结束。"
            ;;
        *)
            echo "输入错误 . . ."
            exit 1
            ;;
    esac
}

start_installation () {
    welcome
    docker_check
    access_check
    build_docker
    start_docker
    data_persistence
}

cleanup () {
    printf "请输入 PagerMaid 容器的名称："
    read -r container_name <&1
    echo "开始删除 Docker 镜像 . . ."
    if docker inspect $container_name &>/mnt/mmcblk2p4/null; then
        docker rm -f "$container_name" &>/mnt/mmcblk2p4/null
        echo
        shon_online
    else
        echo "不存在名为 $container_name 的容器，退出。"
        exit 1
    fi
}

stop_pager () {
    printf "请输入 PagerMaid 容器的名称："
    read -r container_name <&1
    echo "正在关闭 Docker 镜像 . . ."
    if docker inspect $container_name &>/mnt/mmcblk2p4/null; then
        docker stop "$container_name" &>/mnt/mmcblk2p4/null
        echo
        shon_online
    else
        echo "不存在名为 $container_name 的容器，退出。"
        exit 1
    fi
}

start_pager () {
    printf "请输入 PagerMaid 容器的名称："
    read -r container_name <&1
    echo "正在启动 Docker 容器 . . ."
    if docker inspect $container_name &>/mnt/mmcblk2p4/null; then
        docker start $container_name &>/mnt/mmcblk2p4/null
        echo
        echo "Docker 启动完毕。"
        echo
        shon_online
    else
        echo "不存在名为 $container_name 的容器，退出。"
        exit 1
    fi
}

restart_pager () {
    printf "请输入 PagerMaid 容器的名称："
    read -r container_name <&1
    echo "正在重新启动 Docker 容器 . . ."
    if docker inspect $container_name &>/mnt/mmcblk2p4/null; then
        docker restart $container_name &>/mnt/mmcblk2p4/null
        echo
        echo "Docker 重新启动完毕。"
        echo
        shon_online
    else
        echo "不存在名为 $container_name 的容器，退出。"
        exit 1
    fi
}

reinstall_pager () {
    cleanup
    build_docker
    start_docker
    data_persistence
}

shon_online () {
    echo "一键脚本出现任何问题请转手动搭建！ xtaolabs.com"
    echo "一键脚本出现任何问题请转手动搭建！ xtaolabs.com"
    echo "一键脚本出现任何问题请转手动搭建！ xtaolabs.com"
    echo ""
    echo ""
    echo "欢迎使用 PagerMaid-Modify Docker 一键安装脚本。"
    echo
    echo "请选择您需要进行的操作:"
    echo "  1) Docker 安装 PagerMaid"
    echo "  2) Docker 卸载 PagerMaid"
    echo "  3) Docker 关闭 PagerMaid"
    echo "  4) Docker 启动 PagerMaid"
    echo "  5) Docker 重启 PagerMaid"
    echo "  6) Docker 重装 PagerMaid"
    echo "  7) 将 PagerMaid 数据持久化"
    echo "  8) 退出脚本"
    echo
    echo "     Version：0.3.1"
    echo
    echo -n "请输入编号: "
    read N
    case $N in
        1)
            start_installation
            ;;
        2)
            cleanup
            ;;
        3)
            stop_pager
            ;;
        4)
            start_pager
            ;;
        5)
            restart_pager
            ;;
        6)
            reinstall_pager
            ;;
        7)
            data_persistence
            ;;
        8)
            exit 0
            ;;
        *)
            echo "Wrong input!"
            sleep 5s
            shon_online
            ;;
    esac 
}

shon_online
