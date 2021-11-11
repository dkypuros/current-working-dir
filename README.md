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
Set Bash variables
```bash
wan=ens192
echo $wan
isolated=ens224
echo $isolated
```

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

## 7.2.3.5.1. Example DNS configuration for user-provisioned clusters

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
systemctl enable haproxy
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
wget https://mirror.openshift.com/pub/openshift-v4/clients/ocp/stable/openshift-install-linux.tar.gz
tar xvf openshift-install-linux.tar.gz
touch pull-secret.txt
```

## 7.2.8. Installing the OpenShift CLI by downloading the binary
Download the OC CLI file on a local computer
https://access.redhat.com/downloads/content/290

```bash
dnf install tar -y
cd /ocp_files
wget https://mirror.openshift.com/pub/openshift-v4/clients/ocp/stable/openshift-client-linux.tar.gz
tar xvzf openshift-client-linux.tar.gz
echo $PATH
cp oc /usr/local/bin
cp kubectl /usr/local/bin
oc version
kubectl version
```
Other Files to download
```bash
wget https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/latest/latest/rhcos-live.x86_64.iso
wget https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/latest/latest/rhcos-metal.x86_64.raw.gz
```

## 7.2.9. Manually creating the installation configuration file
For user-provisioned installations of OpenShift Container Platform, you manually generate your
installation configuration file. Need Pull Secret, and SSH Public Key...

```bash
mkdir /installation-dir
cd /installation-dir
vim install-config.yaml
```

Update the install-config.yaml with your own pull-secret and ssh key.
Line 23 should contain the contents of your pull-secret.txt

```bash
cat /installation-files/pull-secret.txt
```

Line 24 should contain the contents of your '~/.ssh/id_rsa.pub'

```
cat ~/.ssh/id_rsa.pub
```

## 7.2.9.2. Sample install-config.yaml file for bare metal
use the following (formating in related file):

```yaml
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
  name: ocp4
networking:
  clusterNetwork:
    - cidr: 10.128.0.0/14
      hostPrefix: 23
  networkType: OpenShiftSDN
  serviceNetwork:
    - 172.30.0.0/16
platform:
  none: {}
fips: false
pullSecret: 'XXXX'
sshKey: 'XXX'
```

## 7.2.10. Creating the Kubernetes manifest and Ignition config files

Copy the OpenShift Container Platform installation program to the folder you will run the installation from (e.g. /installation-dir).

```bash
cp /ocp_files/openshift-install /installation-dir/
```

The “/installation-dir” must contain the “install-config.yaml” file

```bash
cd /installation-dir
ll
./openshift-install create manifests
ll
```

View files that have been created so far

```bash
tree /installation-dir/
tree /ocp_files
```

Remove the Kubernetes manifest files that define the control plane machines. By removing these files, you prevent the cluster from automatically generating control plane machines. I didn’t notice anything was deleted.

```bash
rm -f /installation-dir/openshift/99_openshift-cluster-api_master-machines-*.yaml
```

Check that the mastersSchedulable parameter in the "/installation-dir//manifests/cluster-scheduler-02-config.yml" Kubernetes manifest
file is set to false.

```bash
vim /installation-dir//manifests/cluster-scheduler-02-config.yml
```

**Create Ignition Configuration Files**
To create the Ignition configuration files, run the following command from the directory that contains the installation program. Ignition config files are created for the bootstrap, control plane, and compute nodes in the installation directory.

```bash
cd /installation-dir
tree
./openshift-install create ignition-configs
tree
```

Before
```bash
├── manifests
│   ├── 04-openshift-machine-config-operator.yaml
│   ├── cluster-config.yaml
│   ├── cluster-dns-02-config.yml
│   ├── cluster-infrastructure-02-config.yml
│   ├── cluster-ingress-02-config.yml
│   ├── cluster-network-01-crd.yml
│   ├── cluster-network-02-config.yml
│   ├── cluster-proxy-01-config.yaml
│   ├── cluster-scheduler-02-config.yml
│   ├── cvo-overrides.yaml
│   ├── kube-cloud-config.yaml
│   ├── kube-system-configmap-root-ca.yaml
│   ├── machine-config-server-tls-secret.yaml
│   ├── openshift-config-secret-pull-secret.yaml
│   └── openshift-kubevirt-infra-namespace.yaml
├── openshift
│   ├── 99_kubeadmin-password-secret.yaml
│   ├── 99_openshift-cluster-api_master-user-data-secret.yaml
│   ├── 99_openshift-cluster-api_worker-user-data-secret.yaml
│   ├── 99_openshift-machineconfig_99-master-ssh.yaml
│   ├── 99_openshift-machineconfig_99-worker-ssh.yaml
│   └── openshift-install-manifests.yaml
└── openshift-install
```

after
```bash
[root@helper installation-dir]# ./openshift-install create ignition-configs
INFO Consuming OpenShift Install (Manifests) from target directory 
INFO Consuming Openshift Manifests from target directory 
INFO Consuming Worker Machines from target directory 
INFO Consuming Common Manifests from target directory 
INFO Consuming Master Machines from target directory 
INFO Ignition-Configs created in: . and auth      
[root@helper installation-dir]# tree
.
├── auth
│   ├── kubeadmin-password
│   └── kubeconfig
├── bootstrap.ign
├── master.ign
├── metadata.json
├── openshift-install
└── worker.ign

