#!/usr/bin/evn bash
# Pull new k8s images from gcr.io, quay.io and docker.io, 
# and push them to registry.cn-hangzhou.aliuncs.com/cn_kubernetes.

docker_login() {
  docker login registry.cn-hangzhou.aliyuncs.com/cn_kubernetes \
    --username a15001003773 --password Harbor12345
}


pull_images() {


}

retag_and_push() {
  
}