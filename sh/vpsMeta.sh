#!/usr/bin/env bash

set -e

HOST=$1
ARCH=$(uname -m)
DISK=$(lsblk -d -n -o NAME -e 7 | head -n 1)
FIRMWARE=BIOS
# FIRMWARE=$([ -d /sys/firmware/efi/efivars ] && echo UEFI || echo BIOS)

# 获取网络接口信息（排除回环接口）
INTERFACE=$(ip link show | awk -F': ' '/^[0-9]+: [a-zA-Z0-9]+:.*UP.*LOWER_UP/ && !/lo:/ {print $2; exit}')

ipAddr() {
  local ip_version=$1
  local ip_filter=$2

  if [ -n "$INTERFACE" ] && ip addr show "$INTERFACE" | grep -q "$ip_version "; then
    if [ -n "$ip_filter" ]; then
      ip addr show "$INTERFACE" | grep "$ip_version " | grep -v "$ip_filter" | awk '{print $2}' | head -n 1
    else
      ip addr show "$INTERFACE" | grep "$ip_version " | awk '{print $2}' | head -n 1
    fi
  fi
}

get_gateway() {
  ip $@ route | grep default | awk '{print $3}' | head -n 1
}

cat <<EOF
system = "$(case "$ARCH" in
  "x86_64") echo "x86_64-linux" ;;
  "aarch64") echo "aarch64-linux" ;;
  *) echo "unknown" ;;
  esac)";
disk = "/dev/${DISK}";
firmware = "${FIRMWARE}";
virt = "$(systemd-detect-virt)";
interface = "${INTERFACE}";
EOF

if [ -n "$INTERFACE" ] && ip addr show "$INTERFACE" | grep "inet " | grep -q "dynamic"; then
  cat <<EOF
ip = 0;
EOF
else
  IPV4_ADDR=$(ipAddr inet)
  IPV4_GATEWAY=$(get_gateway)
  cat <<EOF
ip = {
  v4 = {
    addr = "${IPV4_ADDR}";
    gateway = "${IPV4_GATEWAY}";
  };
EOF
  IPV6_ADDR=$(ipAddr inet6 "fe80::")
  if [ -n "$IPV6_ADDR" ]; then
    # 支持整个网段
    IPV6_ADDR=$(echo $IPV6_ADDR | sed 's/::1\//::\//')
    IPV6_GATEWAY=$(get_gateway -6)
    cat <<EOF
  v6 = {
    addr = "${IPV6_ADDR}";
    gateway = "${IPV6_GATEWAY}";
  };
EOF
  fi
  echo "};"
fi

cat <<EOF
$(grep -m 1 '[^[:space:]]' /etc/issue)
EOF
