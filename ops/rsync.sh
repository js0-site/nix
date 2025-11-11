#!/usr/bin/env bash

set -e
if [ -z "$2" ]; then
  echo "$0 enable_key path"
  exit 1
fi
DIR=$(realpath $0) && DIR=${DIR%/*}
cd $DIR
set -x

jq -r ".$1" "$(dirname $DIR)/nix/vps/enable.json" | while read host; do
  if [ "$host" != "$HOSTNAME" ]; then
    rsync -avz $1 $host:$(dirname $2)
  fi
done
