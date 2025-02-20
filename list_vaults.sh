#!/usr/bin/env bash

#=vault
#@list all vaults in the keyring directory
#@usage:
#@list_vaults.sh

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

list_vaults() {
    local keyring_dir
    keyring_dir=$(get_keyring_dir)

    local vaults
    mapfile -t vaults < <(find "${keyring_dir}" -mindepth 1 -type d ! -path "${keyring_dir}/.*")

    for v in "${vaults[@]}"; do
        basename "${v}"
    done
}

main() {
    check_parameters "${@}"
    process_opts "${@}"
    shift $((OPTIND - 1))

    list_vaults
}

main "${@}"
