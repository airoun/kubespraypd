#!/usr/bin/env bash

# Load Functions

. "${project_base_dir}/library/lib.sh"
. "${project_base_dir}/config"

downloaddir="${project_base_dir}/downloads"
templatedir="${project_base_dir}/templates"
requirements="${project_base_dir}/downloads/requirements"

kubespray_predeploy_download() {

  am_i_root

  can_i_connect_to_internet

  backup_old_yum_repos
  configure_a_yum_repo \
    "CentOS-Base" "${online_centos_repo_url}"
  configure_a_yum_repo \
    "CentOS-Extra" "${online_centos_extra_repo_url}"
  configure_a_yum_repo \
    "CentOS-epel" "${online_epel_repo_url}"
  configure_a_yum_repo \
    "rh-docker" "${online_docker_rh_repo_url}"

  backup_old_pip_repos
  configure_a_pip_repo \
    "${online_pip_index_url}" "${online_pip_trusted_host}"

  if [[ "${download_centos_yes_or_not}X" == "yesX" ]];then
    dl_centos_isos \
      "${downloaddir}/isos" "${requirements}/isos_to_download"
  fi

  dl_rpm_packages \
    "${downloaddir}/rpms" "${requirements}/centos_rpm_packages_to_download"

  dl_pip_packages \
    "${downloaddir}/pypi" "${requirements}/python_site_packages_to_download"

  dl_kubespray_code \
    "${downloaddir}"

  generate_kubespray_inventory \
    "${download_server_hostname}" "${download_server_ipaddress}" \
    "${templatedir}/inventory.ini.tpl" \
    "${downloaddir}/kubespray/inventory/sample/inventory.ini"

  dl_kubespray_files \
    "${downloaddir}/kubespray" "${downloaddir}/release"

  dl_docker_registry \
    "${downloaddir}/docker-images"

  docker_save_images \
    "${downloaddir}/docker-images" "${requirements}/images_to_push"

  echo_done
}


kubespray_predeploy_offline() {

  am_i_root

  local http_repo="${offline_server_host}:${offline_server_http_repo_port}"
  local docker_registry=""${offline_server_host}:${offline_server_docker_registry_port}""

  setup_http_repo_server \
    "${offline_server_host}" "${offline_server_http_repo_port}" \
    "${downloaddir}" "${downloaddir}/rpms" \
    "${templatedir}/nginx.conf.tpl" "/etc/nginx/nginx.conf"

  backup_old_yum_repos
  configure_a_yum_repo \
    "kubespraypd" "http://${offline_server_host}:${offline_server_http_repo_port}/rpms"

  backup_old_pip_repos
  configure_a_pip_repo \
    "http://${http_repo}/pypi/path/simple" "${offline_server_host}"

  setup_docker_service \
    "${offline_server_docker_data_root}" "${docker_registry}"

  setup_docker_registry_server \
    "${offline_server_host}" "${offline_server_docker_registry_port}" "${offline_server_docker_registry_data}"

  check_ansible_if_is_existed

  template_env_file_for_kubespray \
    "${http_repo}" \
    "${http_repo}/centos" \
    "${http_repo}/rpms" \
    "${http_repo}/extra" \
    "${docker_registry}/k8s.gcr.io" \
    "${docker_registry}/docker.io" \
    "${docker_registry}/quay.io" \
    "${project_base_dir}/templates/env.yml.tpl" \
    "${project_base_dir}/downloads/kubespray/env.yml"

  echo_done
}

kubespray_predeploy_online() {

  am_i_root

  can_i_connect_to_internet

  backup_old_yum_repos
  configure_a_yum_repo \
    "CentOS-Base" "${online_centos_repo_url}"

  backup_old_pip_repos
  configure_a_pip_repo \
    "${online_pip_index_url}" "${online_pip_trusted_host}"

  check_ansible_if_is_existed

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
