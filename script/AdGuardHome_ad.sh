#!/bin/bash
# https://www.shellcheck.net/
# https://www.codeclean.net/tools/bash/

AD_LIST=(
    "https://anti-ad.net/adguard.txt"
    "https://adguardteam.github.io/HostlistsRegistry/assets/filter_29.txt"
    "https://raw.githubusercontent.com/badmojr/1Hosts/master/Lite/adblock.txt"
    "https://raw.githubusercontent.com/AdguardTeam/AdguardFilters/master/BaseFilter/sections/adservers.txt"
    "https://raw.githubusercontent.com/AdguardTeam/AdguardFilters/master/MobileFilter/sections/adservers.txt"
    "https://raw.githubusercontent.com/AdguardTeam/AdguardFilters/master/ChineseFilter/sections/adservers.txt"
    "https://raw.githubusercontent.com/AdguardTeam/AdguardFilters/master/ChineseFilter/sections/adservers_firstparty.txt"
    "https://raw.githubusercontent.com/easylist/easylist/master/easylist/easylist_thirdparty.txt"
    "https://raw.githubusercontent.com/easylist/easylist/master/easylist_adult/adult_adservers.txt"
    "https://raw.githubusercontent.com/easylist/easylistchina/master/easylistchina.txt"
    "https://raw.githubusercontent.com/AdguardTeam/AdguardFilters/master/BaseFilter/sections/cryptominers.txt"
    "https://raw.githubusercontent.com/AdguardTeam/AdGuardSDNSFilter/master/Filters/rules.txt"
    "https://raw.githubusercontent.com/easylist/easylist/master/easylist_adult/adult_adservers_popup.txt"
    "https://raw.githubusercontent.com/AdguardTeam/AdguardFilters/master/SpywareFilter/sections/mobile.txt"
    "https://raw.githubusercontent.com/easylist/easylist/master/easyprivacy/easyprivacy_trackingservers.txt"
)
ad_tmp=$(mktemp)
echo_err(){
    echo  -ne " \033[31m\xE2\x9D\x8C\033[0m"
}
echo_success(){
    echo -ne " \033[32m\xE2\x9C\x85\033[0m"
}
download() {
    echo -n "download ${1}"
    if ! curl -sS "${1}" | grep -E '^(\|\||@@)' >> "${2}"; then
        echo_err
    fi
    echo_success
    echo ""
}

for bl in "${AD_LIST[@]}"; do
    download "$bl" "$ad_tmp"
done
``
cat smartdns_ad.conf | sed 's/\/\([^\/]*\)\/#/||\1^/' >> ${ad_tmp}
grep -E '^(\|\||@@)' "${ad_tmp}" | sort | uniq >adguard_ad.txt

rm ${ad_tmp}
exit 0
