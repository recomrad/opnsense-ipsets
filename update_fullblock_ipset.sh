#! /bin/sh

LOG_TAG="update-ipsets"

if (fetch https://git.krdnet.ru/admin/allow-domains/raw/branch/main/Russia/inside-dnsmasq-ipset.lst --no-verify-hostname -o /tmp/ipset.lst)
then 
    logger -t "$LOG_TAG" "FULL LIST SUCCESS"
    sed -e 's/vpn_domains/IPSET_VPN_FULL/g' /tmp/ipset.lst > /usr/local/etc/dnsmasq.conf.d/50_IPSET_VPN_FULL.conf
else
    logger -p daemon.err -t "$LOG_TAG" "FULL LIST ERROR"
fi

if (fetch https://git.krdnet.ru/admin/allow-domains/raw/branch/main/Services/google_ai.lst --no-verify-hostname -o /tmp/ipset.lst)
then 
    logger -t "$LOG_TAG" "GOOGLE AI LIST SUCCESS"
    while read -r domain; do
        # пропуск пустых строк и комментариев
        [ -z "$domain" ] && continue
        case "$domain" in \#*) continue ;; esac
    
        printf 'ipset=/%s/%s\n' "$domain" "IPSET_VPN_FULL" >> /usr/local/etc/dnsmasq.conf.d/50_IPSET_VPN_FULL.conf
    done < "/tmp/ipset.lst"
else
    logger -p daemon.err -t "$LOG_TAG" "GOOGLE AI LIST ERROR"
fi

if (fetch https://git.krdnet.ru/admin/allow-domains/raw/branch/main/Russia/outside-dnsmasq-ipset.lst --no-verify-hostname -o /tmp/ipset.lst)
then
    logger -t "$LOG_TAG" "VPN RU LIST SUCCESS"
    sed -e 's/vpn_domains/IPSET_VPN_RUONLY/g' /tmp/ipset.lst > /usr/local/etc/dnsmasq.conf.d/60_IPSET_VPN_RUONLY.conf
else
    logger -p daemon.err -t "$LOG_TAG" "VPN RU LIST ERROR"
fi

if (fetch https://git.krdnet.ru/admin/opnsense-ipsets/raw/branch/main/20_IPSET_VPN_ESSENTIAL.conf --no-verify-hostname -o /tmp/ipset.lst)
then
    logger -t "$LOG_TAG" "VPN ESSENTIAL LIST SUCCESS"
    cp -fv /tmp/ipset.lst /usr/local/etc/dnsmasq.conf.d/20_IPSET_VPN_ESSENTIAL.conf
else
    logger -p daemon.err -t "$LOG_TAG" "VPN ESSENTIAL LIST ERROR"
fi

if (fetch https://git.krdnet.ru/admin/opnsense-ipsets/raw/branch/main/30_IPSET_KINO.conf --no-verify-hostname -o /tmp/ipset.lst)
then
    logger -t "$LOG_TAG" "VPN RU LIST SUCCESS"
    cp -fv /tmp/ipset.lst /usr/local/etc/dnsmasq.conf.d/30_IPSET_KINO.conf
else
    logger -p daemon.err -t "$LOG_TAG" "VPN KINO LIST ERROR"
fi

if (fetch https://git.krdnet.ru/admin/opnsense-ipsets/raw/branch/main/40_IPSET_MICROSOFT.conf --no-verify-hostname -o /tmp/ipset.lst)
then
    logger -t "$LOG_TAG" "VPN MICROSOFT LIST SUCCESS"
    cp -fv /tmp/ipset.lst /usr/local/etc/dnsmasq.conf.d/40_IPSET_MICROSOFT.conf
else
    logger -p daemon.err -t "$LOG_TAG" "VPN MICROSOFT LIST ERROR"
fi

if (fetch https://git.krdnet.ru/admin/opnsense-ipsets/raw/branch/main/99_IPSET_SPEEDTEST.conf --no-verify-hostname -o /tmp/ipset.lst)
then
    logger -t "$LOG_TAG" "VPN SPEEDTEST LIST SUCCESS"
    cp -fv /tmp/ipset.lst /usr/local/etc/dnsmasq.conf.d/99_IPSET_SPEEDTEST.conf
else
    logger -p daemon.err -t "$LOG_TAG" "VPN SPEEDTEST LIST ERROR"
fi

CURRENT_DOW=$(date +%u)

if [ "$CURRENT_DOW" == "1" ];
then
    /sbin/pfctl -t IPSET_SPEEDTEST -T flush
    /sbin/pfctl -t IPSET_MICROSOFT -T flush
    /sbin/pfctl -t IPSET_KINO -T flush
    /sbin/pfctl -t IPSET_VPN_ESSENTIAL -T flush
    /sbin/pfctl -t IPSET_VPN_RUONLY -T flush
    /sbin/pfctl -t IPSET_VPN_FULL -T flush
    /sbin/pfctl -t IPSET_VPN_YOUTUBE -T flush
    /sbin/pfctl -t IPSET_VPN_TORRENT -T flush
    /sbin/pfctl -t IPSET_VPN_TELEGRAM -T flush
    /sbin/pfctl -t IPSET_STEAM -T flush
    /sbin/pfctl -t IPSET_CDN_AKAMAI -T flush
    /sbin/pfctl -t IPSET_CDN_CLOUDFRONT -T flush
    /sbin/pfctl -t IPSET_CDN_AMAZON -T flush
    /sbin/pfctl -t IPSET_CDN_EDGENEXT -T flush
    /sbin/pfctl -t IPSET_RU_ZONE -T flush
fi

pluginctl dns

if (fetch https://git.krdnet.ru/admin/opnsense-ipsets/raw/branch/main/update_fullblock_ipset.sh --no-verify-hostname -o /tmp/script.sh)
then
    logger -t "$LOG_TAG" "UPDATE SCRIPT FETCH SUCCESS"
    cp -fv /tmp/script.sh /usr/bin/update_fullblock_ipset.sh
    chmod +x /usr/bin/update_fullblock_ipset.sh
else
    logger -p daemon.err -t "$LOG_TAG" "UPDATE SCRIPT FETCH ERROR"
fi

if (fetch https://git.krdnet.ru/admin/opnsense-ipsets/raw/branch/main/wan-route-cleanup.sh --no-verify-hostname -o /tmp/script.sh)
then
    logger -t "$LOG_TAG" "CLEANUP SCRIPT FETCH SUCCESS"
    cp -fv /tmp/script.sh /usr/local/bin/wan-route-cleanup.sh
    chmod +x /usr/local/bin/wan-route-cleanup.sh
else
    logger -p daemon.err -t "$LOG_TAG" "CLEANUP SCRIPT FETCH ERROR"
fi

resolve_domain() {
    domain="$1"    
    [ -z "$domain" ] && continue    
    ips="$(dig +short @127.0.0.1 -p 5353 $domain | tr '\n' ' ')"    
    [ -n "$ips" ] && printf "%s %s\n" "$domain" "$ips"
}

resolve_ipset_domains() {
    input="$1"
    echo "Resolving $input"
    [ -r "$input" ] || return 1
    while IFS= read -r line; do
        case "$line" in
            ""|\#*) continue ;;
        esac
        rest="${line#ipset=}"
        setname="${rest##*/}"
        domains="${rest%/$setname}"

        OLDIFS="$IFS"
        IFS='/'
        for d in $domains; do            
            resolve_domain "$d"
        done        
        IFS="$OLDIFS"
    done < "$input"
}

resolve_ipset_domains /usr/local/etc/dnsmasq.conf.d/20_IPSET_VPN_ESSENTIAL.conf
resolve_ipset_domains /usr/local/etc/dnsmasq.conf.d/30_IPSET_KINO.conf
resolve_ipset_domains /usr/local/etc/dnsmasq.conf.d/40_IPSET_MICROSOFT.conf
resolve_ipset_domains /usr/local/etc/dnsmasq.conf.d/60_IPSET_VPN_RUONLY.conf
resolve_ipset_domains /usr/local/etc/dnsmasq.conf.d/99_IPSET_SPEEDTEST.conf

resolve_domain 2ip.ru
