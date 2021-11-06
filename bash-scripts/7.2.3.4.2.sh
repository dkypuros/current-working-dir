#!/bin/bash

#change the interface names first (WAN/isolated)

#WAN
echo "WAN Output"
nmcli connection modify wan connection.autoconnect yes
nmcli connection show wan | grep connection.autoconnect
nmcli connection modify wan ipv4.method auto
nmcli con show wan | grep ipv4.method
nmcli connection modify wan ipv4.dns 127.0.0.1
nmcli con show wan | grep ipv4.gateway
nmcli con show wan | grep ipv4.ignore-auto-routes
nmcli connection modify wan ipv4.ignore-auto-dns yes
nmcli con show wan | grep ipv4.ignore-auto-dns
#isolated
echo "Isolated Output"
nmcli connection modify isolated connection.autoconnect yes
nmcli connection modify isolated ipv4.addresses 192.168.1.1/24
nmcli connection show isolated | grep ipv4.addresses
nmcli connection show isolated | grep connection.autoconnect
nmcli connection modify isolated ipv4.dns 127.0.0.1
nmcli con show isolated | grep ipv4.dns
nmcli connection modify isolated ipv4.dns-search example.com
nmcli connection show isolated | grep dns-search
nmcli connection show isolated | grep ipv4.gateway
nmcli connection modify isolated ipv4.method manual
nmcli con show isolated | grep ipv4.method
echo ""
echo ""
echo ""
echo " The output above should match the output below"
echo "================================================="
echo ""
echo ""
echo ""
cat /work_dir/current-working-dir/bash-scripts/7.2.3.4.2.compare