# OCP 4.8 Bare Metal UPI
## David's Walk through Chapter 7 of the Docs

The purpose of these instructions is to walk through all 3 sections of the documentation (7.1, 7.2, and 7.3)

## 7.1. PREPARING FOR BARE METAL CLUSTER INSTALLATION
>This is mainly informational

## 7.2. INSTALLING A USER-PROVISIONED CLUSTER ON BARE METAL
>This is mainly informational

## 7.2.3.4.2 Network Connectivity requirements
In this section we will host based networking via a CentOS "helper system" that will provide requisite networking services.

The system will have 2 network interfaces configured as follows:

The "WAN" NIC directs traffic toward the internet

```bash
nmcli con show
```

NAME UUID TYPE DEVICE

wan f3cca7c6-b9a6-45ed-bea0-b9afafdde095 ethernet enp1s0

isolated 36ade008-902f-4954-b928-4c45c36d74c7 ethernet enp2s0


How it works:

nmcli connection modify wan setting.property value


Name the connections:
```bash
nmcli con modify enp2s0 connection.id isolated

nmcli con modify enp1s0 connection.id wan
```

Connection Autoconnect
```bash
nmcli connection modify wan connection.autoconnect yes

nmcli connection show wan | grep connection.autoconnect
```

IPv4 Method:
```bash
nmcli connection modify wan ipv4.method auto

nmcli con show wan | grep ipv4.method
```

DNS Localhost:
```bash
nmcli connection modify wan ipv4.dns 127.0.0.1
```

Gateway Empty:
```bash
nmcli con show wan | grep ipv4.gateway
```

should look like this:

ipv4.gateway: --


Ignore Auto Routes
```bash
nmcli con show wan | grep ipv4.ignore-auto-routes
```

should look like this:

ipv4.ignore-auto-routes: no


Ignore Auto DNS
```bash
nmcli connection modify wan ipv4.ignore-auto-dns yes
nmcli con show wan | grep ipv4.ignore-auto-dns
```

should look like this:

ipv4.ignore-auto-dns: yes


Isolated NIC
```bash
nmcli connection modify isolated connection.autoconnect yes
nmcli connection show isolated | grep connection.autoconnect
```
Set DNS Address:
```bash
nmcli connection modify isolated ipv4.dns 127.0.0.1
nmcli con show isolated | grep ipv4.dns
```

Set IP Address:
```bash
nmcli connection modify isolated ipv4.addresses 192.168.1.1/24
nmcli con show isolated | grep ipv4.addresses
```

DNS Search
```bash
nmcli connection modify isolated ipv4.dns-search example.com
nmcli connection show isolated | grep dns-search
```

Gateway
```bash
nmcli connection show isolated | grep ipv4.gateway
```

IPv4 Method:
```bash
nmcli connection modify isolated ipv4.method manual
nmcli con show isolated | grep ipv4.method
```

## 7.2.3.5.1. Example DNS configuration for user-provisioned clusters

There are 3 DNS configuratoin files.
1. named.conf
2. /zones/db.example.com
3. /zones/db.reverse

## 7.2.3.6. Load balancing requirements for user-provisioned infrastructure




===========================================================

Red Hat OpenShift User Provisioned Infrastructure

Architecture
I need a better quick networking architecture design. Maybe something like Ryan’s.
Installation Steps

## Part 0 - “Pre” work or before you start configuration steps
    • CentOS ISO downloaded
    • Use the following for the MAC address of Test VM
        ◦ 52:54:00:8b:28:62
    • MACs for Actual Deployment
        ◦ bootstrap hardware ethernet 52:54:00:8b:28:62
        ◦ master0 hardware ethernet 00:0c:29:65:d5:0f
        ◦ master1 hardware ethernet 00:0c:29:8e:91:c2
        ◦ master2 hardware ethernet 00:0c:29:4e:e6:77
        ◦ worker0 hardware ethernet 00:0c:29:da:35:11
        ◦ worker1 hardware ethernet 00:0c:29:3d:ea:c4
## Part 1 - Host System: Libvirt Setup
    • Software install “libvirt” search
    • Configure “Networks” for Libvirt itself
    • Install CentOS – “helper” vm
## Part 1.1 - Helper VM: NMCLI Setup
Configure network inside the “helper VM” or host level networking
    • nmcli “wan”
    • nmcli “isolated”
file:[[nmcli-configuration]]
file:[[firewall-zones]]
*build according to architectural diagram

## Part 1.2 - Helper VM: Install Networking Services
enable, start , stop
    • dhcp-server
    • bind bind-utils
    • wget
    • etc
file:[[1.2.helper-vm-networking-services]]

## Part 1.3 - Helper VM: USB File Copy
Usb /location/ to “/xxx/xxx/xxx.conf”
List of configuration files for viewing
    • configs > zones > db.example.com
    • configs > zones > db.reverse
    • configs > namded.conf
    • configs > dhcpd.conf
    • configs > haproxy.cfg
