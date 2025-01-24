#!/usr/bin/env bash

#=item
#@view a item
#@usage:
#@view_item.sh -v vault_name -i item_name

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
    item_gpg_path="${item_path}".gpg

    #检查所要查看的item是否存在
    if [[ ! -e "${item_gpg_path}" ]]; then
        echo "The item:${ITEM_NAME} does not exist"
        error_msg "$LINENO"
    fi

    #将item拷贝到.workspace目录下
    local workspace_path
    workspace_path=$(get_keyring_dir)/.workspace
    mkdir -p "${workspace_path}"
    cp "${item_gpg_path}" "${workspace_path}"
    item_path="${workspace_path}"/"${ITEM_NAME}"
    item_gpg_path="${item_path}".gpg

    #解密
    bash "${SELF_ABS_DIR}"/decrypt_item.sh -v .workspace -i "${ITEM_NAME}"

    #查看
    nvim -R "${item_path}"

    #查看完毕后,删除
    rm "${item_path}"
}

main "${@}"
