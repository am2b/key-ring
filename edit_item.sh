#!/usr/bin/env bash

#=item
#@edit a item
#@usage:
#@edit_item.sh -v vault_name -i item_name

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
    local item_gpg_path
    item_gpg_path="${item_path}.gpg"

    #检查item是否存在
    check_file_exists "${item_gpg_path}"

    #将item移动到.workspace目录下
    local workspace_path
    workspace_path=$(get_keyring_dir)/.workspace
    mkdir -p "${workspace_path}"
    mv "${item_gpg_path}" "${workspace_path}"
    item_path="${workspace_path}"/"${ITEM_NAME}"
    item_gpg_path="${item_path}".gpg

    #解密
    bash "${SELF_ABS_DIR}"/decrypt_item.sh -v .workspace -i "${ITEM_NAME}"

    #编辑
    nvim "${item_path}"

    #加密
    bash "${SELF_ABS_DIR}"/encrypt_item.sh -v .workspace -i "${ITEM_NAME}"

    #将item从.workspace移动到vault
    mv "${item_gpg_path}" "${vault_path}"
}

main "${@}"
