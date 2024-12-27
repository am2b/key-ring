#!/usr/bin/env bash

#=gpg
#@decrypt a item
#@usage:
#@decrypt_item.sh -i item_name -v vault_name

SELF_ABS_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "${SELF_ABS_DIR}"/shared.sh

usage() {
    local script
    script=$(basename "$0")
    echo "usage:"
    echo "$script -i item_name -v vault_name"
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

decrypt() {
    local item="${1}"

    local key_password="密码"
    local key_two_step="两步验证"

    local encrypted_password
    local encrypted_two_step
    encrypted_password="${ITEM_ARRAY[$key_password]}"
    encrypted_two_step="${ITEM_ARRAY[$key_two_step]}"

    ITEM_ARRAY["$key_password"]=$(do_symmetric_decrypt "${encrypted_password}")
    ITEM_ARRAY["$key_two_step"]=$(do_symmetric_decrypt "${encrypted_two_step}")

    write_item "${item}"
}

main() {
    check_parameters "${@}"
    process_opts "${@}"
    shift $((OPTIND - 1))

    local item
    local item_gpg
    item=$(get_item_path "${VAULT_NAME}" "${ITEM_NAME}")
    item_gpg="${item}".gpg

    do_asymmetric_decrypt "${item_gpg}"

    read_symmetric_encrypted_item "${item}"

    decrypt "${item}"
}

main "${@}"
