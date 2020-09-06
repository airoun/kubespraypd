#!/usr/bin/env bash

# Load Functions

. "${project_base_dir}/library/lib.sh"
. "${project_base_dir}/config"

kubespray_predeploy_download() {
  am_i_root
  can_i_connect_to_internet

  if [[ "${download_centos_iso_enable}X" == "trueX" ]];then
    dl_centos_isos "${project_base_dir}/files/isos" "${project_base_dir}/files/isos_to_download"
  fi

  dl_rpm_packages "${project_base_dir}/files/rpms" "${project_base_dir}/files/centos_rpm_packages_to_download"
  dl_pip_packages "${project_base_dir}/files/pypi" "${project_base_dir}/files/python_site_packages_to_download"

  dl_kubespray_code "${project_base_dir}/files"

  init_kubespray_inventory \
    "${download_server_hostname}" \
    "${download_server_ipaddress}" \
    "${project_base_dir}/templates/offline/inventory.ini.tpl" \
    "${project_base_dir}/files/kubespray/inventory/sample/inventory.ini"

  dl_kubespray_files "${project_base_dir}/files/kubespray" "${project_base_dir}/files/release"

  echo_done
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
  template_env_file_for_kubespray "online"
  echo_done
}

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



