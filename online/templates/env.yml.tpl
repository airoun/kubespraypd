---
# Download
online_kubedpdl_http_repo: "${online_kubedpdl_http_repo}"

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
kube_apiserver_node_port_range: "30000-33000"
enable_nodelocaldns: "true"

# network plugin
kube_network_plugin: "calico"
