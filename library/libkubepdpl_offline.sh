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
pdpl_download() {

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