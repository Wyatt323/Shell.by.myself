#!/bin/bash

# 删除Nginx配置文件
rm -rf /etc/nginx/

# 删除Nginx安装文件
apt-get purge nginx nginx-common nginx-full nginx-core

# 删除Nginx日志文件和缓存
rm -rf /var/log/nginx/
rm -rf /var/cache/nginx/

# 删除Nginx用户
userdel -r nginx

echo "Nginx所有文件已被完全删除。"
