
Error
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

DNS Checking
```bash
[root@helper installation-dir]# dig api.ocp4.example.com  | grep -A 2 ";; ANSWER SECTION:" # Should match: 192.168.1.5
;; ANSWER SECTION:
api.ocp4.example.com.	604800	IN	A	192.168.1.5

[root@helper installation-dir]# dig -x 192.168.1.5 | grep -A 3 ";; ANSWER SECTION:"
\;; ANSWER SECTION:
5.1.168.192.in-addr.arpa. 604800 IN	PTR	api.ocp4.example.com.
5.1.168.192.in-addr.arpa. 604800 IN	PTR	api-int.ocp4.example.com.


```