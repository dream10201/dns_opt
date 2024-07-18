#!/bin/bash
# https://www.shellcheck.net/
# https://www.codeclean.net/tools/bash/

AD_LIST=(
    "https://anti-ad.net/adguard.txt"
    "https://adguardteam.github.io/HostlistsRegistry/assets/filter_29.txt"
)
ad_tmp=$(mktemp)
white_tmp=$(mktemp)

download() {
    echo -n "download ${1}"
    local temp=`curl -sS "${1}"`
    echo ${temp} | grep "^||" >> ${ad_tmp}
    echo ${temp} | grep "^@@" >> ${white_tmp}
}

for bl in "${AD_LIST[@]}"; do
    download "$bl"
done

cat smartdns_ad.conf | sed 's/\/\([^\/]*\)\/#/||\1^/' > ${ad_tmp}
grep "^||" "${ad_tmp}" | sort | uniq >adguard_ad.txt
grep "^@@" "${white_tmp}" | sort | uniq >adguard_white.txt

rm ${ad_tmp}
rm ${white_tmp}
exit 0
