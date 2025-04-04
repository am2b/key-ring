#!/usr/bin/env bash

#=setup
#@init keyring:create directory of keyring and create config file
#@usage:
#@keyring_init.sh

#获取该脚本(我)自己所在目录的绝对路径
SELF_ABS_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "${SELF_ABS_DIR}"/shared.sh

usage() {
    local script
    script=$(basename "$0")
    echo "usage:"
    echo "$script"
    exit 1
}

check_parameters() {
    if (("$#" != 0)); then
        usage
    fi
}

process_opts() {
    while getopts ":h" opt; do
        case $opt in
        h)
            usage
            ;;
        *)
            echo "error:unsupported option -$opt"
            usage
            ;;
        esac
    done
}

#检查是否安装了GPG
check_gpg() {
    if ! command -v gpg >/dev/null 2>&1; then
        echo "GPG is not installed"
        exit 1
    else
        local agent_file="${HOME}"/.gnupg/gpg-agent.conf
        if [[ ! -f "${agent_file}" ]]; then
            echo "allow-loopback-pinentry" >"${agent_file}"
        fi
    fi
}

create_keyring_config() {
    if [[ ! -d "${CONFIG_DIR}" ]]; then
        mkdir -p "${CONFIG_DIR}"
    fi

    if [[ ! -f "${CONFIG_FILE}" ]]; then
        echo "directory=$HOME/.key-ring" >>"${CONFIG_FILE}"
        echo "symmetric=password totp" >>"${CONFIG_FILE}"
    fi
}

create_keyring_dir() {
    local keyring_dir
    keyring_dir=$(get_keyring_dir)

    if [[ ! -d "${keyring_dir}" ]]; then
        mkdir -p "${keyring_dir}"
        chmod 700 "${keyring_dir}"
    fi
}

main() {
    check_parameters "${@}"
    process_opts "${@}"
    shift $((OPTIND - 1))

    check_gpg

    create_keyring_config

    create_keyring_dir
}

main "${@}"
