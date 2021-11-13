
## First Error (system MicroCenter Build)
```bash
[root@helper installation-dir]# ./openshift-install --dir=/installation-dir wait-for bootstrap-complete --log-level=info

INFO Waiting up to 20m0s for the Kubernetes API at https://api.ocp4.example.com:6443... 
ERROR Attempted to gather ClusterOperator status after wait failure: listing ClusterOperator objects: Get "https://api.ocp4.example.com:6443/apis/config.openshift.io/v1/clusteroperators": dial tcp 192.168.1.5:6443: connect: no route to host 
INFO Use the following commands to gather logs from the cluster 
INFO openshift-install gather bootstrap --help    
ERROR Bootstrap failed to complete: Get "https://api.ocp4.example.com:6443/version?timeout=32s": dial tcp 192.168.1.5:6443: connect: no route to host 
ERROR Failed waiting for Kubernetes API. This error usually happens when there is a problem on the bootstrap host that prevents creating a temporary control plane. 
FATAL Bootstrap failed to complete   
```

Checked DNS, and it looks OK.
```bash
[root@helper installation-dir]# dig api.ocp4.example.com  | grep -A 2 ";; ANSWER SECTION:" # Should match: 192.168.1.5
;; ANSWER SECTION:
api.ocp4.example.com.	604800	IN	A	192.168.1.5

[root@helper installation-dir]# dig -x 192.168.1.5 | grep -A 3 ";; ANSWER SECTION:"
\;; ANSWER SECTION:
5.1.168.192.in-addr.arpa. 604800 IN	PTR	api.ocp4.example.com.
5.1.168.192.in-addr.arpa. 604800 IN	PTR	api-int.ocp4.example.com.
```

Hostname Resolution fixed.

```bash
hostname

hostnamectl set-hostname <hostname>

```

Doing what error message says to do:

```bash
cd /installation-dir/
./openshift-install gather bootstrap --help
```

shows the following:
```
Gather debugging data for a failing-to-bootstrap control plane

Usage:
  openshift-install gather bootstrap [flags]

Flags:
      --bootstrap string     Hostname or IP of the bootstrap host
  -h, --help                 help for bootstrap
      --key stringArray      Path to SSH private keys that should be used for authentication. If no key was provided, SSH private keys from user's environment will be used
      --master stringArray   Hostnames or IPs of all control plane hosts
      --skipAnalysis         Skip analysis of the gathered data

Global Flags:
      --dir string         assets directory (default ".")
      --log-level string   log level (e.g. "debug | info | warn | error") (default "info")

```
exploring these commands from help:

```bash
./openshift-install gather bootstrap --bootstrap bootstrap.ocp4.example.com --master master0.ocp4.example.com
```

output
```bash
[root@helper installation-dir]# ./openshift-install gather bootstrap --bootstrap bootstrap.ocp4.example.com --master master0.ocp4.example.com
INFO Pulling debug logs from the bootstrap machine 
INFO Bootstrap gather logs captured here "/installation-dir/log-bundle-20211113072507.tar.gz" 
ERROR The bootstrap machine failed to download the release image 
INFO Error: Error initializing source docker://quay.io/openshift-release-dev/ocp-release@sha256:386f4e08c48d01e0c73d294a88bb64fac3284d1d16a5b8938deb3b8699825a88: error pinging docker registry quay.io: Get "https://quay.io/v2/": dial tcp: lookup quay.io on 192.168.1.1:53: read udp 192.168.1.96:36996->192.168.1.1:53: read: no route to host 
INFO Pull failed. Retrying quay.io/openshift-release-dev/ocp-release@sha256:386f4e08c48d01e0c73d294a88bb64fac3284d1d16a5b8938deb3b8699825a88... 
INFO Error: Error initializing source docker://quay.io/openshift-release-dev/ocp-release@sha256:386f4e08c48d01e0c73d294a88bb64fac3284d1d16a5b8938deb3b8699825a88: error pinging docker registry quay.io: Get "https://quay.io/v2/": dial tcp: lookup quay.io on 192.168.1.1:53: read udp 192.168.1.96:40590->192.168.1.1:53: read: no route to host 
```

Found an error, I can't ping "quay.io" from the bootstrap node. Networking issues in general.

```bash
ssh core@bootstrap.ocp4.example.com

[core@bootstrap ~]$ ping quay.io
ping: quay.io: Name or service not known

[core@bootstrap ~]$ ping master0.ocp4.example.com
ping: master0.ocp4.example.com: Name or service not known

ip add

2: ens192: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP group default qlen 1000
    link/ether 00:0c:29:fe:72:3a brd ff:ff:ff:ff:ff:ff
    inet 192.168.1.96/24 brd 192.168.1.255 scope global dynamic noprefixroute ens192
       valid_lft 12289sec preferred_lft 12289sec
    inet6 fe80::4859:d96c:5eeb:87c0/64 scope link noprefixroute 
       valid_lft forever preferred_lft forever

[core@bootstrap ~]$ nmcli con show
NAME                UUID                                  TYPE      DEVICE 
Wired connection 1  55134531-6be0-3f2c-83e2-dfbb7b0d7ecc  ethernet  ens192 

[core@bootstrap ~]$ hostname
bootstrap

[core@bootstrap ~]$ ping master0
ping: master0: Name or service not known
[core@bootstrap ~]$ ping bootstrap
PING bootstrap(bootstrap (fe80::4859:d96c:5eeb:87c0%ens192)) 56 data bytes
64 bytes from bootstrap (fe80::4859:d96c:5eeb:87c0%ens192): icmp_seq=1 ttl=64 time=0.069 ms
64 bytes from bootstrap (fe80::4859:d96c:5eeb:87c0%ens192): icmp_seq=2 ttl=64 time=0.047 ms

```

Issue so far, networking is looking good from the "helper system" but not from the actual nodes.

## Second Error (Dell R710)

Device ens224 is showing blank.
```bash
root@helper ~]# nmcli con show
NAME    UUID                                  TYPE      DEVICE 
ens192  6cd49951-a09a-4c22-a8c8-028e9d394ad9  ethernet  ens192 
ens224  fa699e0a-d92a-4ace-8de2-9268ef7938f9  ethernet  --     
```
Take VM back to state 0.
Review status of the vm once I reboot VM in state 0.
Device is still empty.

Remove the Network Adapter 2 from ESXi, and power on. Review nmcli connnection information. Is it gone? No. That's strange.
I'm deleting the whole VM, and re-installing CentOS 8. Nope, still have an empty device.
I'm deleting the whole VM and OCP network. 
Recreating the VM, and during the install turning on both NICs. I'm also installing the full GUI server.

...that worked.

```bash
[root@helper ~]# nmcli con show
NAME    UUID                                  TYPE      DEVICE 
ens192  0a19ddd1-2624-41a4-b8ae-f09dd4f3c43d  ethernet  ens192 
ens224  ddbff163-5c7b-4263-a195-387f923973d1  ethernet  ens224 
virbr0  b677997e-ee87-4d7d-970f-2941d9524fd4  bridge    virbr0 
```


