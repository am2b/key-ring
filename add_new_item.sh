#!/usr/bin/env bash

#=item
#@add a new item to a vault
#@usage:
#@add_new_item.sh -v vault_name -i item_name

SELF_ABS_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "${SELF_ABS_DIR}"/shared.sh

usage() {
    local script
    script=$(basename "$0")
    echo "usage:"
    echo "$script -v vault_name -i item_name"
    exit 1
}

check_parameters() {
    if (("$#" != 4)); then
        usage
    fi
}

process_opts() {
    while getopts ":hi:v:" opt; do
        case $opt in
        h)
            usage
            ;;
        i)
            ITEM_NAME="${OPTARG}"
            ;;
        v)
            VAULT_NAME="${OPTARG}"
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

    local vault_path
    vault_path=$(get_keyring_dir)/"${VAULT_NAME}"
    local item_path
    item_path="${vault_path}"/"${ITEM_NAME}"

    #检查是否有同名的item
    if [[ -e "${item_path}" ]]; then
        echo "An item with the same name exists"
        error_msg "$LINENO"
    fi

    #确保只有用户自己能访问
    touch "${item_path}"
    chmod 600 "${item_path}"

    #输入信息
    nvim "${item_path}"

    #加密
    bash "${SELF_ABS_DIR}"/encrypt_item.sh -v "${VAULT_NAME}" -i "${ITEM_NAME}"
}

main "${@}"
