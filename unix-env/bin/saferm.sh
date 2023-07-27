#!/bin/bash
# 
# saferm.sh
# like unix 系统, 安全删除文件脚本
# copy from: https://github.com/lagerspetz/linux-stuff/blob/master/scripts/saferm.sh
# 添加可执行权限: chmod +x saferm.sh

# 参数选项
recursive=""    # 递归
verbose="true"  # 详细信息
unsafe=""       # 不安全删除
clear=""        # 倾倒垃圾桶

# 参数列表
flaglist="r v u q c"

# 装载的文件系统，用于避免安全删除时的跨设备移动
filesystems=$(mount | awk '{print $3;}')

# 垃圾桶文件夹
trash="$HOME/.trash"

# 使用方法提示
usage_message() {
    echo -e "saferm.sh 用于安全删除文件，实际是mv操作. \n";
    echo -e "Usage: /path/to/saferm.sh [OPTIONS] [--] files/dirs"
    echo -e "Options:"
    echo -e "-r      递归删除."
    echo -e "-u      不安全模式, 将使用系统rm命令, 永久删除文件."
    echo -e "-v      打印详细信息."
    echo -e "-q      静音模式, 与冗长相反(-v)"
    echo -e "-c      清空垃圾桶"
	echo "";
}

# 创建垃圾桶文件夹
if [ ! -d "${trash}" ]; then
    mkdir "${trash}";
fi

# 设置选项
set_flags() {
    for k in $flaglist; do
        reduced=$(echo "$1" | sed "s/$k//")
        if [ "$reduced" != "$1" ]; then
            flags_set="$flags_set $k"
        fi
    done

    for k in $flags_set; do
        if [ "$k" == "v" ]; then
            verbose="true"
        elif [ "$k" == "r" ]; then
            recursive="true"
        elif [ "$k" == "u" ]; then
            unsafe="true"
        elif [ "$k" == "q" ]; then
            unset verbose
        elif [ "$k" == "c" ]; then
            clear="true"
        fi
    done
}

# 检查
detect() {
    if [ ! -e "$1" ]; then fs=""; return; fi
    path=$(readlink -f "$1")
    for det in $filesystems; do
        match=$(echo "$path" | grep -oE "^$det")
        if [ -n "$match" ]; then
            if [ ${#det} -gt ${#fs} ]; then
                fs="$det"
            fi
        fi
    done
}

# 检查文件/文件夹
complain() {
    msg=""
    if [[ ! -e "$1" && ! -L "$1" ]]; then
        msg="File does not exist:"
    elif [[ ! -w "$1" && ! -L "$1" ]]; then
        msg="File is not writable:"
    elif [ -f "$1" ]; then
        act="true" # operate on files by default
    elif [[ -d "$1" && -n "$recursive" ]]; then
        act="true"
    elif [[ -d "$1" && -z "$recursive" ]]; then
		msg="Is a directory (and -r not specified):"
    else
		msg="No such file or directory:"
    fi
}

# 对比挂载文件系统
ask_fs() {
    detect "$1"
    if [ "${fs}" != "${tfs}" ]; then
        unset answer;
        while true; do
            echo -e "$1 is on ${fs}. Unsafe delete (y/n)?"
            read -n 1 answer
            case $answer in
 	            [Yy]*)
	                unsafe="yes"
	                break
	                ;;
	            [Nn]*)
	                return
	                ;;
	            *)
	                echo "Please answer y or n."
	                ;;
            esac
        done
  fi
}

# 执行删除
perform_delete() {
    # "delete" = move to trash
    if [ -n "$unsafe" ]; then
        if [ -n "$verbose" ]; then echo -e "Deleting(rm -rf) $1"; fi
        # permanently remove files.
        rm -rf -- "$1"
    else
        if [ -n "$verbose" ];then echo -e "Moving $k to ${trash}"; fi
        # moves and backs up old files
        mv -- "$1" "${trash}"
    fi
}

ask_nobackup() {
    unset answer
    while true; do
        echo -e "$k could not be moved to trash. Unsafe delete (y/n)?"
        read -n 1 answer
        case $answer in
            [Yy]*)
                unsafe="yes"
                perform_delete "${k}"
                ret=$?
                break
                ;;
            [Nn]*)
                break
                ;;
            *)
                 echo "Please answer y or n."
                ;;
        esac
    done
    # Reset temporary unsafe flag
    unset unsafe
}

# 删除文件
delete_files() {
    for k in "$@"; do
        desc="$k";
        complain "${k}"
        if [ -n "$msg" ]; then
            echo -e "$msg $desc"
        else
            # actual action
            if [ -z "$unsafe" ]; then
                ask_fs "${k}"
            fi
            perform_delete "${k}"
            ret=$?
            # Reset temporary unsafe flag
            if [ "$answer" == "y" ]; then unset unsafe; unset answer; fi
            # echo "MV exit status: $ret"
            if [ ! "$ret" -eq 0 ]; then
                ask_nobackup "${k}"
            fi
        fi
    done
}

# 清空垃圾桶
clear_trash() {
    while true; do
        echo -e "Do you want to clean the trash can(y/n)?"
        read -n 1 answer
        case $answer in
            [Yy]*)
                unsafe="yes"
                perform_delete "$1"
                ret=$?
                break
                ;;
            [Nn]*)
                break
                ;;
            *)
                 echo "Please answer y or n."
                ;;
        esac
    done
}

# 解析参数
after_opts=""
for k in "$@"; do
    if [[ "${k:0:1}" == "-" && -z "$after_opts" ]]; then
        if [ "${k:1:2}" == "-" ]; then
            after_opts="true"
        else # option(s)
            set_flags "$k" # set flags
        fi
    else
        files[++i]="$k"
    fi
done

# 清理垃圾桶
if [ -n "$clear" ]; then
    clear_trash "${trash}"
    exit 0;
fi

# 无参数, 提示使用信息
if [ -z "${files[1]}" ]; then
	usage_message
	exit 0;
fi

detect "${trash}"
tfs="$fs"

# 删除
delete_files "${files[@]}"