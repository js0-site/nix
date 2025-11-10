#!/usr/bin/env bash

set -e
if [ -z "$1" ]; then
  echo "$0 path"
  exit 1
fi
DIR=$(realpath $0) && DIR=${DIR%/*}
cd $DIR
set -x

jq -r '.[]' "$(dirname $DIR)/nix/vps/host.json" | while read host; do
  if [ "$host" != "$HOSTNAME" ]; then
    rsync -avz $1 $host:$(dirname $1)
  fi
done
