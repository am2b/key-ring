#!/usr/bin/env bash

#=vault
#@create a new vault in keyring directory
#@usage:
#@create_new_vault.sh new_vault_name

SELF_ABS_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "${SELF_ABS_DIR}"/shared.sh

usage() {
    local script
    script=$(basename "$0")
    echo "usage:"
    echo "$script new_vault_name"
    exit 1
}

check_parameters() {
    if (("$#" != 1)); then
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

create_new_vault() {
    local keyring_dir
    keyring_dir=$(get_config_value "${KEY_KEYRING_DIR}") || error_msg "$LINENO"
    local new_vault_name="${1}"
    local new_vault_path="${keyring_dir}"/"${new_vault_name}"

    if [[ ! -d "${new_vault_path}" ]]; then
        mkdir -p "${new_vault_path}"
    else
        error_msg "$LINENO"
    fi
}

main() {
    check_parameters "${@}"
    process_opts "${@}"
    shift $((OPTIND - 1))

    local new_vault_name
    new_vault_name="${1}"
    create_new_vault "${new_vault_name}"
}

main "${@}"