file:[[Part 1.3 - Helper VM: USB File Copy]]
Part 1.4 - Helper VM Test 01
I need to come back to this later.
Test via CLI
    • digg configuration
Test via “test vm”
    • install CentOS to isolated network
    • configure OS networking
    • reboot and make sure vm gets correct IP, and hostname from DHCP
file:[[test-vm-config]]

## Part 2 - Following OCP PXE Instructions
Test DNS
dig +noall +answer @192.168.1.1 api.ocp4.example.com
should see: 
api.ocp4.example.com. 604800 IN A 192.168.1.5

dig +noall +answer @192.168.1.1 api-int.ocp4.example.com
should see:
api-int.ocp4.example.com. 604800 IN A 192.168.1.5

dig +noall +answer @192.168.1.1 random.apps.ocp4.example.com
should see:
random.apps.ocp4.example.com. 604800 IN A 192.168.1.5

dig +noall +answer @192.168.1.1 console-openshift-console.apps.ocp4.example.com
should see:
console-openshift-console.apps.ocp4.example.com. 604800 IN A 192.168.1.5
bootstrap.ocp4.example.com. 604800 IN A 192.168.1.96

dig +noall +answer @192.168.1.1 bootstrap.ocp4.example.com
should see:
bootstrap.ocp4.example.com. 604800 IN A 192.168.1.96

dig +noall +answer @192.168.1.1 -x 192.168.1.5
should see:
5.1.168.192.in-addr.arpa. 604800 IN PTR api.ocp4.example.com.
5.1.168.192.in-addr.arpa. 604800 IN PTR api-int.ocp4.example.com.

dig +noall +answer @192.168.1.1 -x 192.168.1.96
should see:
96.1.168.192.in-addr.arpa. 604800 IN PTR bootstrap.ocp4.example.com.

SSH Key Gen
ssh-keygen -t ed25519 -N '' -f ~/.ssh/id_rsa
cat ~/.ssh/id_rsa.pub
ssh-agent
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_rsa
should see:
Identity added: /root/.ssh/id_rsa (root@helper)

Gathering a nunch of files
mkdir /installation-files
    • https://console.redhat.com/openshift/install
        ◦ OpenShift installer (use wget)
            ▪ wget https://mirror.openshift.com/pub/openshift-v4/clients/ocp/stable/openshift-install-linux.tar.gz
        ◦ Pull secret
            ▪ touch pull-secret.txt
        ◦ OCP CLI (oc) Command line interface
            ▪ wget https://mirror.openshift.com/pub/openshift-v4/clients/ocp/stable/openshift-client-linux.tar.gz
        ◦ rhcos iso - installer ISO image
            ▪ wget https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/latest/latest/rhcos-live.x86_64.iso
        ◦ rhcos raw - the compressed metal RAW
            ▪ wget https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/latest/latest/rhcos-metal.x86_64.raw.gz

Installation program (binary)
dnf install tar -y

Trying to keep my files directory clean for another project.
cp /installation-files/openshift-install-linux.tar.gz /installation-dir
tar xvf openshift-install-linux.tar.gz

Install OC CLI
```bash
cd /installation-files
tar xvzf openshift-client-linux.tar.gz
echo $PATH
mv oc /usr/local/bin
mv kubectl /usr/local/bin
oc version
```

Create Installation Configuration File
For user-provisioned installations of OpenShift Container Platform, you manually generate your
installation configuration file. Need Pull Secret, and SSH Public Key...

mkdir /installation-dir
cd /installation-dir
vim install-config.yaml
Update the install-config.yaml with your own pull-secret and ssh key.
    • Line 23 should contain the contents of your pull-secret.txt
        ◦ cat /installation-files/pull-secret.txt
    • Line 24 should contain the contents of your '~/.ssh/id_rsa.pub'
        ◦ cat ~/.ssh/id_rsa.pub

use the following (formating in related file):
apiVersion: v1
baseDomain: example.com
compute:
- hyperthreading: Enabled
name: worker
replicas: 0
controlPlane:
hyperthreading: Enabled
name: master
replicas: 3
metadata:
name: test
networking:
clusterNetwork:
- cidr: 10.128.0.0/14
hostPrefix: 23 10
networkType: OpenShiftSDN
serviceNetwork:
- 172.30.0.0/16
platform:
none: {}
fips: false 13
pullSecret: '{"auths": ...}'
sshKey: 'ssh-ed25519 AAAA...'


3 Node OCP - 7.2.9.4. Configuring a three-node cluster

Create the Manifests
It's basically a Kubernetes "API object description". A config file can include one or more of these. (i.e. Deployment, ConfigMap, Secret, DaemonSet, etc). They describe the desired state of your application in terms of Kubernetes API objects.

Change to the directory that contains the OpenShift Container Platform installation program.
The “/installation-dir” must contain the “install-config.yaml” file
./openshift-install create manifests --dir=/installation-dir
or
cd /installation-dir
./openshift-install create manifests

