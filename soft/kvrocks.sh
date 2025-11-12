#!/usr/bin/env bash

set -e
DIR=$(realpath $0) && DIR=${DIR%/*}
set -a
CONF=$(dirname $DIR)/nix/vps/disk/etc/kvrocks
cd $CONF
. conf.sh
. sentinel.sh
set +a
set -x

NAME=$(basename $0) && NAME=${NAME%.*}

send() {
  $DIR/sh/rsync.sh $NAME $@
}

cd /tmp
CONF=kvrocks.conf

curl https://raw.githubusercontent.com/apache/kvrocks/refs/heads/unstable/kvrocks.conf -o $CONF

rconf() {
  sd "$1" "$2" $CONF
}

disable_cmd() {
  for cmd in "$@"; do
    grep -q "^\s*rename-command $cmd " $CONF || echo -e "\nrename-command $cmd \"\"\n" >>$CONF
  done
}

disable_cmd FLUSHDB FLUSHALL

LOG_DIR=/var/log/kvrocks
DATA_DIR=/var/lib/kvrocks

rconf '^#?\s*log-dir .*' "log-dir $LOG_DIR"
rconf '^#?\s*lua-strict-key-accessing no' 'lua-strict-key-accessing yes'
rconf '^#?\s*masterauth .*' "masterauth $R_PASSWORD"
rconf '^#?\s*requirepass .*' "requirepass $R_PASSWORD"
rconf '^#?\s*resp3-enabled\s.*' 'resp3-enabled yes'
rconf '^bind .*' 'bind 0.0.0.0'
rconf '^db-name .*' 'db-name db'
rconf '^dir .*' "dir $DATA_DIR"
rconf '^migrate-type .*' 'migrate-type raw-key-value'
rconf '^port .*' "port $R_PORT"
rconf '^repl-namespace-enabled .*' 'repl-namespace-enabled yes'
rconf '^rocksdb.compression .*' 'rocksdb.compression zstd'
rconf '^rocksdb.enable_blob_files .*' 'rocksdb.enable_blob_files yes'
rconf '^rocksdb.read_options.async_io .*' 'rocksdb.read_options.async_io yes'
rconf '^supervised .*' 'supervised systemd'
rconf '^workers .*' "workers $(nproc)"

send $NAME.conf /etc/$NAME

cd $($DIR/clone_or_pull.sh https://github.com/js0-dep/nixos-kvrocks.git)

./build.sh
send result/bin/ /opt/bin
