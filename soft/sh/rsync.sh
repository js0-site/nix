#!/usr/bin/env bash

set -e
if [ -z "$3" ]; then
  echo "$0 gruop(in ../nix/vps/enable.json) file dir"
  exit 1
fi
DIR=$(realpath $0) && DIR=${DIR%/*}
set -x

rsync="rsync -avz"

jq -r ".$1[]" "${DIR%/*/*}/nix/vps/enable.json" | while read host; do
  if [ "$host" != "$HOSTNAME" ]; then
    $rsync $2 $host:$3/
  else
    $rsync $2 $3/
  fi
done
