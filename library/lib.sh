#!/usr/bin/env bash

# Load Functions
. "${project_base_dir}/library/liblog.sh"

########################
# Am i root
# Arguments:
#   None
# Returns:
#   None
#########################
am_i_root() {
  if [[ $(id -u) -eq 0 ]];
  then
    info "*** Are you root? Yeah, I am ... ***"
  else
    error "*** You must be root, please check your permission, exit now. ***"
    exit 1
  fi
}

########################
# Disable SELinux
# Arguments:
#   None
# Returns:
#   None
#########################
disable_selinux() {
  if [[ ! "$(sestatus | grep "SELinux status:" | awk '{print $3}')" = "disabled" ]];
  then
    info "*** Check SELinux is not disabled, disable it now. ***"
    sed -i 's/^SELINUX=.*/SELINUX=disabled/' /etc/selinux/config
    setenforce 0
  else
    info "*** Check SELinux is disabled, it's OK. ***"
  fi
}

########################
# Backup old yum repos
# Arguments:
#   None
# Returns:
#   None
#########################
backup_old_yum_repos() {
  info "*** Backup old yum repos ***"
  mkdir -p /etc/yum.repos.d/bak
  
  if ls /etc/yum.repos.d/*.repo &> /dev/null;
  then
    mv /etc/yum.repos.d/*.repo /etc/yum.repos.d/bak
  fi

  rm -fr /var/cache/yum 
}

########################
# Backup old pip repos
# Arguments:
#   None
# Returns:
#   None
#########################
backup_old_pip_repos() {
  mkdir -p ~/.pip/
  info "*** Backup old pip config ***"
  if [[ -f ~/.pip/pip.conf ]];
  then
    mv ~/.pip/pip.conf ~/.pip/pip.conf.bak."$(date "+%F_%R:%S")"
  fi
}

########################
# Check internet connection
# Arguments:
#   None
# Returns:
#   None
#########################
can_i_connect_to_internet() {
  if ping -c 1 www.baidu.com > /dev/null;
  then
    info "*** Connected to the internet ***"
  else
    error "*** Cannot connect to the internet, please check your networking, exit now. ***"
    exit 2
  fi 
}


########################
# print help msg
# Arguments:
#   None
# Returns:
#   None
#########################
print_help_message() {

  echo "
使用kubepdpl.sh初始化kubespray controller运行环境和获取k8s镜像
./kubepdpl.sh {COMMAND}

COMMANDS:
  online        在有互联网的机器上部署kubespray controller
  offline       在没有互联网的机器上部署kubespray controller
  download      预下载所需软件包
  "
}

# configure repos
configure_a_yum_repository() {

  repo_name="$1"
  repo_url="$2"

  info "*** Configure ${repo_name} repo ***"
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

configure_a_pip_repo() {

  index_url="$1"
  trusted_host="$2"

  info "*** Configure internet pip repo ***"
  cat > ~/.pip/pip.conf <<EOF
[global]
index-url=${index_url}
[install]
trusted-host=${trusted_host}
EOF
}

# install command line tools
check_cmd_if_is_existed() {

  cmd="$1"

  if command -v "${cmd}"; then
    info "*** ${cmd} is already installed, nothing to do. ***"
  else
    info "*** ${cmd} is not installed, install it now. ***"
    yum -y -q install "${cmd}"
  fi
}

check_ansible_if_is_existed() {

  cmd="ansible"

  if command -v "${cmd}"; then
    info "*** ${cmd} is already installed, nothing to do. ***"
  else
    info "*** ${cmd} is not installed, install it now. ***"
    check_cmd_if_is_existed "python3"
    pip3 install --user --quiet -r "${project_base_dir}/files/python_site_packages_to_download"
    echo "export PATH=/root/.local/bin:$PATH" >> ~/.bashrc
  fi
}

check_docker_if_is_existed() {

  cmd="docker"

  if command -v "${cmd}"; then
    info "*** ${cmd} is already installed, nothing to do. ***"
  else
    info "*** ${cmd} is not installed, install it now. ***"
    yum -y -q install docker-ce
  fi
}

# download
dl_kubespary_code() {

  downloaddir="$1"

  check_cmd_if_is_existed "git"

  info "*** Downloading kubespray code ***"
  cd "${downloaddir}" && rm -fr kubespary/
  git clone https://github.com/kubernetes-sigs/kubespray.git &> /dev/null
}

dl_kubespary_files() {

  downloaddir="$1"

  check_ansible_if_is_existed

  info "*** Downloading kubespary files"
  cd "${downloaddir}/kubespary" || return
  ansible-playbook -i inventory/sample/inventory.ini cluster.yml --tags download &> /dev/null
}

dl_centos_isos() {

  downloaddir="$1"
  requirements="$2"

  check_cmd_if_is_existed "wget"

  rm -rf "${downloaddir}" && mkdir -p "${downloaddir}"
  while IFS= read -r item; do
    info "*** Downloading ${item} isos ***"
    #wget -q -c -O "${project_base_dir}/files/centos.iso" "${centos_iso_url}"
    cd "${downloaddir}" && wget -q -c  "${item}"
  done < "${requirements}"
}

dl_rpm_packages() {

  downloaddir="$1"
  requirements="$2"

  rm -rf "${downloaddir}" && mkdir -p "${downloaddir}"
  while IFS= read -r item; do
    info "*** Downloading ${item} yum packages ***"
    yum -y remove "${item}" &> /dev/null
    yum -y install "${item}" --downloadonly --downloaddir="${downloaddir}" &> /dev/null
  done < "${requirements}"

  createrepo "${downloaddir}" > /dev/null
}

dl_pip_packages() {

  downloaddir="$1"
  requirements="$2"

  check_cmd_if_is_existed "python3"

  info "*** Installing pip2pi ***"
  pip3 install -q pip2pi

  rm -rf "${downloaddir}" && mkdir -p "${downloaddir}"
  info "*** Downloading pip packages ***"
  cd "${downloaddir}" || return
  pip2tgz path -r "${requirements}" > /dev/null
  dir2pi path/ > /dev/null
}

# setup services
setup_http_repo_server() {

  listen_host="$1"
  listen_port="$2"
  data_root="$3"
  packagesdir="$4"

  check_cmd_if_is_existed "nginx"

  disable_selinux

  info "*** Installing nginx ***"
  yum -y localinstall "${packagesdir}/nginx*.rpm" > /dev/null

  export listen_host
  export listen_port
  export data_root

  envsubst < "${project_base_dir}"/template/nginx.conf.tpl > /etc/nginx/nginx.conf

  export -n listen_host
  export -n listen_port
  export -n data_root

  systemctl stop firewalld

}

setup_docker_registry_server() {

  listen_host="$1"
  listen_port="$2"
  data_root="$3"

  check_docker_if_is_existed

  docker run -d -v "${data_root}":/var/lib/registry \
  -p 5000:5000 --restart=Always \
  --name registry registry:2

}

# template environment file for kubespray
template_env_file_for_kubespray() {
  mode="$1"
  env_file="${project_base_dir}/env.yml"
  if [[ "X${mode}" == "Xonline" ]]; then
    template_env_file="${project_base_dir}}/templates/online/env.yml.tpl"
  elif [ "X${mode}" == "Xoffline" ]; then
    template_env_file="${project_base_dir}}/templates/offline/env.yml.tpl"
  fi

  export online_centos_extra_repo_url
  export online_centos_extra_repo_gpgkey
  export online_centos_repo_url
  export online_centos_repo_gpgkey
  export online_docker_rh_repo_url
  export online_docker_rh_repo_gpgkey
  export online_kube_image_repo
  export online_docker_image_repo
  export online_quay_image_repo
  export online_kubedpdl_http_repo

  envsubst < "${template_env_file}" > "${env_file}"

  export -n online_docker_rh_repo_url
  export -n online_docker_rh_repo_gpgkey
  export -n online_kube_image_repo
  export -n online_docker_image_repo
  export -n online_quay_image_repo
  export -n online_kubedpdl_http_repo
  export -n online_centos_repo_url
  export -n online_centos_repo_gpgkey
  export -n online_centos_extra_repo_url
  export -n online_centos_extra_repo_gpgkey
}

