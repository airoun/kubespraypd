#!/usr/bin/env bash

# Load Functions
. "${project_base_dir}/lib/liblog.sh"

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

  yum clean all &> /dev/null && rm -fr /var/cache/yum 
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
    mv ~/.pip/pip.conf ~/.pip/pip.conf.bak.$(date "+%F_%R:%S")
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