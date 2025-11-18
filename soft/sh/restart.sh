#!/usr/bin/env bash

set -e
DIR=$(realpath $0) && DIR=${DIR%/*}
set -x

exec pssh -P -H \
  "$(jq -r ".ipv6_proxy|join(\" \")" $DIR/../../nix/vps/enable.json)" systemctl restart $1
