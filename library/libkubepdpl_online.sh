#!/usr/bin/env bash

# Load functions
. "${project_base_dir}/library/lib.sh"
. "${project_base_dir}/library/liblog.sh"
. "${project_base_dir}/library/libkubepdpl.sh"
. "${project_base_dir}/config"


########################
# pdpl online
# Arguments:
#   None
# Returns:
#   None
#########################
pdpl_online() {

  am_i_root
  can_i_connect_to_internet
  backup_old_yum_repos
  configure_a_yum_repo "CentOS-Base" "${online_centos_repo_url}"
  configure_a_yum_repo "CentOS-Extra" "${online_centos_extra_repo_url}"
  configure_a_yum_repo "docker_rh" "${online_docker_rh_repo_url}"
  configure_a_yum_repo "epel" "${online_epel_repo_url}"

  backup_old_pip_repos
  configure_a_pip_repo "${online_pip_index_url}" "${online_pip_trusted_host}"

  check_ansible_if_is_existed
  template_env_file_for_kubespray
}