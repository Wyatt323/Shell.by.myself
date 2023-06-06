#!/bin/bash

# Cloudflare API相关信息
API_KEY="YOUR_Cloudflare_API_KEY "
EMAIL="YOUR_Cloudflare_EMAIL"
ZONE_ID="YOUR_Cloudflare_ZONE_ID"
RECORD_NAME="YOUR_Cloudflare_Domain"

TELEGRAM_BOT_TOKEN="YOUR_BOT_TOKEN"
TELEGRAM_CHAT_ID="YOUR_CHAT_ID"
TELEGRAM_ENABLED="1"

TZ='Asia/Shanghai'
now_time=$(date +'%Y-%m-%d %H:%M:%S')

# Ping结果保存文件路径
PING_FILE="/root/cf/ip.txt"

# 待PING的IP地址范围
START_IP="X.X.X.1"
END_IP="X.X.X.252"

# 数组变量用于存储可成功ping通的IP地址及其延迟
declare -A ping_results

# 获取当前域名指向的IP地址
ip_old=$(host "$RECORD_NAME" | awk '/has address/ { print $4 }')

# ping当前域名指向的IP地址
echo "正在 Ping 目前域名指向的IP: $ip_old"
PING_RESULT=$(ping -c 1 -W 1 "$ip_old" | grep -oP "(?<=time=)[0-9]+" 2>/dev/null)

if [ -n "$PING_RESULT" ]; then
  echo "目前域名指向的IP可达，脚本结束运行"
  # 是否启用通知
   if [[ "$TELEGRAM_ENABLED" == "1" ]]; then
     echo "Telegram通知已启用"
      # 发送Telegram通知。
       message="$now_time"
       message+=" %0A 🎉目前$RECORD_NAME指向的IP:$ip_old可达 "
       telegram_url="https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage?chat_id=$TELEGRAM_CHAT_ID&text=$message"
       curl -s "$telegram_url" >/dev/null
   else
     echo "Telegram通知未启用"
   fi
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
IP_ADDRESS=$(sort -k2 -n "$PING_FILE" | awk 'NR==1{print $1}')
echo "最低延迟IP: $IP_ADDRESS"

# 获取记录ID
RECORD_INFO=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?type=A&name=$RECORD_NAME" \
    -H "X-Auth-Email: $EMAIL" \
    -H "X-Auth-Key: $API_KEY" \
    -H "Content-Type: application/json")

RECORD_ID=""
if [[ "$RECORD_INFO" == *"\"id\":\""* ]]; then
  RECORD_ID=$(echo "$RECORD_INFO" | grep -oP "\"id\":\"\\K[^\"]+")
fi

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
SUCCESS=$(echo "$RESPONSE" | grep -oP "\"success\":\\K[^,]+")

if [ "$SUCCESS" = "true" ]; then
  echo "IP地址更新成功"
  # 是否启用通知
    if [[ "$TELEGRAM_ENABLED" == "1" ]]; then
      echo "Telegram通知已启用"
       # 发送Telegram通知。
        message="$now_time"
        message+="🎉目前$RECORD_NAME指向的IP:$ip_old不可达"
        message+="已经将新的IP:$IP_ADDRESS解析到该域名中"
        telegram_url="https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage?chat_id=$TELEGRAM_CHAT_ID&text=$message"
        curl -s "$telegram_url" >/dev/null
    else
      echo "Telegram通知未启用"
    fi
else
  echo "IP地址更新失败"
fi

