#!/bin/bash

# Cloudflare API相关信息
API_KEY="YOUR_Cloudflare_API_KEY "
EMAIL="YOUR_Cloudflare_EMAIL"
ZONE_ID="YOUR_Cloudflare_ZONE_ID"
RECORD_NAME="YOUR_Cloudflare_Domain"

# Ping结果保存文件路径
PING_FILE="/root/cf/ip.txt"

# 待PING的IP地址范围
START_IP="X.X.X.1"
END_IP="X.X.X.255"

# 数组变量用于存储可成功ping通的IP地址及其延迟
declare -A ping_results

# 获取当前域名指向的IP地址
ip_old=$(dig +short "$RECORD_NAME")

# ping当前域名指向的IP地址
echo "正在 Ping 目前域名指向的IP: $ip_old"
PING_RESULT=$(ping -c 1 -W 1 "$ip_old" | grep -oP "(?<=time=)[0-9]+" 2>/dev/null)

if [ -n "$PING_RESULT" ]; then
  echo "目前域名指向的IP可达，脚本结束运行"
  exit 0
else
  echo "目前域名指向的IP不可达，继续执行脚本"
fi

# 清空Ping结果文件
> "$PING_FILE"

# 循环Ping IP地址范围
for ((i=1; i<=50; i++))
do
  IP="$START_IP"
  echo "正在 Ping IP 地址: $IP"
  PING_RESULT=$(ping -c 1 -W 1 "$IP" | grep -oP "(?<=time=)[0-9]+" 2>/dev/null)
  
  if [ -n "$PING_RESULT" ]; then
    ping_results["$IP"]=$PING_RESULT
    echo "Ping 成功! 延迟: $PING_RESULT ms"
  else
    echo "Ping 失败"
  fi
  
  # IP地址递增
  IFS='.' read -ra OCTETS <<< "$START_IP"
  ((OCTETS[3]++))
  START_IP="${OCTETS[0]}.${OCTETS[1]}.${OCTETS[2]}.${OCTETS[3]}"
done

# 将Ping结果写入文件
for ip in "${!ping_results[@]}"; do
  echo "$ip ${ping_results[$ip]} ms" >> "$PING_FILE"
done

# 待解析的IP地址
IP_ADDRESS="$(sort -k2 -n "$PING_FILE" | head -n 1 | awk '{print $1}')"
echo "最低延迟IP:"$IP_ADDRESS""

# 获取记录ID
RECORD_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?type=A&name=$RECORD_NAME" \
    -H "X-Auth-Email: $EMAIL" \
    -H "X-Auth-Key: $API_KEY" \
    -H "Content-Type: application/json" | jq -r '.result[0].id')

if [ -z "$RECORD_ID" ]; then
  echo "找不到与域名 $RECORD_NAME 相关的DNS记录"
  exit 1
fi

# 更新记录的IP地址
RESPONSE=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$RECORD_ID" \
    -H "X-Auth-Email: $EMAIL" \
    -H "X-Auth-Key: $API_KEY" \
    -H "Content-Type: application/json" \
    --data "{\"type\":\"A\",\"name\":\"$RECORD_NAME\",\"content\":\"$IP_ADDRESS\"}")

# 检查响应状态
SUCCESS=$(echo "$RESPONSE" | jq -r '.success')

if [ "$SUCCESS" = "true" ]; then
  echo "IP地址更新成功"
else
  echo "IP地址更新失败"
fi
