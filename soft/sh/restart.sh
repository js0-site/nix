#!/usr/bin/env bash

set -e
DIR=$(realpath $0) && DIR=${DIR%/*}
set -x

if [ -z "$2" ]; then
  cmd=restart
  srv="$1"
else
  cmd="$1"
  srv="$2"
fi

jq -r ".$srv[]" "${DIR%/*/*}/nix/vps/enable.json" | while read host; do
  # 避免 ssh 占用 read 的标准输入
  ssh $host "systemctl $cmd $srv || systemctl start $srv" </dev/null
done
