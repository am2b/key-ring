#!/usr/bin/env bash

#=vault
#@archive an item
#@usage:
#@archive_item.sh -v vault_name -i item_name

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

    local item
    item=$(get_item_path "${VAULT_NAME}" "${ITEM_NAME}")

    check_file_exists "${item}"

    local keyring_dir
    keyring_dir=$(get_config_value "${KEY_KEYRING_DIR}") || error_msg "$LINENO"
    local archive_vault_path="${keyring_dir}"/.archive/"${VAULT_NAME}"

    if [[ ! -d "${archive_vault_path}" ]]; then
        mkdir -p "${archive_vault_path}"
    fi

    if [[ -f "${archive_vault_path}"/"${ITEM_NAME}" ]]; then
        timestamp=$(date +"%Y-%m-%d_%H-%M-%S")
        local new_item_name="${item}"_"${timestamp}"
        mv "${item}" "${new_item_name}"
        mv "${new_item_name}" "${archive_vault_path}"
    else
        mv "${item}" "${archive_vault_path}"
    fi
}

main "${@}"
