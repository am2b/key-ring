#!/usr/bin/env bash

#=libs
#@shared variables and functions
#@usage:
#@source shared.sh

CONFIG_DIR="${HOME}"/.config/keyring
CONFIG_FILE="${CONFIG_DIR}"/config

KEY_KEYRING_DIR="directory"

declare -A ITEM_ARRAY
declare -a ITEM_ARRAY_ORDER

error_msg() {
    printf "ERROR:\nSCRIPT:%s\nFUNC:%s\nLINE:%d\n" "$(basename "${0}")" "${FUNCNAME[1]}" "$1"
    exit 1
}

get_gpg_symmetric_password_from_keychain() {
    local password
    password=$(security find-generic-password -s "gpg-symmetric" -a "${MAIL_GMAIL_MAIN}" -w) || error_msg "$LINENO"

    echo "${password}"
    return 0
}

#对称加密
do_symmetric_encrypt() {
    local plain_text="${1}"
    local encrypted_text
    local password
    password=$(get_gpg_symmetric_password_from_keychain)

    encrypted_text=$(echo -n "$plain_text" | gpg --batch --yes --passphrase "$password" --symmetric --armor)

    if [[ $? -eq 0 ]]; then
        echo "${encrypted_text}"
        return 0
    else
        error_msg "$LINENO"
    fi
}

#非对称加密
do_asymmetric_encrypt() {
    :
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
    keyring_dir=$(get_config_value "${KEY_KEYRING_DIR}") || error_msg "$LINENO"

    echo "${keyring_dir}"
    return 0
}

get_vault_path() {
    local vault_name="${1}"
    local vault_path
    vault_path=$(get_keyring_dir)/"${vault_name}" || error_msg "$LINENO"

    echo "${vault_path}"
    return 0
}

get_item_path() {
    local vault_name="${1}"
    local item_name="${2}"
    local item_path
    item_path=$(get_vault_path "${vault_name}")/"${item_name}" || error_msg "$LINENO"

    echo "${item_path}"
    return 0
}

read_item() {
    local item="${1}"

    current_key=""

    while IFS= read -r line || [[ -n $line ]]; do
        # 如果是空行,则清除当前键
        if [[ -z $line ]]; then
            current_key=""
        elif [[ $current_key == "" ]]; then
            # 如果没有当前键,将这一行作为键
            current_key=$line
            ITEM_ARRAY["$current_key"]=""
            ITEM_ARRAY_ORDER+=("$current_key")
        else
            # 否则将这一行追加到当前键的值中
            ITEM_ARRAY["$current_key"]+="${line}"$'\n'
        fi
    done <"${item}"

    # 去除每个值末尾多余的换行符
    for key in "${!ITEM_ARRAY[@]}"; do
        ITEM_ARRAY["$key"]=$(echo -e "${ITEM_ARRAY[$key]}" | sed '/^[[:space:]]*$/d')
    done
}

write_item() {
    local item="${1}"

    : >"${item}"

    for key in "${ITEM_ARRAY_ORDER[@]}"; do
        echo "${key}" >>"${item}"
        echo -e "${ITEM_ARRAY[$key]}" >>"${item}"
        # 添加空行分隔
        echo >>"${item}"
    done

    #删除掉文件末尾的空行
    sed -i -e :a -e '/^\n*$/{$d;N;ba' -e '}' "${item}"
}
