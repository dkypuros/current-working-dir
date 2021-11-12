
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

DNS Looks OK
```bash
[root@helper installation-dir]# dig api.ocp4.example.com  | grep -A 2 ";; ANSWER SECTION:" # Should match: 192.168.1.5
;; ANSWER SECTION:
api.ocp4.example.com.	604800	IN	A	192.168.1.5

[root@helper installation-dir]# dig -x 192.168.1.5 | grep -A 3 ";; ANSWER SECTION:"
\;; ANSWER SECTION:
5.1.168.192.in-addr.arpa. 604800 IN	PTR	api.ocp4.example.com.
5.1.168.192.in-addr.arpa. 604800 IN	PTR	api-int.ocp4.example.com.
```

I'm looking at this currently

## 8.6.5. The API is not accessible

https://access.redhat.com/documentation/en-us/openshift_container_platform/4.8/html-single/installing/index#ipi-install-troubleshooting

Hostname Resolution: Check the cluster nodes to ensure they have a fully qualified domain name, and not just localhost.localdomain. For example:

```bash
hostname

hostnamectl set-hostname <hostname>

```

specific error from rhcoreos
```bash
I manually set the hostname, and the changes didn't seem to persist. Still same errors.read udf 192.168.1.1:44327 -> 192.168.1.1:53 no route to host.
```

The story of DHCP and hostnames
> But, as the man dhcpd.conf says: It should be noted here that most DHCP clients completely ignore the host-name option sent by the DHCP server, and  here is no way to configure them not to do this. So you generally have a choice of either not having any hostname to client IP address mapping that the  client will recognize, or doing DNS updates. 

More Info from Redhat.com
https://www.redhat.com/sysadmin/set-hostname-linux


ssh core@bootstrap.ocp4.example.com



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
I'm deleting the whole VM. 



