#!/bin/bash

# 进入目录并执行docker compose命令
function enter_and_execute() {
  cd $1
  docker-compose pull
  docker-compose up -d
}

# 需要进入的目录列表
DIRS=(
  "/root/Docker/AdguareHome/ADG1"
  "/root/Docker/AdguareHome/ADG2"
  "/root/Docker/E5_Renew"
  "/root/Docker/nginx-nav"
  "/root/Docker/nginx-sub"
  "/root/Docker/portainer"
)

# 循环进入目录并执行命令
for dir in ${DIRS[@]}; do
  enter_and_execute $dir
done

# 输出所有Docker容器已更新完成
echo "所有Docker容器已更新完成！"
