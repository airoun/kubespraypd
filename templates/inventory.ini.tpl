[all]
${hostname} ansible_host=${ipaddress}  ip=${ipaddress} etcd_member_name=etcd1

[kube-master]
${hostname}

[etcd]
${hostname}

[kube-node]
${hostname}

[calico-rr]

[k8s-cluster:children]
kube-master
kube-node
calico-rr