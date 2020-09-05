#!/usr/bin/env bash

set -e 

########################
# cd project working space
# Arguments:
#   None
# Returns:
#   None
#########################
change_directory_to_project_base_dir() {
  project_base_dir=$(dirname $(readlink -f $0))
  export project_base_dir="${project_base_dir}" && cd "${project_base_dir}"
}

change_directory_to_project_base_dir

# Load Fuctions
. "${project_base_dir}/library/libkubepd.sh"

########################
# Main function
# Arguments:
#   arg 1: command
# Returns:
#   None
#########################
main() {
  command=$1
  case "${command}" in
    "online")
      kubespray_predeploy_online
      ;;
    
    "offline")
      kubespray_predeploy_offline
      ;;

    "download")
      kubespray_predeploy_download
      ;;

    *)
      print_help_message
      ;;
  esac
}

main "$@"
