#!/bin/bash
# https://www.shellcheck.net/
# https://www.codeclean.net/tools/bash/
CONF_PATH="/etc/smartdns"
CONF_NAME="smartdns.conf"
PROXY="http://127.0.0.1:10809"
BLOCK_DNS=("dns.pub" "doh.360.cn" "dns.alidns.com" "doh.pub")
AD_LIST=(
    "https://raw.githubusercontent.com/privacy-protection-tools/anti-AD/master/anti-ad-smartdns.conf"
    "https://raw.githubusercontent.com/Cats-Team/AdRules/main/smart-dns.conf"
    "https://raw.githubusercontent.com/neodevpro/neodevhost/master/smartdns.conf"
)
WHITE_LIST=(
    "https://raw.githubusercontent.com/privacy-protection-tools/dead-horse/master/anti-ad-white-for-smartdns.txt"
)

ad_tmp=$(mktemp)
white_tmp=$(mktemp)
conf_tmp=$(mktemp)

download() {
    echo -n "download ${1}"
    if ! curl -sSx ${PROXY} "${1}" >> "${2}"; then
        echo  -ne " \033[31m\xE2\x9D\x8E\033[0m"
    fi
    echo -ne " \033[32m\xE2\x9C\x85\033[0m"
    echo ""
}
for bl in "${AD_LIST[@]}"; do
    download "$bl" "$ad_tmp"
done
for wl in "${WHITE_LIST[@]}"; do
    download "$wl" "$white_tmp"
done

CHECK_LINK=("https://www.google.com/ncr" "https://x.com" "https://www.facebook.com" "https://www.youtube.com" "https://www.baidu.com")
checkDoh() {
    local i=0
    for link in "${CHECK_LINK[@]}"; do
        curl -sS --connect-timeout 1 -m 2 -v --doh-url "$1" "${link}" 2>&1 -o /dev/null | grep -q "was resolved." || return 1
    done
    return 0
}

cp "${CONF_PATH}/${CONF_NAME}" "$conf_tmp"
sed -i '/^server-https/d' "$conf_tmp"
urls=$(curl -sSx ${PROXY} "https://raw.githubusercontent.com/dream10201/DNS-over-HTTPS/master/doh.list")
declare -A ping_times
declare -A url_map

compare_float() {
    awk -v n1="$1" -v n2="$2" 'BEGIN {if (n1 < n2) exit 0; exit 1}'
}
for url in ${urls}; do
    domain=$(echo "$url" | awk -F/ '{print $3}')
    #domain=$(echo "${url}" | sed -E 's#^.*://([^/]+).*#\1#' | sed -E 's#^.*\.([^\.]+\.[^\.]+)$#\1#')
    if [[ " ${BLOCK_DNS[*]} " == *" $domain "* ]]; then
        continue
    fi

    avg_time=$(ping -A -c 9 -W 1 "$domain" 2>/dev/null | awk -F'/' '/^rtt/ {print $5}' 2>/dev/null)
    echo -n "${url}"

    if [ -z "$avg_time" ]; then
        echo -ne " \033[31m\xE2\x9D\x8E\033[0m"
        echo ""
        continue
    fi
    if ! checkDoh "$url"; then
        echo -ne " \033[31m\xE2\x9D\x8E\033[0m"
        echo ""
        continue
    fi
    
    if [ -z "${ping_times[$domain]}" ] || compare_float "$avg_time" "${ping_times[$domain]}"; then
        ping_times["$domain"]=$avg_time
        url_map["$domain"]=$url
        echo -ne " ${avg_time}ms \033[32m\xE2\x9C\x85\033[0m"
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

grep "^address" "$ad_tmp" | sort | uniq >${CONF_PATH}/ad.conf
grep "^address" "$white_tmp" | sort | uniq >${CONF_PATH}/white.conf。
cat "$conf_tmp" >${CONF_PATH}/${CONF_NAME}
systemctl restart smartdns.service

rm "$conf_tmp"
rm "$ad_tmp"
rm "$white_tmp"
exit 0
