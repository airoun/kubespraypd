[os-base]
name=centos base repository
baseurl=http://${local_repo_listen_addr}:${local_repo_listen_port}${local_yum_repo_uri}
enabled=1
gpgcheck=0