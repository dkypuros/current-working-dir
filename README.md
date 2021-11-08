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
**Bash variables**
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
nmcli connection show $wan | grep ipv4.dns
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
Should see:
```bash
ipv4.gateway:                           --
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
```bash
firewall-cmd --get-active-zones
cat /proc/sys/net/ipv4/ip_forward
firewall-cmd --list-all --zone=internal
firewall-cmd --list-all --zone=external
```

should see this output
```bash
external
  interfaces: ens192
internal
  interfaces: ens224
1
internal (active)
  target: default
  icmp-block-inversion: no
  interfaces: ens224
  sources: 
  services: cockpit dhcpv6-client mdns samba-client ssh
  ports: 
  protocols: 
  masquerade: yes
  forward-ports: 
  source-ports: 
  icmp-blocks: 
  rich rules: 
external (active)
  target: default
  icmp-block-inversion: no
  interfaces: ens192
  sources: 
  services: ssh
  ports: 
  protocols: 
  masquerade: yes
  forward-ports: 
  source-ports: 
  icmp-blocks: 
  rich rules: 
```

### Install and Enable Network Packages [unspecified in Docs]

```bash
dnf install bind bind-utils dhcp-server httpd haproxy nfs-utils wget tftp-server syslinux vim -y
```
```bash
systemctl enable named
vim /etc/named.conf
mkdir /etc/named/zones
vim /etc/named/zones/db.example.com
vim /etc/named/zones/db.reverse
systemctl start named
systemctl status named
systemctl stop named
```
## 7.2.3.5.1. Example DNS configuration for user-provisioned clusters

paste from files on Hive - local directory - Visual Studio

Check all the DNS confirations
```bash
dig ns1.example.com | grep -A 2 ";; ANSWER SECTION:" # Should match: 192.168.1.5
dig smtp.example.com | grep -A 2 ";; ANSWER SECTION:" # Should match: 192.168.1.5
dig helper.example.com | grep -A 2 ";; ANSWER SECTION:" # Should match: 192.168.1.5
dig helper.ocp4.example.com  | grep -A 2 ";; ANSWER SECTION:" # Should match: 192.168.1.5
dig api.ocp4.example.com  | grep -A 2 ";; ANSWER SECTION:" # Should match: 192.168.1.5
dig api-int.ocp4.example.com  | grep -A 2 ";; ANSWER SECTION:" # Should match: 192.168.1.5
dig *.apps.ocp4.example.com  | grep -A 2 ";; ANSWER SECTION:" # Should match: 192.168.1.5
dig bootstrap.ocp4.example.com  | grep -A 2 ";; ANSWER SECTION:" # Should match: 192.168.1.96
dig master0.ocp4.example.com  | grep -A 2 ";; ANSWER SECTION:" # Should match: 192.168.1.97
dig master1.ocp4.example.com  | grep -A 2 ";; ANSWER SECTION:" # Should match: 192.168.1.98
dig master2.ocp4.example.com  | grep -A 2 ";; ANSWER SECTION:" # Should match: 192.168.1.99
dig worker0.ocp4.example.com  | grep -A 2 ";; ANSWER SECTION:" # Should match: 192.168.1.11
dig worker1.ocp4.example.com  | grep -A 2 ";; ANSWER SECTION:" # Should match: 192.168.1.7
```


Check Reverse DNS
```bash
dig -x 192.168.1.5 | grep -A 3 ";; ANSWER SECTION:"
dig -x 192.168.1.96 | grep -A 3 ";; ANSWER SECTION:"
dig -x 192.168.1.97 | grep -A 3 ";; ANSWER SECTION:"
dig -x 192.168.1.98 | grep -A 3 ";; ANSWER SECTION:"
dig -x 192.168.1.99 | grep -A 3 ";; ANSWER SECTION:"
dig -x 192.168.1.11 | grep -A 3 ";; ANSWER SECTION:"
dig -x 192.168.1.7 | grep -A 3 ";; ANSWER SECTION:"
```

### Install and Enable Network Packages [unspecified in Docs]

**Apache Webserver (httpd)**

```bash
systemctl enable httpd
ls /etc/httpd/conf/httpd.conf
sed -i 's/Listen 80/Listen 0.0.0.0:8080' /etc/httpd/conf/httpd.conf
firewall-cmd --add-port=8080/tcp --zone=internal --permanent
firewall-cmd --reload
systemctl start httpd
systemctl status httpd
curl localhost:8080
```

## 7.2.3.6. Load balancing requirements for user-provisioned infrastructure

```bash
systemctl enable haproxy
ls /etc/haproxy/haproxy.cfg
vim /etc/haproxy/haproxy.cfg
```
_copy config files from local drive_
```bash
firewall-cmd --add-port=6443/tcp --zone=internal --permanent # kube-api-server on control plane nodes
firewall-cmd --add-port=6443/tcp --zone=external --permanent # kube-api-server on control plane nodes
firewall-cmd --add-port=22623/tcp --zone=internal --permanent # machine-config server
firewall-cmd --add-service=http --zone=internal --permanent # web services hosted on worker nodes
firewall-cmd --add-service=http --zone=external --permanent # web services hosted on worker nodes
firewall-cmd --add-service=https --zone=internal --permanent # web services hosted on worker nodes
firewall-cmd --add-service=https --zone=external --permanent # web services hosted on worker nodes
firewall-cmd --add-port=9000/tcp --zone=external --permanent # HAProxy Stats
firewall-cmd --reload

