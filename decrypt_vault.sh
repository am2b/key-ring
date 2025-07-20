#!/usr/bin/env bash

#=gpg
#@decrypt a vault(contains archived items)
#@usage:
#@decrypt_vault.sh vault_name decrypted_dir

SELF_ABS_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "${SELF_ABS_DIR}"/shared.sh

usage() {
    local script
    script=$(basename "$0")
    echo "usage:" >&2
    echo "$script vault_name decrypted_dir" >&2
    exit "${1:-1}"
}

check_parameters() {
    if (("$#" != 2)); then
        usage
    fi
}

process_opts() {
    while getopts ":h" opt; do
        case $opt in
        h)
            usage 0
            ;;
        *)
            echo "error:unsupported option -$opt" >&2
            usage
            ;;
        esac
    done
}

decrypt_asymmetric() {
    local password="${1}"
    local gpg_file="${2}"
    local file="${3}"

    #使用私钥解密文件
    gpg --quiet --batch --pinentry-mode loopback --passphrase "${password}" --decrypt "${gpg_file}" >"${file}" 2>/dev/null
    if [[ $? -ne 0 ]]; then
        echo "error:decrypt ${gpg_file}"
    fi
    chmod 600 "${file}"
}

decrypt_symmetric() {
    local item="${1}"

    local keys=()
    keys=($(get_config_value "symmetric"))

    for key in "${keys[@]}"; do
        if [[ -v ITEM_ARRAY["${key}"] ]]; then
            local encrypted="${ITEM_ARRAY[$key]}"
            ITEM_ARRAY["$key"]=$(do_symmetric_decrypt "${encrypted}")
        fi
    done

    write_item "${item}"
}

main() {
    check_parameters "${@}"
    OPTIND=1
    process_opts "${@}"
    shift $((OPTIND - 1))

    local keyring_dir
    local vault_name
    local vault_dir
    local archived_vault_dir
    local decrypted_dir
    local decrypted_archived_dir

    keyring_dir=$(get_keyring_dir)
    vault_name="${1}"
    vault_dir=$(get_vault_path "${vault_name}")
    archived_vault_dir="${keyring_dir}"/.archive/"${vault_name}"
    decrypted_dir=$(realpath "${2}")
    decrypted_archived_dir="${decrypted_dir}"/archive

    if [[ ! -d "${decrypted_archived_dir}" ]]; then
        mkdir -p "${decrypted_archived_dir}"
    fi

    #从macOS钥匙串获取GPG密钥的私钥密码
    local password
    password=$(security find-generic-password -s "gpg" -a "${RECIPIENT}" -w)
    if [[ $? -ne 0 ]] || [[ -z "$password" ]]; then
        echo "error:read password form keychain"
    fi

    local file

    while IFS= read -r -d '' gpg_file; do
        file=$(basename "${gpg_file}")
        file=${file%.gpg}
        file="${decrypted_dir}"/"${file}"
        decrypt_asymmetric "${password}" "${gpg_file}" "${file}"
        read_symmetric_encrypted_item "${file}"
        decrypt_symmetric "${file}"
        ITEM_ARRAY=()
        ITEM_ARRAY_ORDER=()
        echo "${file}"
    done < <(find "${vault_dir}" -path './.git' -prune -o \( -type f ! -name '.DS_Store' -print0 \))

    while IFS= read -r -d '' gpg_file; do
        file=$(basename "${gpg_file}")
        file=${file%.gpg}
        file="${decrypted_archived_dir}"/"${file}"
        decrypt_asymmetric "${password}" "${gpg_file}" "${file}"
        read_symmetric_encrypted_item "${file}"
        decrypt_symmetric "${file}"
        ITEM_ARRAY=()
        ITEM_ARRAY_ORDER=()
        echo "${file}"
    done < <(find "${archived_vault_dir}" -path './.git' -prune -o \( -type f ! -name '.DS_Store' -print0 \))
}

main "${@}"
