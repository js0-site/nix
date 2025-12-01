#!/usr/bin/env bash

set -e
DIR=$(realpath $0) && DIR=${DIR%/*}
set -x

jq -r ".$1[]" "${DIR%/*/*}/nix/vps/enable.json" | while read host; do
  # 避免 ssh 占用 read 的标准输入
  ssh $host "systemctl restart $1" </dev/null
done
