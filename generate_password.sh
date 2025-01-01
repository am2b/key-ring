#!/usr/bin/env bash

#=password
#@generate password
#@usage:
#@generate_password.sh length

usage() {
    echo "用法: $0 <长度>"
    exit 1
}

# 检查参数
if [[ $# -ne 1 ]]; then
    usage
fi

# 密码长度
length=$1
if ! [[ $length =~ ^[0-9]+$ ]]; then
    echo "错误: 长度必须是一个正整数。"
    exit 1
fi

# 定义颜色
RED="\033[31m"       # 数字
GREEN="\033[32m"     # 字母
BLUE="\033[34m"      # 符号
RESET="\033[0m"

# 生成随机密码
generate_password() {
    local len=$1
    local symbols="!@#$%^&*()-_=+[]{};:,./?"
    local letters="abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
    local numbers="0123456789"
    local all="$symbols$letters$numbers"
    local password=""

    for ((i = 0; i < len; i++)); do
        index=$((RANDOM % ${#all}))
        password+="${all:index:1}"
    done
    echo "$password"
}

# 打印密码并加颜色
print_colored_password() {
    local password=$1
    local colored_password=""

    for ((i = 0; i < ${#password}; i++)); do
        char="${password:i:1}"
        if [[ $char =~ [0-9] ]]; then
            colored_password+="${RED}${char}${RESET}"
        elif [[ $char =~ [a-zA-Z] ]]; then
            colored_password+="${GREEN}${char}${RESET}"
        else
            colored_password+="${BLUE}${char}${RESET}"
        fi
    done

    printf "%b\n" "$colored_password"
}

# 主流程
password=$(generate_password "$length")
print_colored_password "$password"
