#!/usr/bin/env bash

#=libs
#@shared variables and functions
#@usage:
#@source shared.sh

CONFIG_DIR="${HOME}"/.config/keyring
CONFIG_FILE="${CONFIG_DIR}"/config

KEY_KEYRING_DIR="directory"

error_msg() {
    printf "ERROR:\nSCRIPT:%s\nFUNC:%s\nLINE:%d\n" "$(basename "${0}")" "${FUNCNAME[1]}" "$1"
    exit 1
}

get_config_value() {
    if (("$#" == 1)); then
        local key="${1}"
        local value
        value=$(awk -F= -v k="$key" '{gsub(/^[[:space:]]+|[[:space:]]+$/, "", $1); gsub(/^[[:space:]]+|[[:space:]]+$/, "", $2); if ($1 == k) print $2}' "${CONFIG_FILE}")

        echo "${value}"
        return 0
    else
        error_msg "$LINENO"
    fi
}

get_keyring_dir() {
    local keyring_dir
    keyring_dir=$(get_config_value "${KEY_KEYRING_DIR}")
    echo "${keyring_dir}"
    return 0
}
