# kubespary predeploy
解决离线安装Kubernetes集群所需要的依赖，设置安装工具kubespray运行环境。

## 环境准备
运行kubespraypd的环境
* 首先要有一个hk节点用作下载机器
* 下载机器与要部署的目标机器的系统版本要一致
* CentOS 7.5+

## 开始工作
在下kubespraypd代码
```Shellsession
git clone https://github.com/potato210402/kubespraypd.git
```

### 获取离线包
修改配置文件`config`，下载机需要自己对自己做免密登陆。
```Shellsession
download_server_hostname=hk-01    # 下载机的主机名
download_server_ipaddress=192.168.101.12 # 下载机的ip地址
download_centos_isos_enable=false
```

下载所需要的rpm软件包，python软件包和k8s镜像。下载完成后会提示`congratulations`，所有下载都存放在`downloads`目录下。
```Shellsession
cd kubespraypd/
chmod +x kubespraypd
./kubespraypd download
```
然后将项目整体打包，输出一个离线部署包。
```Shellsession
tar cvf kubespraypd_offline.tar kubespraypd/
```

### 私有化软件源
将离线部署包上传至客户环境，解压缩。
```Shellsession
tar xvf kubespraypd_offline.tar
cd kubespraypd/ 
```
修改配置文件`config`，设置ansible controller的主机信息和数据存放位置。
```Shellsession
offline_server_host=192.168.101.12    # ansible controller的ip
offline_server_http_repo_port=32080    # http repo监听端口
offline_server_docker_registry_port=5000    # docker registry 监听端口
offline_server_docker_registry_data=/data/registry    # docker registry数据存放位置
offline_server_docker_data_root=/data/var/lib/docker  # docker 的data root，要和kubespray安装时指定的docker data root 一致
external_centos_base_repo_enable=false    # 是否使用外部的centos base repo，内部默认是"${project_base_dir}/downloads/centos"
external_centos_base_repo_url="http://192.168.101.12:8001/centos/Packages"
```
设置离线yum源，pip源和镜像源。
```Shellsession
./kubespraypd setup
```

### 在线软件源
使用我在互联网上公布的源作为软件源，配置文件不需要更改。
```Shellsession
./kubespraypd setup
```

