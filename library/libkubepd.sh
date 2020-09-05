#!/usr/bin/env bash

# Load Functions

. "${project_base_dir}/library/lib.sh"
. "${project_base_dir}/library/liblog.sh"
. "${project_base_dir}/config"

kubespray_predeploy_download() {
  am_i_root
  can_i_connect_to_internet

  dl_kubespray_code "${project_base_dir}/files"
  dl_kubespray_files "${project_base_dir}/files/"

  if [[ "${download_centos_iso_enable}X" == "trueX" ]];then
    dl_centos_isos "${project_base_dir}/isos"
  fi

  dl_rpm_packages "${project_base_dir}/rpms"
  dl_pip_packages "${project_base_dir}/pypi"
}

kubespray_predeploy_online() {

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



