# OCP 4.8 Bare Metal UPI
## David's Walk through Chapter 7 of the Docs

The purpose of these instructions is to walk through all 3 sections of the documentation (7.1, 7.2, and 7.3)

## 7.1. PREPARING FOR BARE METAL CLUSTER INSTALLATION
>This is mainly informational

## 7.2. INSTALLING A USER-PROVISIONED CLUSTER ON BARE METAL
>This is mainly informational

## 7.2.3.4.2 Network Connectivity requirements
In this section we will host based networking via a CentOS "helper system" that will provide requisite networking services. Many many steps are needed to build the routing that are not detailed here.

Login:
```bash
ssh root@192.168.0.159
```

### The "nmcli" work
...
**Part 1 - The WAN NIC portion**

The "WAN" NIC directs traffic toward the internet

```bash
nmcli con show
```
Bash variables
wan=ens192
echo $wan
isolated=ens224
echo $isolated

_DRAFT_

```bash
dnf install git -y
mkdir /work_dir
cd /work_dir
git clone https://github.com/dkypuros/current-working-dir.git
chmod +x /work_dir/current-working-dir/bash-scripts/*
cd /work_dir/current-working-dir/bash-scripts/
./7.2.3.4.2.sh
```

How it works:
nmcli connection modify wan setting.property value

Connection Autoconnect
```bash
nmcli connection modify $wan connection.autoconnect yes

nmcli connection show $wan | grep connection.autoconnect
```

IPv4 Method:
```bash
nmcli connection modify $wan ipv4.method auto

nmcli con show $wan | grep ipv4.method
```

DNS Localhost:
```bash
nmcli connection modify $wan ipv4.dns 127.0.0.1
```

Gateway Empty:
```bash
nmcli con show $wan | grep ipv4.gateway
```

should look like this:

ipv4.gateway: --


Ignore Auto Routes
```bash
nmcli con show $wan | grep ipv4.ignore-auto-routes
```

should look like this:

ipv4.ignore-auto-routes: no


Ignore Auto DNS
```bash
nmcli connection modify $wan ipv4.ignore-auto-dns yes
nmcli con show $wan | grep ipv4.ignore-auto-dns
```

should look like this:

ipv4.ignore-auto-dns: yes

...
**Part 2 - The Isolated NIC**

Isolated NIC
```bash
nmcli connection modify $isolated connection.autoconnect yes
nmcli connection show $isolated | grep connection.autoconnect
```
Set DNS Address:
```bash
nmcli connection modify $isolated ipv4.dns 127.0.0.1
nmcli con show $isolated | grep ipv4.dns
```

Set IP Address:
```bash
nmcli connection modify $isolated ipv4.addresses 192.168.1.1/24
nmcli con show $isolated | grep ipv4.addresses
```

DNS Search
```bash
nmcli connection modify $isolated ipv4.dns-search example.com
nmcli connection show $isolated | grep dns-search
```

Gateway
```bash
nmcli connection show $isolated | grep ipv4.gateway
```

IPv4 Method:
```bash
nmcli connection modify $isolated ipv4.method manual
nmcli con show $isolated | grep ipv4.method
```

### Using firewalld as a "traffic forwarder"
```bash
nmcli connection modify $wan connection.zone external
nmcli connection modify $isolated connection.zone internal

firewall-cmd --zone=external --add-masquerade --permanent
firewall-cmd --zone=internal --add-masquerade --permanent
firewall-cmd --reload
```

_Review the config output_
firewall-cmd --get-active-zones
cat /proc/sys/net/ipv4/ip_forward
firewall-cmd --list-all --zone=internal
firewall-cmd --list-all --zone=external


## 7.2.3.5.1. Example DNS configuration for user-provisioned clusters

There are 3 DNS configuratoin files.
1. named.conf
2. /zones/db.example.com
3. /zones/db.reverse

## 7.2.3.6. Load balancing requirements for user-provisioned infrastructure


