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
  project_base_dir=$(dirname $(readlink -f $0)
  export project_base_dir="${project_base_dir}" && cd "${project_base_dir}"
}

change_directory_to_project_base_dir

# Load Fuctions
. "${project_base_dir}/library/lib.sh"
. "${project_base_dir}/library/libkubepdpl_online.sh"
. "${project_base_dir}/library/libkubepdpl_offline.sh"

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
      pdpl_online
      ;;
    
    "offline")
      pdpl_offline
      ;;

    "download")
      pdpl_download
      ;;

    *)
      print_help_message
      ;;
  esac
}

main "$@"
