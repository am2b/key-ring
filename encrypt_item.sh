#!/usr/bin/env bash

#=gpg
#@encrypt a item
#@usage:
#@encrypt_item.sh -v vault_name -i item_name

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

encrypt() {
    local item="${1}"

    local keys=()
    keys=($(get_config_value "symmetric"))

    for key in "${keys[@]}"; do
        if [[ -v ITEM_ARRAY["${key}"] ]]; then
            local plain="${ITEM_ARRAY[$key]}"
            ITEM_ARRAY["$key"]=$(do_symmetric_encrypt "${plain}")
        fi
    done

    write_item "${item}"

    do_asymmetric_encrypt "${item}"
}

main() {
    check_parameters "${@}"
    process_opts "${@}"
    shift $((OPTIND - 1))

    local item
    item=$(get_item_path "${VAULT_NAME}" "${ITEM_NAME}")

    check_file_exists "${item}"

    read_item "${item}"

    encrypt "${item}"
}

main "${@}"
