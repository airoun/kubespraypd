---
# Download
online_kubedpdl_http_repo: "${online_kubedpdl_http_repo}"

extras_rh_repo_base_url: "${online_centos_extra_repo_url}"
extras_rh_repo_gpgkey: "$online_centos_extra_repo_gpgkey}"

docker_rh_repo_base_url: "${online_docker_rh_repo_url}"
docker_rh_repo_gpgkey: "${online_docker_rh_repo_gpgkey}"

kube_image_repo: "${online_kube_image_repo}"
docker_image_repo: "${online_docker_image_repo}"
quay_image_repo: "${online_quay_image_repo}"

kubeadm_download_url: "http://{{ online_kubedpdl_http_repo }}/kubernetes-release/release/{{ kube_version }}/bin/linux/{{ image_arch }}/kubeadm"
kubelet_download_url: "http://{{ online_kubedpdl_http_repo }}/kubernetes-release/release/{{ kube_version }}/bin/linux/{{ image_arch }}/kubelet"
kubectl_download_url: "http://{{ online_kubedpdl_http_repo }}/kubernetes-release/release/{{ kube_version }}/bin/linux/{{ image_arch }}/kubectl"

etcd_download_url: "http://{{ online_kubedpdl_http_repo }}/coreos/etcd/releases/download/{{ etcd_version }}/etcd-{{ etcd_version }}-linux-{{ image_arch }}.tar.gz"
cni_download_url: "http://{{ online_kubedpdl_http_repo }}/containernetworking/plugins/releases/download/{{ cni_version }}/cni-plugins-linux-{{ image_arch }}-{{ cni_version }}.tgz"
calicoctl_download_url: "http://{{ online_kubedpdl_http_repo }}/projectcalico/calicoctl/releases/download/{{ calico_ctl_version }}/calicoctl-linux-{{ image_arch }}"

# Settings
# Etcd
etcd_data_dir: /data/lib/etcd
etcd_kubeadm_enabled: false

# docker
docker_version: '18.09'
docker_daemon_graph: "/data/docker"
docker_cert_dir: "/etc/docker/pki"
docker_insecure_registries:
  - registry.arksec.io:32443

# K8S Master
kube_version: v1.18.5
kube_apiserver_node_port_range: "30000-33000"
kube_api_anonymous_auth: true
kube_apiserver_insecure_port: 0

# network plugin
kube_network_plugin: "calico"
kube_network_plugin_multus: false
kube_service_addresses: 10.233.0.0/18
kube_pods_subnet: 10.233.64.0/18
kube_network_node_prefix: 24

# kube proxy
kube_proxy_mode: ipvs
kube_proxy_strict_arp: false

# dns
cluster_name: cluster.local
dns_mode: coredns
enable_nodelocaldns: true
nodelocaldns_ip: 169.254.25.10
nodelocaldns_health_port: 9254
enable_coredns_k8s_external: false
coredns_k8s_external_zone: k8s_external.local
enable_coredns_k8s_endpoint_pod_names: false
resolvconf_mode: docker_dns