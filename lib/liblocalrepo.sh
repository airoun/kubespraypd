#!/usr/bin/env bash

# Load Functions

. "${project_base_dir}/lib/lib.sh"
. "${project_base_dir}/lib/liblog.sh"
. "${project_base_dir}/config"

########################
# Internet YUM repo
# Arguments:
#   internet yum repo file
# Returns:
#   None
#########################
set_internet_yum_repo() {
  config_url_list=$1
  
  backup_old_yum_repos

  info "*** Configuring internet Yum repo ***"
  for config_url in ${config_url_list};
  do
    config_name=$(echo ${config_url} | awk -F "/" '{print $NF}')
    curl -o /etc/yum.repos.d/"${config_name}" "${config_url}" &> /dev/null
  done

  sleep 2s

  yum makecache &> /dev/null 
  yum -y install wget createrepo net-tools &> /dev/null 
}

########################
# Local YUM repo
# Arguments:
#   local_repo_home
# Returns:
#   None
#########################
local_yum_repo() {
  local_repo_home=$1
  local_repo_listen_addr=$2
  local_repo_listen_port=$3

  local_yum_repo_uri="/yum"
  local_yum_repo_home="${local_repo_home}${local_yum_repo_uri}"

  info "*** Just wait a moment ***"
  if [[ ! -d "${local_yum_repo_home}" ]];
  then
    mkdir -p "${local_yum_repo_home}"
    mount "${project_base_dir}"/pkg/yum/*.iso "${project_base_dir}"/pkg/yum/mnt_tmp &> /dev/null
    /usr/bin/cp -r "${project_base_dir}"/pkg/yum/mnt_tmp/* "${local_yum_repo_home}"
    umount "${project_base_dir}"/pkg/yum/mnt_tmp/
  fi
  
  backup_old_yum_repos

  info "*** Configuring local Yum repo ***"
  export local_repo_listen_addr
  export local_repo_listen_port
  export local_yum_repo_uri

  envsubst < "${project_base_dir}"/template/os-base.repo.tpl > /etc/yum.repos.d/os-base.repo

  export -n local_repo_listen_addr
  export -n local_repo_listen_port
  export -n local_yum_repo_uri

  yum clean all &> /dev/null && rm -rf /var/cache/yum
  yum makecache &> /dev/null 
}

########################
# Local Pip repo
# Arguments:
#   local_repo_home
#   local_repo_listen_addr
#   local_repo_listen_port
# Returns:
#   None
#########################
local_pip_repo() {
  local_repo_home=$1
  local_repo_listen_addr=$2
  local_repo_listen_port=$3

  local_pip_repo_uri="/pypi"
  local_pip_repo_home="${local_repo_home}${local_pip_repo_uri}"

  mkdir -p "${local_pip_repo_home}"
  cp -r "${project_base_dir}/pkg/pypi/path/" "${local_pip_repo_home}"

  backup_old_pip_repos

  info "*** Configuring local Pip repo ***"

  export local_repo_listen_addr
  export local_repo_listen_port
  export local_pip_repo_uri

  envsubst < "${project_base_dir}"/template/pip.conf.tpl > ~/.pip/pip.conf

  export -n local_repo_listen_addr
  export -n local_repo_listen_port
  export -n local_pip_repo_uri

}

########################
# Internet PIP repo
# Arguments:
#   internet pip repo url
# Returns:
#   None
#########################
set_internet_pip_repo() {
  index_url=$1
  trusted_host=$2
  
  backup_old_pip_repos

  info "*** Configuring internet Pip repo ***"
  cat > ~/.pip/pip.conf <<EOF
[global]
index-url=${index_url}

[install]
trusted-host=${trusted_host}

EOF
}

########################
# Local repo http service
# Arguments:
#   local_repo_home
#   local_repo_listen_addr
#   local_repo_listen_port
# Returns:
#   None
#########################
install_http_service() {
  local_repo_home=$1
  local_repo_listen_addr=$2
  local_repo_listen_port=$3

  disable_selinux

  info "*** Installing nginx ***"
  yum -y localinstall "${project_base_dir}"/pkg/yum/nginx/*.rpm > /dev/null 

  export local_repo_listen_port
  export local_repo_home

  envsubst < "${project_base_dir}"/template/nginx.conf.tpl > /etc/nginx/nginx.conf

  export -n local_repo_listen_port
  export -n local_repo_home

  if systemctl start nginx;
  then
    info "*** HTTP Service installed succeeded ***"
  else
    error "*** HTTP Service install failed, exit now. ***"
    exit 123
  fi 
  systemctl stop firewalld.service 
  systemctl "${local_repo_auto_start}" nginx.service
}

########################
# Install python3 
# Arguments:
#   None 
# Returns:
#   None
#########################
install_python_3() {
  info "*** Installing python 3 ***"
  yum -y localinstall "${project_base_dir}"/pkg/yum/python3/*.rpm > /dev/null 
}

########################
# Install requirements
# Arguments:
#   requirements
# Returns:
#   None
#########################
install_kubespary_pip_requirements() {
  requirements=$1
  info "*** Installing kubespary python requirements ***"
  pip3 install --user --quiet -r "${requirements}"

  export PATH=/root/.local/bin:$PATH
}

########################
# Download rpm packages
# Arguments:
#   yum config url list
# Returns:
#   None
#########################
download_yum_packages() {
  rpm_requirements=$1

  set_internet_yum_repo "${donwload_yum_config_url_list}"

  for item in $(cat ${rpm_requirements} );
  do
    item_packages_dir="${project_base_dir}/pkg/yum/${item}"
    rm -rf "${item_packages_dir}" && mkdir -p "${item_packages_dir}"
    info "*** Downloading Yum ${item} packages ***"
    yum -y remove "${item}" &> /dev/null 
    yum -y install "${item}" --downloadonly --downloaddir="${item_packages_dir}" &> /dev/null
    createrepo "${item_packages_dir}" > /dev/null 
  done
}

########################
# get pip requirements pkgs
# Arguments:
#   None
# Returns:
#   None
#########################
download_pip_packages() {
  requirements_file=$1

  set_internet_pip_repo "${download_pip_index_url}" "${download_pip_trusted_host}"

  # you should run get_yum_package first, and then run this function.
  install_python_3
  pip3 install -q pip2pi 

  info "*** Downloading Pip packages ***"
  cd "${project_base_dir}/pkg/pypi"
  pip2tgz path -r "${requirements_file}" > /dev/null
  dir2pi path/ > /dev/null
}

########################
# get centos iso
# Arguments:
#   Centos version
# Returns:
#   None
#########################
download_centos_iso() {
  donwload_centos_iso_url=$1

  if ls "${project_base_dir}/pkg/iso/*.iso" &> /dev/null;
  then
    info "*** There is a iso found, I will use it. ***"
  else
    if [[ "${downlaod_centos_iso_enabled}" = "true" ]];
    then
      info "*** Downloading CentOS iso ***"
      wget -q -c -O "${project_base_dir}"/pkg/yum/centos.iso "${donwload_centos_iso_url}"
    else
      error "*** Do not download CentOS iso? I didn't find a iso, exit now. ***"
      exit 10
    fi
  fi
}

########################
# Check if download done
# Arguments:
#   None
# Returns:
#   None
#########################
check_if_download_done() {
  if [[ ! -f "${project_base_dir}/.DOWNLOADDONE" ]];
  then
    warn "*** There is no offline packages, please download first. ***"
  fi
}

########################
# Install Function
# Arguments:
#   None
# Returns:
#   None
#########################
localrepo_install() {
  am_i_root

  check_if_download_done

  local_yum_repo "${local_repo_home}" "${local_repo_listen_addr}" "${local_repo_listen_port}"
  local_pip_repo "${local_repo_home}" "${local_repo_listen_addr}" "${local_repo_listen_port}"

  install_python_3
  install_http_service "${local_repo_home}" "${local_repo_listen_addr}" "${local_repo_listen_port}"

  install_kubespary_pip_requirements "${project_base_dir}/requirements/pip.txt"
  info "*** Install Done ***"
}

########################
# Download Function
# Arguments:
#   None
# Returns:
#   None
#########################
localrepo_download() {
  rm -f "${project_base_dir}/.DOWNLOADDONE"

  am_i_root

  can_i_connect_to_internet

  download_yum_packages "${project_base_dir}/requirements/rpm.txt"
  download_pip_packages "${project_base_dir}/requirements/pip.txt"

  download_centos_iso "${donwload_centos_iso_url}"

  touch "${project_base_dir}/.DOWNLOADDONE"
  info "*** Download Done ***"

}
