#! /bin/sh

fetch https://raw.githubusercontent.com/itdoginfo/allow-domains/main/Russia/inside-dnsmasq-ipset.lst -o /tmp/ipset.lst
sed -e 's/vpn_domains/IPSET_VPN_FULL/g' /tmp/ipset.lst > /usr/local/etc/dnsmasq.conf.d/50_IPSET_VPN_FULL.conf

fetch https://raw.githubusercontent.com/itdoginfo/allow-domains/main/Russia/outside-dnsmasq-ipset.lst -o /tmp/ipset.lst
sed -e 's/vpn_domains/IPSET_VPN_RUONLY/g' /tmp/ipset.lst > /usr/local/etc/dnsmasq.conf.d/60_IPSET_VPN_RUONLY.conf

fetch https://raw.githubusercontent.com/recomrad/opnsense-ipsets/main/00_DNS_REBIND.conf -o /usr/local/etc/dnsmasq.conf.d/00_DNS_REBIND.conf
fetch https://raw.githubusercontent.com/recomrad/opnsense-ipsets/main/20_IPSET_VPN_ESSENTIAL.conf -o /usr/local/etc/dnsmasq.conf.d/20_IPSET_VPN_ESSENTIAL.conf
fetch https://raw.githubusercontent.com/recomrad/opnsense-ipsets/main/30_IPSET_KINO.conf -o /usr/local/etc/dnsmasq.conf.d/30_IPSET_KINO.conf
fetch https://raw.githubusercontent.com/recomrad/opnsense-ipsets/main/40_IPSET_MICROSOFT.conf -o /usr/local/etc/dnsmasq.conf.d/40_IPSET_MICROSOFT.conf
fetch https://raw.githubusercontent.com/recomrad/opnsense-ipsets/main/99_IPSET_SPEEDTEST.conf -o /usr/local/etc/dnsmasq.conf.d/99_IPSET_SPEEDTEST.conf

pluginctl dns

fetch https://raw.githubusercontent.com/recomrad/opnsense-ipsets/main/update_fullblock_ipset.sh -o /usr/bin/update_fullblock_ipset.sh
chmod +x /usr/bin/update_fullblock_ipset.sh