Remove the Kubernetes manifest files that define the control plane machines. By removing these files, you prevent the cluster from automatically generating control plane machines. I didn’t notice anything was deleted.
rm -f /installation-dir/openshift/99_openshift-cluster-api_master-machines-*.yaml

Create Ignition Configuration Files:
./openshift-install create ignition-configs --dir=/installation-dir
./openshift-install create ignition-configs

Installing RHCOS by using PXE or iPXE booting 7.2.11.2
Apache to host files for PXE. Upload the bootstrap, control plane, and compute node Ignition config files that the installation
program created to your HTTP server.

mkdir /var/www/html/ocp4
cp /installation-dir/bootstrap.ign /var/www/html/ocp4/
cp /installation-dir/master.ign /var/www/html/ocp4/
cp /installation-dir/worker.ign /var/www/html/ocp4/
cp /installation-dir/worker.ign /var/www/html/ocp4/

chcon -R -t httpd_sys_content_t /var/www/html/ocp4/
chown -R apache: /var/www/html/ocp4/
chmod 755 /var/www/html/ocp4/

curl localhost:8080/ocp4
curl -k http://localhost:8080/ocp4/bootstrap.ign

curl -k http://192.168.1.1:8080/ocp4/bootstrap.ign
curl -k http://192.168.1.1:8080/ocp4/master.ign
curl -k http://192.168.1.1:8080/ocp4/worker.ign

Obtain the RHCOS kernel, initramfs and rootfs files from the RHCOS image mirror page.
mkdir /installation-files/rhcos-image-mirror
cd /installation-files/rhcos-image-mirror
    • rhcos-4.8.14-x86_64-live-initramfs.x86_64.img
        ◦ wget https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/4.8/latest/rhcos-4.8.14-x86_64-live-initramfs.x86_64.img
    • rhcos-4.8.14-x86_64-live-kernel-x86_64
        ◦ wget https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/4.8/latest/rhcos-4.8.14-x86_64-live-kernel-x86_64
    • rhcos-4.8.14-x86_64-live-rootfs.x86_64.img
        ◦ wget https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/4.8/latest/rhcos-4.8.14-x86_64-live-rootfs.x86_64.img
    • rhcos-4.8.14-x86_64-live.x86_64.iso
        ◦ wget https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/4.8/latest/rhcos-4.8.14-x86_64-live.x86_64.iso
cp /installation-files/rhcos-image-mirror/* /var/www/html/ocp4/
should see this:
[root@helper rhcos-image-mirror]# ll /var/www/html/ocp4/
total 2012804
-rw-r-----. 1 apache apache 271520 Nov 4 05:30 bootstrap.ign
-rw-r-----. 1 apache apache 1718 Nov 4 05:30 master.ign
-rw-r--r--. 1 root root 89362572 Nov 4 06:46 rhcos-4.8.14-x86_64-live-initramfs.x86_64.img
-rw-r--r--. 1 root root 10030448 Nov 4 06:46 rhcos-4.8.14-x86_64-live-kernel-x86_64
-rw-r--r--. 1 root root 925434368 Nov 4 06:46 rhcos-4.8.14-x86_64-live-rootfs.x86_64.img
-rw-r--r--. 1 root root 1035993088 Nov 4 06:46 rhcos-4.8.14-x86_64-live.x86_64.iso
-rw-r-----. 1 apache apache 1718 Nov 4 05:30 worker.ign

http://192.168.1.1:8080/rhcos-4.8.14-x86_64-live-initramfs.x86_64.img
http://192.168.1.1:8080/rhcos-4.8.14-x86_64-live-kernel-x86_64
http://192.168.1.1:8080/rhcos-4.8.14-x86_64-live-rootfs.x86_64.img
http://192.168.1.1:8080/rhcos-4.8.14-x86_64-live.x86_64.iso

At this point all these files are available on an webserver

Setup tftp 
dnf install tftp-server -y
systemctl enable tftp
systemctl start tftp
systemctl status tftp

dnf install syslinux -y

Copy Menu Over:
cp /usr/share/syslinux/vesamenu.c32 /var/lib/tftpboot/
wget https://raw.githubusercontent.com/leoaaraujo/openshift_pxe_boot_menu/main/files/bg-ocp.png -O /var/lib/tftpboot/bg-ocp.png

Make PXE Config file called “default”
mkdir /var/lib/tftpboot/pxelinux.cfg/
vim /var/lib/tftpboot/pxelinux.cfg/default
copy config from visual-studio / lab-files area of laptop

Test files locations again:
curl -k http://192.168.1.1:8080/ocp4/bootstrap.ign
curl -k http://192.168.1.1:8080/ocp4/master.ign
curl -k http://192.168.1.1:8080/ocp4/worker.ign

EOF - #Below here is just for reference
==============================================================
Part 2 - Standard PXE CentOS 8 test
file:[[part-2-standard-pxe-test]]