setsebool -P haproxy_connect_any 1
systemctl start haproxy
systemctl status haproxy
```

## 7.2.4. Preparing the user-provisioned infrastructure
```bash
systemctl enable dhcpd
ll /etc/dhcp/
vim /etc/dhcp/dhcpd.conf
firewall-cmd --add-service=dhcp --zone=internal --permanent
firewall-cmd --reload
systemctl start dhcpd
systemctl status dhcpd
```

## 7.2.5. Validating DNS resolution for user-provisioned infrastructure
```bash
dig +noall +answer @192.168.1.1 api.ocp4.example.com # Should see: api.ocp4.example.com. 604800 IN A 192.168.1.5
dig +noall +answer @192.168.1.1 api-int.ocp4.example.com # Should see: api-int.ocp4.example.com. 604800 IN A 192.168.1.5
dig +noall +answer @192.168.1.1 random.apps.ocp4.example.com # Should see: random.apps.ocp4.example.com. 604800 IN A 192.168.1.5

dig +noall +answer @192.168.1.1 console-openshift-console.apps.ocp4.example.com
should see:
console-openshift-console.apps.ocp4.example.com. 604800 IN A 192.168.1.5
bootstrap.ocp4.example.com. 604800 IN A 192.168.1.96

dig +noall +answer @192.168.1.1 bootstrap.ocp4.example.com # Should see: bootstrap.ocp4.example.com. 604800 IN A 192.168.1.96

dig +noall +answer @192.168.1.1 -x 192.168.1.5
should see:
5.1.168.192.in-addr.arpa. 604800 IN PTR api.ocp4.example.com.
5.1.168.192.in-addr.arpa. 604800 IN PTR api-int.ocp4.example.com.

dig +noall +answer @192.168.1.1 -x 192.168.1.96 # Should see: 96.1.168.192.in-addr.arpa. 604800 IN PTR bootstrap.ocp4.example.com.
```

## 7.2.6. Generating a key pair for cluster node SSH access
```bash
ssh-keygen -t ed25519 -N '' -f ~/.ssh/id_rsa
cat ~/.ssh/id_rsa.pub
ssh-agent
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_rsa
```

>should see:

```bash
Identity added: /root/.ssh/id_rsa (root@helper)
```

## 7.2.7. Obtaining the installation program
Download the installation file on a local computer
https://console.redhat.com/openshift/install

```bash
mkdir /ocp_files
cd /ocp_files
tar xvf openshift-install-linux.tar.gz
```

## 7.2.8. Installing the OpenShift CLI by downloading the binary
Download the OC CLI file on a local computer
https://access.redhat.com/downloads/content/290

```bash
cd /ocp_files

```

## Other
```
systemctl enable nfs-server rpcbind
systemctl enable tftp
```