#!/bin/bash
# https://www.shellcheck.net/
# https://www.codeclean.net/tools/bash/

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
ad_hosts_tmp=$(mktemp)
echo_err(){
    echo  -ne " \033[31m\xE2\x9D\x8C\033[0m"
}
echo_success(){
    echo -ne " \033[32m\xE2\x9C\x85\033[0m"
}

download() {
    echo -n "download ${1}"
    if ! curl -sS "${1}" | grep "^address" >> "${2}"; then
        echo_err
    fi
    echo_success
    echo ""
}

other_list(){
    local v2ray_rules_dat_ad=(
        "https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/reject-list.txt"
    )
    local bl=""
    for bl in "${v2ray_rules_dat_ad[@]}"; do
        echo -n "download ${bl}"
        #if ! curl -sS "${bl}" | sed 's/^/address \//;s/$/\/#/' >> "${ad_hosts_tmp}"; then
        if ! fgrep -q "${bl}" "${ad_tmp}" && ! curl -sS "${bl}" | sed 's/^/0.0.0.0 /;s/$//' >> "${ad_hosts_tmp}"; then
            echo_err
        fi
        echo_success
        echo ""
    done
}
for bl in "${AD_LIST[@]}"; do
    download "$bl" "$ad_tmp"
done
for wl in "${WHITE_LIST[@]}"; do
    download "$wl" "$white_tmp"
done

other_list

grep "^address" "$ad_tmp" | sort | uniq >ad.conf
grep "^address" "$white_tmp" | sort | uniq >white.conf
cat ${ad_hosts_tmp} | sort | uniq > ad.hosts

rm ${ad_tmp}
rm ${white_tmp}
rm ${ad_hosts_tmp}
exit 0
