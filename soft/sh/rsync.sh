#!/usr/bin/env bash

set -e
if [ -z "$3" ]; then
  echo "$0 gruop(in ../nix/vps/enable.json) file dir"
  exit 1
fi
DIR=$(realpath $0) && DIR=${DIR%/*}
set -x

srv=$1
name=$2
to=$3

shift 3

rsync="rsync -avz $@ $name"

jq -r ".$srv[]" "${DIR%/*/*}/nix/vps/enable.json" | while read host; do
  if [ "$host" != "$HOSTNAME" ]; then
    $rsync $host:$to/
  else
    $rsync $to/
  fi
done
