#!/usr/bin/env bash

# Load functions
. "${project_base_dir}/library/lib.sh"
. "${project_base_dir}/library/liblog.sh"
. "${project_base_dir}/library/libkubepdpl.sh"
. "${project_base_dir}/config"


########################
# pdpl online
# Arguments:
#   internet yum repo file
# Returns:
#   None
#########################
pdpl_online() {
  
  backup_old_yum_repos
  set_online_yum_repo "CentOS-Base" "${online_centos_repo_url}" "${online_centos_repo_gpgkey}"
  set_online_yum_repo "docker" "${online_docker_rh_repo_url}" "${online_docker_rh_repo_gpgkey}"
  set_online_yum_repo "epel" "${online_epel_repo_url}" "${online_epel_repo_gpgkey}"
  set_online_yum_repo "CentOS-Extra" "${online_centos_extra_repo_url}" "${online_centos_extra_repo_gpgkey}"

  backup_old_pip_repos
  set_online_pip_repo "${online_pip_index_url}" "${online_pip_trusted_host}"

  install_python3_and_ansible
  template_env_file_for_kubespray
}