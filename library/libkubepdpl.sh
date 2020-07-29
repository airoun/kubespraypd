#!/usr/bin/env bash

# Load Functions

. "${project_base_dir}/library/lib.sh"
. "${project_base_dir}/library/liblog.sh"
. "${project_base_dir}/config"

########################
# Online yum repo
# Arguments:
#   1: repo name
#   2: repo url
#   3: repo gpgkey
# Returns:
#   None
# e.g.
#   set_online_yum_repo centos http://xxxxx http://xxxxx
#########################
set_online_yum_repo() {
  repo_name=$1
  repo_url=$2
  repo_gpgkey=$3

  info "*** Configure online ${repo_name} repo ***"
  # for config_url in ${config_url_list};
  # do
  #   config_name=$(echo ${config_url} | awk -F "/" '{print $NF}')
  #   curl -o /etc/yum.repos.d/"${config_name}" "${config_url}" &> /dev/null
  # done

  cat > /etc/yum.repos.d/"${repo_name}".repo <<EOF
[${repo_name}]
name=${repo_name}- \$releasever
enabled=1
baseurl=${repo_url}
gpgcheck=0
gpgkey=${repo_gpgkey}

EOF
}


########################
# Online pip repo
# Arguments:
#   1: pip repo url
# Returns:
#   None
#########################
set_online_pip_repo() {
  index_url=$1
  trusted_host=$2
  
  info "*** Configure internet pip repo ***"
  cat > ~/.pip/pip.conf <<EOF
[global]
index-url=${index_url}

[install]
trusted-host=${trusted_host}

EOF
}


########################
# Install python3 and ansible
# Arguments:
#   None
# Returns:
#   None
#########################
install_python3_and_ansible() {
  requirements="${project_base_dir}/requirements/pip.txt"

  info "*** Installing python 3 ***"
  yum -y -q install python3

  info "*** Installing kubespary python requirements ***"
  pip3 install --user --quiet -r "${requirements}"

  echo "export PATH=/root/.local/bin:$PATH" >> ~/.bashrc
}

########################
# Print environment for kubespray
# Arguments:
#   None
# Returns:
#   None
#########################
print_kubespray_environment() {
  env_file="${project_base_dir}/env.yml"
  rm -f "${env_file}"

  info "*** Save kubespray evironment file to ${env_file} ***"
  echo "
# Docker
docker_rh_repo_base_url: \"${online_docker_rh_repo_url}\"
docker_rh_repo_gpgkey: \"${online_docker_rh_repo_gpgkey}\"

# Kubernetes image repo
kube_image_repo: \"${online_kube_image_repo}\"
docker_image_repo: \"${online_docker_image_repo}\"
quay_image_repo: \"${online_quay_image_repo}\"

# Download
kubeadm_download_url: \"http://${online_kubedpdl_http_repo}/kubernetes-release/release/{{ kube_version }}/bin/linux/{{ image_arch }}/kubeadm\"
kubelet_download_url: \"http://${online_kubedpdl_http_repo}/kubernetes-release/release/{{ kube_version }}/bin/linux/{{ image_arch }}/kubelet\"
kubectl_download_url: \"http://${online_kubedpdl_http_repo}/kubernetes-release/release/{{ kube_version }}/bin/linux/{{ image_arch }}/kubectl\"

etcd_download_url: \"http://${online_kubedpdl_http_repo}/coreos/etcd/releases/download/{{ etcd_version }}/etcd-{{ etcd_version }}-linux-{{ image_arch }}.tar.gz\"
cni_download_url: \"http://${online_kubedpdl_http_repo}/containernetworking/plugins/releases/download/{{ cni_version }}/cni-plugins-linux-{{ image_arch }}-{{ cni_version }}.tgz\"
calicoctl_download_url: \"http://${online_kubedpdl_http_repo}/projectcalico/calicoctl/releases/download/{{ calico_ctl_version }}/calicoctl-linux-{{ image_arch }}\"
crictl_download_url: \"https://github.com/kubernetes-sigs/cri-tools/releases/download/{{ crictl_version }}/crictl-{{ crictl_version }}-{{ ansible_system | lower }}-{{ image_arch }}.tar.gz\"

" > "${env_file}"

}
