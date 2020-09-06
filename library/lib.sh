#!/usr/bin/env bash

# Load Functions
. "${project_base_dir}/library/liblog.sh"

am_i_root() {
  if [[ $(id -u) -eq 0 ]];
  then
    info "*** Are you root? Yeah, I am ... ***"
  else
    error "*** You must be root, please check your permission, exit now. ***"
    exit 1
  fi
}

disable_selinux() {
  if [[ ! "$(sestatus | grep "SELinux status:" | awk '{print $3}')" = "disabled" ]];
  then
    info "*** selinux is not disabled, disable it now. ***"
    sed -i 's/^SELINUX=.*/SELINUX=disabled/' /etc/selinux/config
    setenforce 0
  else
    info "*** selinux is already disabled, nothing to do. ***"
  fi
}

backup_old_yum_repos() {
  info "*** backup old yum repos ***"
  mkdir -p /etc/yum.repos.d/bak

  if ls /etc/yum.repos.d/*.repo &> /dev/null;
  then
    mv /etc/yum.repos.d/*.repo /etc/yum.repos.d/bak
  fi

  rm -fr /var/cache/yum 
}

backup_old_pip_repos() {
  mkdir -p ~/.pip/
  info "*** backup old pip config ***"
  if [[ -f ~/.pip/pip.conf ]];
  then
    mv ~/.pip/pip.conf ~/.pip/pip.conf.bak."$(date "+%F_%R:%S")"
  fi
}

can_i_connect_to_internet() {
  if ping -c 1 www.baidu.com > /dev/null;
  then
    info "*** connected to the internet ***"
  else
    error "*** cannot connect to the internet, exit now. ***"
    exit 2
  fi 
}

docker_remove_all_images() {

  local dataRoot="$1"

  info "*** removing old docker images ***"
  rm -rf "${dataRoot}"

}

# configure repos
configure_a_yum_repo() {

  local repo_name="$1"
  local repo_url="$2"

  info "*** configure ${repo_name} repo ***"
  cat > /etc/yum.repos.d/"${repo_name}".repo <<EOF
[${repo_name}]
name=${repo_name}- \$releasever
enabled=1
baseurl=${repo_url}
gpgcheck=0
EOF
}

configure_a_pip_repo() {

  local index_url="$1"
  local trusted_host="$2"

  info "*** configure pip repo ${trusted_host} ***"
  cat > ~/.pip/pip.conf <<EOF
[global]
index-url=${index_url}
[install]
trusted-host=${trusted_host}
EOF
}

# install command line tools
check_cmd_if_is_existed() {

  local cmd="$1"

  if command -v "${cmd}" &> /dev/null; then
    info "*** ${cmd} is already installed, nothing to do. ***"
  else
    info "*** ${cmd} is not installed, install it now. ***"
    yum -y -q install "${cmd}"
  fi
}

check_ansible_if_is_existed() {

  local cmd="ansible"
  local requirements="${project_base_dir}/downloads/requirements/python_site_packages_to_download"

  if ansible &> /dev/null; then
    info "*** ${cmd} is already installed, nothing to do. ***"
  else
    info "*** ${cmd} is not installed, install it now. ***"
    check_cmd_if_is_existed "python3"
    pip3 install --user --quiet -r "${requirements}"
    echo "export PATH=/root/.local/bin:$PATH" >> ~/.bashrc
  fi
}

check_docker_if_is_existed() {

  local cmd="docker"

  if docker info &> /dev/null; then
    info "*** ${cmd} is already installed, nothing to do. ***"
  else
    info "*** ${cmd} is not installed, install it now. ***"
    yum -y -q install docker-ce
    systemctl start docker.service
  fi
}

# download
dl_kubespray_code() {

  local downloaddir="$1"

  check_cmd_if_is_existed "git"

  info "*** downloading kubespray code ***"
  cd "${downloaddir}" && rm -fr kubespray/
  git clone https://github.com/kubernetes-sigs/kubespray.git &> /dev/null
}

generate_kubespray_inventory() {

  local hostname="$1"
  local ipaddress="$2"
  local src_file="$3"
  local dst_file="$4"

  export  hostname
  export  ipaddress

  info "*** generate kubespray inventory file ***"
  envsubst < "${src_file}" > "${dst_file}"

  export -n hostname
  export -n ipaddress

}

dl_kubespray_files() {

  local kubespraydir="$1"
  local downloaddir="$2"

  check_ansible_if_is_existed
  check_docker_if_is_existed

  info "*** downloading kubespary files ***"
  cd "${kubespraydir}" || return
  ansible-playbook -i inventory/sample/inventory.ini cluster.yml -e local_release_dir="${downloaddir}" --tags download
}

dl_centos_isos() {

  local downloaddir="$1"
  local requirements="$2"

  check_cmd_if_is_existed "wget"

  rm -rf "${downloaddir}" && mkdir -p "${downloaddir}"
  while IFS= read -r item; do
    info "*** downloading ${item} isos ***"
    cd "${downloaddir}" && wget -q -c  "${item}"
  done < "${requirements}"
}

dl_rpm_packages() {

  local downloaddir="$1"
  local requirements="$2"

  rm -rf "${downloaddir}" && mkdir -p "${downloaddir}"
  while IFS= read -r item; do
    info "*** uninstalling ${item} for downloading ${item} ***"
    yum -y remove "${item}*" &> /dev/null
    info "*** downloading ${item} yum packages ***"
    yum -y install "${item}" --downloadonly --downloaddir="${downloaddir}" &> /dev/null
  done < "${requirements}"

  check_cmd_if_is_existed "createrepo"
  createrepo "${downloaddir}" > /dev/null
}

dl_pip_packages() {

  local downloaddir="$1"
  local requirements="$2"

  check_cmd_if_is_existed "python3"

  info "*** installing pip2pi ***"
  pip3 install -q pip2pi

  rm -rf "${downloaddir}" && mkdir -p "${downloaddir}"
  info "*** downloading pip packages ***"
  cd "${downloaddir}" || return
  pip2tgz path -r "${requirements}" > /dev/null
  dir2pi path/ > /dev/null
}

dl_docker_registry() {

  local downloaddir="$1"

  mkdir -p "${downloaddir}"

  info "*** downloading docker registry image ***"
  docker pull registry:2 &> /dev/null

  cd "${downloaddir}" || return
  docker save registry:2 -o registry.tar &> /dev/null
}

# setup services
setup_http_repo_server() {

  local listen_host="$1"
  local listen_port="$2"
  local data_root="$3"
  local downloaddir="$4"
  local src_file="$5"
  local dst_file="$6"

  check_cmd_if_is_existed "nginx"

  disable_selinux

  info "*** installing nginx as http repo service ***"
  yum -y localinstall "${downloaddir}/nginx-*.rpm" > /dev/null

  export listen_host
  export listen_port
  export data_root

  envsubst < "${src_file}" > "${dst_file}"

  export -n listen_host
  export -n listen_port
  export -n data_root

  systemctl stop firewalld
  if systemctl restart nginx; then
    info "*** http repo has been installed ***"
  else
    info "*** http repo install failed, exit now ***"
    exit 140
  fi
}

setup_docker_service() {
  local data_root="$1"
  local insecure_registry="$2"

  check_docker_if_is_existed

  info "*** configure localhost docker and then restart ***"
  cat > /etc/docker/daemon.json <<EOF
{
"data-root": "${data_root}",
"insecure-registries": ["${insecure_registry}"]
}
EOF
  if systemctl restart docker.service; then
    info "*** docker has been installed ***"
  else
    info "*** docker install failed, exit now ***"
    exit 141
  fi
}

setup_docker_registry_server() {

  local listen_host="$1"
  local listen_port="$2"
  local registry_data="$3"

  check_docker_if_is_existed

  info "*** removing old docker registry ***"
  if docker ps | grep "registry:2";then
    docker rm -f registry &> /dev/null
    rm -rf "${registry_data}"
  fi

  info "*** installing docker registry ***"
  if docker run \
    -d \
    -v "${registry_data}":/var/lib/registry \
    -p 5000:5000  \
    --name registry \
    registry:2;
  then
    info "*** docker registry has been installed ***"
  else
    info "*** docker registry install failed, exit now ***"
    exit 142
  fi
  docker container update --restart=always registry
}

# docker images actions
docker_save_images() {

  local downloaddir="$1"
  local docker_images="$2"

  check_docker_if_is_existed
  mkdir -p "${downloaddir}"

  docker images | grep -v "^REPOSITORY" | awk '{print $1":"$2}' > "${docker_images}"
  while IFS= read -r docker_image; do
    docker_image_file_name=$(echo "${docker_image}" | awk -F ":" '{print $1}' | awk -F "/" '{print $NF}').tar
    info "*** saveing docker image ${docker_image} to file ${docker_image_file_name} ***"
    cd "${downloaddir}" || return
    docker save "${docker_image}" -o "${docker_image_file_name}"
  done < "${docker_images}"
}

docker_load_and_push() {

  local downloaddir="$1"
  local docker_images="$2"
  local new_registry_name="$3"

  check_docker_if_is_existed

  cd "${downloaddir}" || return
  for f in *.tar;
  do
    info "*** loading docker image ${f} ***"
    docker load -i "${f}" &> /dev/null
  done

  while IFS= read -r docker_image; do
    new_docker_image="${new_registry_name}/${docker_image}"
    info "*** docker tag ${docker_image} as ${new_docker_image} ***"
    docker tag "${docker_image}" "${new_docker_image}" &> /dev/null
    info "*** pushing ${new_docker_image}"
    docker push "${new_docker_image}" &> /dev/null
  done < "${docker_images}"
}

modify_directory_name() {

  local downloaddir="$1"

  local kubespray_envfile="${downloaddir}/kubespray/roles/download/defaults/main.yml"
  local release_dir="${downloaddir}/release"
  local image_arch="amd64"

  # etcd
  etcd_version=$(grep "^etcd_version" "${kubespray_envfile}" | awk '{print $2}' | sed $'s/\"//g' )

  # cni
  cni_version=$(grep "^cni_version" "${kubespray_envfile}" | awk '{print $2}' | sed $'s/\"//g')
  cni_dst_dir="${downloaddir}/containernetworking/plugins/releases/download/${cni_version}"
  cni_src_filename="cni-plugins-linux-${image_arch}-${cni_version}.tgz"
  cni_dst_filename="cni-plugins-linux-${image_arch}-${cni_version}.tgz"

  info "*** modify cni plugins directory ***"
  mkdir -p "${cni_dst_dir}"
  /bin/cp "${release_dir}/${cni_src_filename}" "${cni_dst_dir}/${cni_dst_filename}"

  # calico
  calico_ctl_version=$(grep "^calico_version" ${kubespray_envfile} | awk '{print $2}' | sed $'s/\"//g')
  calico_ctl_dst_dir="${downloaddir}/projectcalico/calicoctl/releases/download/${calico_ctl_version}"
  calico_ctl_src_filename="calicoctl"
  calico_ctl_dst_filename="calicoctl-linux-${image_arch}"

  info "*** modify calicoctl directory ***"
  mkdir -p "${calico_ctl_dst_dir}"
  /bin/cp "${release_dir}/${calico_ctl_src_filename}" "${calico_ctl_dst_dir}/${calico_ctl_dst_filename}"

  # kubectl
  # kubelet
  # kubeadm
  kube_version=$(grep "^kube_version" ${kubespray_envfile} | awk '{print $2}' )
  kube_dst_dir="${downloaddir}/kubernetes-release/release/${kube_version}/bin/linux/${image_arch}"

  info "*** modify kube binaries directory ***"
  mkdir -p "${kube_dst_dir}"
  /bin/cp "${release_dir}/kubeadm-${kube_version}-${image_arch}" "${kube_dst_dir}/kubeadm"
  /bin/cp "${release_dir}/kubectl-${kube_version}-${image_arch}" "${kube_dst_dir}/kubectl"
  /bin/cp "${release_dir}/kubelet-${kube_version}-${image_arch}" "${kube_dst_dir}/kubelet"

}

# template environment file for kubespray
template_env_file_for_kubespray() {

  local http_repo="$1"
  local centos_base_repo_url="$2"
  local centos_extra_repo_url="$3"
  local docker_rh_repo="$4"
  local kube_image_repo="$5"
  local docker_image_repo="$6"
  local quay_image_repo="$7"
  local src_file="$8"
  local dst_file="$9"

  export http_repo
  export centos_base_repo_url
  export centos_extra_repo_url
  export docker_rh_repo
  export kube_image_repo
  export docker_image_repo
  export quay_image_repo
  export offline_server_docker_data_root

  envsubst < "${src_file}" > "${dst_file}"

  export -n http_repo
  export -n centos_base_repo_url
  export -n centos_extra_repo_url
  export -n docker_rh_repo
  export -n kube_image_repo
  export -n docker_image_repo
  export -n quay_image_repo
  export -n offline_server_docker_data_root
}

echo_done() {
  info "*** congratulations, it's all done. ***"
}
