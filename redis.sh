#!/usr/bin/env bash

set -e
DIR=$(realpath $0) && DIR=${DIR%/*}
cd $DIR
set -a
. ./nix/vps/disk/etc/kvrocks/conf.sh
REDISCLI_AUTH=$R_PASSWORD
set +a
set -x

$(bun ./sh/redis_master.js)
