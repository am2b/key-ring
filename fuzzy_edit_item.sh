#!/usr/bin/env bash

#=item
#@edit a item
#@usage:
#@fuzzy_edit_item.sh

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

main() {
    check_parameters "${@}"
    process_opts "${@}"
    shift $((OPTIND - 1))

    key_ring_dir=$(get_keyring_dir)

    #定义需要忽略的目录
    ignore_dirs=(.git .workspace)

    #构造find的排除条件
    exclude_dirs=$(for dir in "${ignore_dirs[@]}"; do echo "-path '${key_ring_dir}/${dir}' -prune -o"; done | tr '\n' ' ')

    #动态执行find命令
    selected_item=$(eval "find \"${key_ring_dir}\" \( $exclude_dirs -type f -print \) | sed \"s|^$key_ring_dir/||\" | fzf")

    #检查用户是否选择了文件
    if [[ -n "$selected_item" ]]; then
        VAULT_NAME=$(dirname "${selected_item}")
        ITEM_NAME=$(basename "${selected_item%%.*}")

        #edit
        bash "${SELF_ABS_DIR}"/edit_item.sh -v "${VAULT_NAME}" -i "${ITEM_NAME}"
    else
        exit 0
    fi
}

main "${@}"
