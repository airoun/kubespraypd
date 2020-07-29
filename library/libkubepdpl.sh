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

  info "*** Configuring online ${repo_name} repo ***"
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
  
  info "*** Configuring internet pip repo ***"
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

" > "${env_file}"

  echo "
含有一些重要环境变量的文件env.yml已经保存到${project_base_dir}/env.yml
您可以在使用kubespray时加载它
例如：ansible-playbook -i inventory/mycluster/inventory.ini -e @env.yml cluster.yml
具体信息如下：  
"
  cat "${env_file}"
}
