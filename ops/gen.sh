#!/usr/bin/env bash

set -e
DIR=$(realpath $0) && DIR=${DIR%/*}
cd $DIR
set -x
cd ../nix/vps
IP_LI=$(jq -r 'keys | join(" ")' host.json)

cd disk/etc
echo "IPV6_PROXY_HOST_LI='$IP_LI'" >ipv6_proxy.host_li.env
echo "KVROCKS_IP_LI='$IP_LI'" >kvrocks/ip_li.env
git add .
$DIR/kvrocks.conf.sh
