#!/bin/bash

# 清理缓存
sudo apt-get clean

# 清理已下载但未安装的软件包
sudo apt-get autoclean

# 清理旧的配置文件
sudo apt-get purge $(dpkg -l | grep "^rc" | awk '{print $2}')

# 清理无用的依赖项
sudo apt-get autoremove

# 清理临时文件
sudo rm -rf /tmp/*

# 清理用户缓存目录
for user in $(ls /home); do
  sudo rm -rf /home/$user/.cache/*
done

# 清理系统日志
sudo journalctl --vacuum-time=7d

# 清理用户日志
for user in $(ls /home); do
  sudo journalctl --vacuum-time=7d --user-unit=$user
done

# 清理旧的内核版本
sudo apt-get remove --purge $(dpkg -l 'linux-*' | sed '/^ii/!d;/'"$(uname -r | sed "s/\(.*\)-\([^0-9]\+\)/\1/")"'/d;s/^[^ ]* [^ ]* \([^ ]*\).*/\1/;/[0-9]/!d')

# 清理缓存目录
sudo rm -rf /var/cache/*

# 清理历史命令记录
history -c && history -w

sudo update-grub

sudo grub-install /dev/sda

# 完成
echo "所有硬盘垃圾已经清除完毕！"
