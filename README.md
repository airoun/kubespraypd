# kubespary predeploy
解决kubespray运行时环境依赖和K8S集群安装所需要的Docker安装包和K8S镜像，支持online和offline两种模式。
* online模式设置国内阿里云CentOS仓库、Docker仓库、PIP仓库，我们基于阿里云容器镜像服务提供了安装K8S集群所需的二进制和镜像。
* offline模式预先下载kubespray运行时环境依赖离线部署包，可以一键设置本地的CentOS仓库、Docker仓库、PIP仓库。我们提供了一个ansbile roles用于设置本地的docker registry。

## 准备
这里专门对offline模式进行下说明。
* 要有一个能够访问到gcr.io的节点，用于预先下载镜像。
* 执行下载操作的操作系统最好与要进行部署K8S集群的操作系统版本一致。

## 联网下载
修改配置文件`config`, 一切所需要的RPM和PIP包都是从`mirrors.aliyun.com`获取的.
```
downlaod_centos_iso_enabled="true"
donwload_centos_iso_url="https://mirrors.aliyun.com/centos-vault/7.5.1804/isos/x86_64/CentOS-7-x86_64-DVD-1804.iso"
download_pip_index_url="https://mirrors.aliyun.com/pypi/simple/"
download_pip_trusted_host="mirrors.aliyun.com"
donwload_yum_config_url_list="
https://mirrors.aliyun.com/repo/Centos-7.repo
http://mirrors.aliyun.com/repo/epel-7.repo
https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
"
```
`download_centos_iso_enabled`默认开启下载系统镜像, 用于制作内网YUM源. 如果已经有CentOS系统镜像, 只需要将`download_centos_iso_enabled`改为`false`, 然后将CentOS系统镜像Copy到`pkg/yum/`目录下.

接下来执行, 来获取所有部署包的离线包. 下载完成后, 整个localrepo项目即是离线部署包, 使用`TAR`打包即可.
```
[root@k8s1 localrepo]# ./localrepo.sh  download
 05:54:39.57 INFO  ==> *** Are you root? Yeah, I am ... ***
 05:54:39.61 INFO  ==> *** Connected to the internet ***
 05:54:39.62 INFO  ==> *** Backup old yum repos ***
 05:54:40.44 INFO  ==> *** Configuring internet Yum repo ***
 05:55:22.29 INFO  ==> *** Downloading Yum python3 packages ***
 05:55:23.83 INFO  ==> *** Downloading Yum nginx packages ***
 05:55:27.33 INFO  ==> *** Downloading Yum docker-ce packages ***
 05:55:31.57 INFO  ==> *** Backup old pip config ***
 05:55:31.57 INFO  ==> *** Configuring internet Pip repo ***
 05:55:31.58 INFO  ==> *** Installing python 3 ***
 05:55:36.78 INFO  ==> *** Downloading Pip packages ***
 05:55:50.28 INFO  ==> *** Downloading CentOS iso ***
 05:58:12.63 INFO  ==> *** Download Done ***
```

## 离线部署
将离线软件源部署包localrepo上传至服务器, 确认服务监听地址和端口以及离线包存放路径, 修改配置文件config. 
```
local_repo_home="/data/localrepo"
local_repo_listen_addr="192.168.158.128"
local_repo_listen_port="8001"
```
接下来执行, 来安装离线软件源
```
[root@k8s1 localrepo]# ./localrepo.sh install
 05:59:49.23 INFO  ==> *** Are you root? Yeah, I am ... ***
 06:00:47.83 INFO  ==> *** Backup old yum repos ***
 06:00:47.91 INFO  ==> *** Just wait a moment ***
 06:00:49.92 INFO  ==> *** Configuring local Yum repo ***
 06:00:51.21 INFO  ==> *** Backup old pip config ***
 06:00:51.21 INFO  ==> *** Configuring local Pip repo ***
 06:00:51.23 INFO  ==> *** Installing python 3 ***
 06:00:51.58 INFO  ==> *** Check SELinux is not disabled, disable it now. ***
 06:00:51.62 INFO  ==> *** Installing nginx ***
 06:00:59.80 INFO  ==> *** HTTP Service installed succeeded ***
 06:01:00.77 INFO  ==> *** Installing kubespary python requirements ***
 06:01:26.89 INFO  ==> *** Install Done ***
```
## 验证部署
查看kubespary依赖ansible版本
```
[root@k8s1 localrepo]# ansible --version
ansible 2.9.6
  config file = None
  configured module search path = ['/root/.ansible/plugins/modules', '/usr/share/ansible/plugins/modules']
  ansible python module location = /root/.local/lib/python3.6/site-packages/ansible
  executable location = /root/.local/bin/ansible
  python version = 3.6.8 (default, Apr  2 2020, 13:34:55) [GCC 4.8.5 20150623 (Red Hat 4.8.5-39)]
```
