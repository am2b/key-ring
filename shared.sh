#!/usr/bin/env bash

#=libs
#@shared variables and functions
#@usage:
#@source shared.sh

CONFIG_DIR="${HOME}"/.config/keyring
CONFIG_FILE="${CONFIG_DIR}"/config

KEY_KEYRING_DIR="directory"

#公钥的邮件地址
RECIPIENT="${MAIL_GMAIL_MAIN}"

declare -A ITEM_ARRAY
declare -a ITEM_ARRAY_ORDER

error_msg() {
    printf "ERROR:\nSCRIPT:%s\nFUNC:%s\nLINE:%d\n" "$(basename "${0}")" "${FUNCNAME[1]}" "$1"
    exit 1
}

check_file_exists() {
    local file="${1}"
    if [[ ! -f "${file}" ]]; then
        error_msg "$LINENO"
    fi
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

#对称解密
do_symmetric_decrypt() {
    local encrypted_text="${1}"
    local plain_text
    local password
    password=$(get_gpg_symmetric_password_from_keychain)

    plain_text=$(echo "$encrypted_text" | gpg --quiet --batch --yes --passphrase "$password" --decrypt)

    if [[ $? -eq 0 ]]; then
        echo "${plain_text}"
        return 0
    else
        error_msg "$LINENO"
    fi
}

#非对称加密
do_asymmetric_encrypt() {
    local file="${1}"
    local file_gpg="${file}".gpg

    # 从macOS钥匙串获取GPG密钥的私钥密码(签名的时候,需要使用私钥对哈希值进行加密来生成数字签名)
    local password
    password=$(security find-generic-password -s "gpg" -a "${RECIPIENT}" -w)
    if [[ $? -ne 0 ]] || [[ -z "$password" ]]; then
        error_msg "$LINENO"
    fi

    # 使用私钥对文件进行签名,然后使用公钥加密文件
    #--batch:启用非交互模式
    #--pinentry-modeloopback:指示GPG不调用图形化的pinentry程序,而是直接在命令行处理密码
    #--passphrase:通过变量传递密码
    gpg --batch --pinentry-mode loopback --passphrase "${password}" --encrypt --sign --recipient "${RECIPIENT}" "${file}"

    if [[ $? -ne 0 ]]; then
        error_msg "$LINENO"
    fi

    chmod 600 "${file_gpg}"

    rm -f "${file}"
}

do_asymmetric_decrypt() {
    local file_gpg="${1}"
    local file="${file_gpg%.gpg}"

    # 从macOS钥匙串获取GPG密钥的私钥密码
    local password
    password=$(security find-generic-password -s "gpg" -a "${RECIPIENT}" -w)
    if [[ $? -ne 0 ]] || [[ -z "$password" ]]; then
        error_msg "$LINENO"
    fi

    # 使用私钥解密文件
    #如果文件有签名,gpg --decrypt会自动验证签名
    gpg --quiet --batch --pinentry-mode loopback --passphrase "${password}" --decrypt "${file_gpg}" >"${file}" 2>/dev/null

    if [[ $? -ne 0 ]]; then
        error_msg "$LINENO"
    fi

    chmod 600 "${file}"

    rm -f "${file_gpg}"
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
    local current_key=""

    #设置IFS=的作用是告诉read命令不将空格,制表符或换行符视为分隔符,这意味着读取的每一行会被完整保留,包括前导和尾随空格
    #-r:禁用反斜杠转义,如果没有-r,反斜杠(\)会被解析为转义符
    #如果文件的最后一行没有换行符,read会读取这行内容,但返回非0,导致该行可能被忽略
    #为了防止这种情况,通过||[[-n $line]]确保即使read返回非0,只要变量line非空,这行数据仍会被处理
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

    #这样就允许将"标签"写在一行用空格分开,或者写在多行,也允许用引号扩住包含空格的"标签"
    if [[ -v ITEM_ARRAY[标签] ]]; then
        declare -a tags
        #禁用IFS以免将引号扩住的字符串从中间的空格分割开来
        while IFS= read -r line; do
            # 将中文引号替换为英文双引号
            line="${line//‘/\"}"
            line="${line//’/\"}"
            line="${line//“/\"}"
            line="${line//”/\"}"
            # 将英文单引号替换为英文双引号
            line="${line//\'/\"}"

            temp_array=()

            #通过正则表达式从每一行中提取出符合条件的元素(比如引号内的内容和普通单词),并将它们添加到数组中

            #regex_double_quote='"([^"]|\\.)*"':该正则表达式用于匹配引号内的内容,包括双引号内的文本
            #":匹配一个英文双引号字符
            #([^"]|\\.)*:这是一个捕获组,用于匹配双引号内部的内容,它可以匹配:
            #[^"]:任意非双引号字符
            #\\.:匹配转义字符(如\"),\是转义字符,\\.可以匹配双引号内部的转义字符
            #":匹配另一个英文双引号,表示字符串的结束

            #regex_word='[^[:space:]]+':该正则表达式用于匹配普通的单词,即没有空格的连续字符
            #[^[:space:]]:匹配所有非空白字符
            #+:表示一个或多个非空白字符

            local regex_double_quote='"([^"]|\\.)*"'
            local regex_word='[^[:space:]]+'

            #=~:模式匹配
            while [[ $line =~ $regex_double_quote|$regex_word ]]; do
                #token="${BASH_REMATCH[0]}":取出匹配的结果,并将其赋值给token
                #每次成功匹配后,Bash会将匹配的结果存储在内置变量BASH_REMATCH中,BASH_REMATCH[0]保存的是整个匹配的文本
                local token="${BASH_REMATCH[0]}"
                temp_array+=("$token")
                #line=${line#*"${BASH_REMATCH[0]}"}:将已经匹配的部分从line字符串中删除,#*用于从字符串的开头删除匹配的部分,即删除已提取出的token
                #例如,如果line为"tag1 tag2",当第一次匹配"tag1"后,line将变为"tag2"
                line=${line#*"${BASH_REMATCH[0]}"}
                #line=${line## }:删除了line字符串开头的所有空白字符(如果有的话)
                line=${line## }
            done
            tags+=("${temp_array[@]}")
        done < <(echo -e "${ITEM_ARRAY[标签]}")
        #< <():进程替代
        #echo -e:将值中的换行符解析为真正的换行

        # 将普通数组的元素用换行符分隔并替换到关联数组中
        ITEM_ARRAY["标签"]=$(printf "%s\n" "${tags[@]}")
    fi

    # 去除每个值末尾多余的换行符
    for key in "${!ITEM_ARRAY[@]}"; do
        # 使用printf去掉末尾的换行符,同时保留中间的换行符
        ITEM_ARRAY["$key"]=$(printf "%s" "${ITEM_ARRAY[$key]}")
    done
}

read_symmetric_encrypted_item() {
    local item="${1}"
    local current_key=""
    local is_pgp_block=0

    while IFS= read -r line || [[ -n $line ]]; do
        # 检查是否是PGP块的开始
        if [[ $line == "-----BEGIN PGP MESSAGE-----" ]]; then
            is_pgp_block=1
            if [[ -n $current_key ]]; then
                ITEM_ARRAY["$current_key"]+="$line"$'\n'
            fi
            continue
        fi

        # 检查是否是PGP块的结束
        if [[ $is_pgp_block -eq 1 ]]; then
            ITEM_ARRAY["$current_key"]+="$line"$'\n'
            if [[ $line == "-----END PGP MESSAGE-----" ]]; then
                is_pgp_block=0
            fi
            continue
        fi

        # 处理空行
        if [[ -z $line ]]; then
            current_key=""
            continue
        fi

        # 处理新键
        if [[ -z $current_key ]]; then
            current_key=$line
            ITEM_ARRAY["$current_key"]=""
            ITEM_ARRAY_ORDER+=("$current_key")
        else
            # 追加到当前键的值
            ITEM_ARRAY["$current_key"]+="$line"$'\n'
        fi
    done <"$item"

    # 去除每个值末尾多余的换行符
    for key in "${!ITEM_ARRAY[@]}"; do
        ITEM_ARRAY["$key"]=$(printf "%s" "${ITEM_ARRAY[$key]}")
    done
}

write_item() {
    local item="${1}"

    : >"${item}"

    for key in "${ITEM_ARRAY_ORDER[@]}"; do
        echo "${key}" >>"${item}"
        printf "%s\n" "${ITEM_ARRAY[$key]}" >>"${item}"
        echo >>"${item}"
    done

    #删除掉文件末尾的空行
    sed -i -e :a -e '/^\n*$/{$d;N;ba' -e '}' "${item}"

    chmod 600 "${item}"
}
