#!/bin/bash
# 定义要压缩的目录
dir=/root/Docker

# 定义压缩后的文件名
filename=Docker$(date +%Y-%m-%d-%H).tar.gz

# 压缩目录
tar -czvf $filename $dir/*

# 输出压缩结果
echo "压缩完成，压缩文件名为 $filename"

mv /root/Docker*.tar.gz /root/Docker_bak
echo "成功上传OneDrive"

exit



