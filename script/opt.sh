#!/bin/bash
# https://www.shellcheck.net/
# https://www.codeclean.net/tools/bash/
CONF_PATH="/etc/smartdns"
CONF_NAME="smartdns.conf"
AD_ENABLE=$1
PROXY="http://127.0.0.1:10809"
BLOCK_DNS=("dns.pub" "doh.360.cn" "dns.alidns.com" "doh.pub")
conf_tmp=$(mktemp)
cp "${CONF_PATH}/${CONF_NAME}" "$conf_tmp"
sed -i '/^server-https/d' "$conf_tmp"



echo_err(){
    echo  -ne " \033[31m\xE2\x9D\x8C\033[0m"
}
echo_success(){
    echo -ne " \033[32m\xE2\x9C\x85\033[0m"
}
download() {
    echo -n "download ${1}"
    if ! curl -sSx ${PROXY} "${1}" > "${2}"; then
        echo_err
    fi
    echo_success
    echo ""
}
if [ -n "$AD_ENABLE" ]; then
    download "https://raw.githubusercontent.com/dream10201/smartdns_opt/master/ad.conf" "${CONF_PATH}/ad.conf"
    download "https://raw.githubusercontent.com/dream10201/smartdns_opt/master/white.conf" "${CONF_PATH}/white.conf"
    download "https://raw.githubusercontent.com/dream10201/smartdns_opt/master/ad.hosts" "${CONF_PATH}/ad.hosts"
fi

CHECK_LINK=("https://im.qq.com" "https://www.baidu.com")
checkDoh() {
    for link in "${CHECK_LINK[@]}"; do
        if ! curl -sIS -m 9 --doh-url "$1" "${link}" &>/dev/null;then
            return 1
        fi
    done
    return 0
}
checkDohThread() {
    local pids=()
    local fail=0
    for link in "${CHECK_LINK[@]}"; do
        #(curl -sIS --connect-timeout 9 -m 9 --doh-url "$1" "${link}" >/dev/null 2>&1) &
        (curl -sIS -m 9 --doh-url "$1" "${link}" &>/dev/null) &
        pids+=($!)
    done
    while [ ${#pids[@]} -gt 0 ]; do
        if ! wait -n; then
            fail=1
            break
        fi
        for i in "${!pids[@]}"; do
            if ! kill -0 "${pids[i]}" 2>/dev/null; then
                unset 'pids[i]'
            fi
        done
    done
    if [ "$fail" -eq 0 ]; then
        return 0
    else
        kill "${pids[@]}" &>/dev/null
        return 1
    fi
}
getList(){
    local urls=$(curl -sSx ${PROXY} "https://raw.githubusercontent.com/dream10201/DNS-over-HTTPS/master/doh.list")
    if [ $? -ne 0 ]; then
        exit 0
    fi
    echo ${urls}
}


urls=$(getList)
declare -A ping_times
declare -A url_map

compare_float() {
    awk -v n1="$1" -v n2="$2" 'BEGIN {if (n1 < n2) exit 0; exit 1}'
}
counter=0
for url in ${urls}; do
    domain=$(echo "$url" | awk -F/ '{print $3}')
    #domain=$(echo "${url}" | sed -E 's#^.*://([^/]+).*#\1#' | sed -E 's#^.*\.([^\.]+\.[^\.]+)$#\1#')
    if [[ " ${BLOCK_DNS[*]} " == *" $domain "* ]]; then
        continue
    fi
    avg_time=$(curl --max-time 10 --doh-url ""$url"" --output /dev/null --silent --write-out "%{time_namelookup}" www.baidu.com)
    #avg_time=$(ping -A -c 9 -W 1 "$domain" 2>/dev/null | awk -F'/' '/^rtt/ {print $5}' 2>/dev/null)
    ((counter++))
    echo -n "[${counter}] ${url}"
    if awk "BEGIN {exit ($avg_time == 0) ? 0 : 1}"; then
    #if [ -z "$avg_time" ]; then
        echo_err
        echo ""
        continue
    fi
    # if ! checkDoh "$url"; then
    #     echo -ne " [c]"
    #     echo_err
    #     echo ""
    #     continue
    # fi

    if [ -z "${ping_times[$domain]}" ] || compare_float "$avg_time" "${ping_times[$domain]}"; then
        ping_times["$domain"]=$avg_time
        url_map["$domain"]=$url
        echo_success
        echo -ne " ${avg_time}ms"
    fi
    echo ""
done

sorted_urls=$(for domain in "${!ping_times[@]}"; do
    echo "${ping_times[$domain]} ${url_map[$domain]}"
done | sort -n | awk '{print $2}' | head -n 9)
for fast in ${sorted_urls}; do
    echo "server-https $fast" >>"$conf_tmp"
done

echo ""
echo "$sorted_urls"
#echo "server-https https://doh.bidd.net/1:-P8AuAAIBAB_A__p2_8iQazggBBUMyAAQGoAWA==" >> "${conf_tmp}"
cat "$conf_tmp" >${CONF_PATH}/${CONF_NAME}
systemctl restart smartdns.service

rm "$conf_tmp"
exit 0