1 directory, 7 files
```

## 7.2.11. Installing RHCOS and starting the OpenShift Container Platform bootstrap process

## 7.2.11.1. Installing RHCOS by using an ISO image - Testing Configs with VMWare

I'll start with ISO installation first, then add PXE later.

**File Hosting**

You can configure RHCOS during ISO and PXE installations. Both options need a webserver, so we will set this up now.

```bash
rpm -qa httpd
systemctl enable httpd
systemctl start httpd
systemctl status httpd
```

Upload the bootstrap, control plane, and compute node Ignition config files that the installation program created to your HTTP server. Note the URLs of these files.

```bash
mkdir /var/www/html/ocp4
ll /installation-dir/
cp /installation-dir/*.ign /var/www/html/ocp4/
ll /var/www/html/ocp4/

chcon -R -t httpd_sys_content_t /var/www/html/ocp4/
chown -R apache: /var/www/html/ocp4/
chmod 755 /var/www/html/ocp4/
systemctl stop httpd
systemctl start httpd
```

From the installation host, validate that the Ignition config files are available on the URLs.

```
curl -k http://192.168.1.1:8080/ocp4/bootstrap.ign
curl -k http://192.168.1.1:8080/ocp4/master.ign
curl -k http://192.168.1.1:8080/ocp4/worker.ign
```

**Review the files that are needed fro installation**

RHCOS ISO Image name from earlier steps: rhcos-live.x86_64.iso

```bash
tree /ocp_files/
```

**Preparing the VMware VMs**


**Prepare VMs and Gather MAC Addresses**
Instructions unique to testing ISO installation of VMware environment to simulate bare metal, and test configurations.

Create 3/2/1 control plane vm's

3 Control Plane nodes:
* master0
* master1
* master2

2 Worker nodes:
* worker0
* worker1

1 Bootstrap
* bootstrap

VM settings:
* 4 vCPU, 8GB ram, 50GB disk, network=OCP

ISO to use:
* rhcos-live.x86_64.iso

Local install of ISO
```bash
wget https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/latest/latest/rhcos-live.x86_64.iso
```

* Load the rhcos-X.X.X-x86_64-installer.x86_64.iso image into the boot drive.
* Use the VMware ESXi dashboard to record the MAC address of each vm
* update the dhcpd.conf with MAC addresses

```bash
vim /etc/dhcp/dhcpd.conf
systemctl stop dhcpd
systemctl start dhcpd
systemctl status dhcpd
```

**Build the CoreOS Installer command**

Obtain the SHA512 digest and save it somewhere. 

```bash
cd /installation-dir
sha512sum bootstrap.ign
```

Make a note of the disk name or "device" that you think vmware will use during the boot process of a new system.

```bash
fdisk -l
```

Using the following disk (<device>) name:
```
/dev/sda
```

The --ignition-hash option is required when the Ignition config file is obtained through an HTTP URL to validate the authenticity of the Ignition config file on the cluster node.

```bash
sudo coreos-installer install --ignition-url=http://192.168.1.1:8080/ocp4/bootstrap.ign /dev/sda --insecure-ignition

sudo coreos-installer install --ignition-url=http://192.168.1.1:8080/ocp4/master.ign /dev/sda --insecure-ignition

sudo coreos-installer install --ignition-url=http://192.168.1.1:8080/ocp4/worker.ign /dev/sda --insecure-ignition
```


**Kick OFF ISO install and monitor the Progress**
Before boot, verify all services are running:
```bash
systemctl status named
systemctl status dhcpd
systemctl status haproxy
systemctl status httpd
```

Monitor the progress of the RHCOS installation on the console of the machine. Be sure that the installation is successful on each node before commencing with
the OpenShift Container Platform installation. Observing the installation process can also help to determine the cause of RHCOS installation issues that might arise.

(see 7.2.12 below for options.)

After RHCOS installs, the system reboots. During the system reboot, it applies the Ignition config file that you specified.

Continue to create the other machines for your cluster.

Create the bootstrap and control plane machines at this time. The control plane machines are not schedulable, so we are creating two compute machines to complete the installation of OCP.

The required network, DNS, and load balancer infrastructure is in place and tested so the OpenShift Container Platform bootstrap process will begin automatically after the RHCOS nodes have rebooted.

**Login to CoreOS nodes**

```
ssh core@bootstrap.ocp4.example.com
ssh core@master0.ocp4.example.com
ssh core@master1.ocp4.example.com
ssh core@master2.ocp4.example.com
ssh core@worker0.ocp4.example.com
ssh core@worker1.ocp4.example.com
```

## 7.2.11.2. Installing RHCOS by using PXE or iPXE booting

## 7.2.11.3. Advanced RHCOS installation configuration
## 7.2.11.3.3.1. Embedding a live install Ignition config in the RHCOS ISO
Fun to try on a rainy day.

## 7.2.12. Waiting for the bootstrap process to complete
The configuration information provided through the Ignition config files is used to initialize the bootstrap process and install OpenShift Container Platform on the machines.

```bash
cd /installation-dir
./openshift-install --dir=/installation-dir wait-for bootstrap-complete --log-level=info
```

After bootstrap process is complete, remove the bootstrap machine from the load balancer.
