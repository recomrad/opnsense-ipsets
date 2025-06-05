#! /bin/sh

if (fetch https://raw.githubusercontent.com/itdoginfo/allow-domains/main/Russia/inside-dnsmasq-ipset.lst --no-verify-hostname -o /tmp/ipset.lst)
then 
    echo success-vpn-full
    sed -e 's/vpn_domains/IPSET_VPN_FULL/g' /tmp/ipset.lst > /usr/local/etc/dnsmasq.conf.d/50_IPSET_VPN_FULL.conf
fi

if (fetch https://raw.githubusercontent.com/itdoginfo/allow-domains/main/Russia/outside-dnsmasq-ipset.lst --no-verify-hostname -o /tmp/ipset.lst)
then
    echo success-vpn-ru
    sed -e 's/vpn_domains/IPSET_VPN_RUONLY/g' /tmp/ipset.lst > /usr/local/etc/dnsmasq.conf.d/60_IPSET_VPN_RUONLY.conf
fi

if (fetch https://raw.githubusercontent.com/recomrad/opnsense-ipsets/main/20_IPSET_VPN_ESSENTIAL.conf --no-verify-hostname -o /tmp/ipset.lst)
then
    echo success-vpn-essential
    cp /tmp/ipset.lst /usr/local/etc/dnsmasq.conf.d/20_IPSET_VPN_ESSENTIAL.conf
fi

if (fetch https://raw.githubusercontent.com/recomrad/opnsense-ipsets/main/30_IPSET_KINO.conf --no-verify-hostname -o /tmp/ipset.lst)
then
    echo success-vpn-kino
    cp /tmp/ipset.lst /usr/local/etc/dnsmasq.conf.d/30_IPSET_KINO.conf
fi

if (fetch https://raw.githubusercontent.com/recomrad/opnsense-ipsets/main/40_IPSET_MICROSOFT.conf --no-verify-hostname -o /tmp/ipset.lst)
then
    echo success-vpn-microsoft
    cp /tmp/ipset.lst /usr/local/etc/dnsmasq.conf.d/40_IPSET_MICROSOFT.conf
fi

if (fetch https://raw.githubusercontent.com/recomrad/opnsense-ipsets/main/99_IPSET_SPEEDTEST.conf --no-verify-hostname -o /tmp/ipset.lst)
then
    echo success-vpn-speedtest
    cp /tmp/ipset.lst /usr/local/etc/dnsmasq.conf.d/99_IPSET_SPEEDTEST.conf
fi

pluginctl dns

if (https://raw.githubusercontent.com/recomrad/opnsense-ipsets/main/update_fullblock_ipset.sh --no-verify-hostname -o /tmp/script.sh)
then
    echo success-udpate-script
    cp /tmp/script.sh /usr/bin/update_fullblock_ipset.sh
    chmod +x /usr/bin/update_fullblock_ipset.sh
fi
