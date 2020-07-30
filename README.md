# kubespary predeploy
解决kubespray运行时环境依赖和K8S集群安装所需要的Docker安装包和K8S镜像，支持online和offline两种模式。
* online模式设置国内阿里云CentOS仓库、Docker仓库、PIP仓库，我们基于阿里云容器镜像服务提供了安装K8S集群所需的二进制和镜像。
* offline模式预先下载kubespray运行时环境依赖离线部署包，可以一键设置本地的CentOS仓库、Docker仓库、PIP仓库。我们提供了一个ansbile roles用于设置本地的docker registry。

## 准备
这里专门对offline模式进行下说明。
* 要有一个能够访问到gcr.io的节点，用于预先下载镜像。
* 执行下载操作的操作系统最好与要进行部署K8S集群的操作系统版本一致。

