#!/usr/bin/env bash

DIR=$(realpath $0) && DIR=${DIR%/*}
cd $DIR
set -e
set -a
CONF=$(dirname $DIR)/nix/vps/disk/etc/kvrocks
cd $CONF
. conf.sh
. sentinel.sh
cd $DIR
set +a
set -x

CONF=$CONF/kvrocks.conf

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

# initdir() {
#   mkdir -p $1
#   chown -R kvrocks:kvrocks $1
# }

# LOG_DIR=/var/log/kvrocks
# initdir $LOG_DIR
#
# DATA_DIR=/data/kvrocks
# initdir $DATA_DIR

rconf '^rocksdb.compression .*' 'rocksdb.compression zstd'
rconf '^rocksdb.enable_blob_files .*' 'rocksdb.enable_blob_files yes'
rconf '^rocksdb.read_options.async_io .*' 'rocksdb.read_options.async_io yes'
rconf '^repl-namespace-enabled .*' 'repl-namespace-enabled yes'
rconf '^bind .*' 'bind 0.0.0.0'
rconf '^db-name .*' 'db-name db'
rconf '^supervised .*' 'supervised systemd'
rconf '^migrate-type .*' 'migrate-type raw-key-value'
rconf "^port .*" "port $R_PORT"
rconf "^dir .*" "dir $DATA_DIR"
rconf "^log-dir .*" "log-dir $LOG_DIR"

rconf '^#?\s*resp3-enabled\s.*' 'resp3-enabled yes'
rconf "^#?\s*requirepass .*" "requirepass $R_PASSWORD"

rconf "^#?\s*masterauth .*" "masterauth $R_PASSWORD"

# rconf "^workers .*" "workers $(nproc)"
# if ! ip addr show | awk '/inet / {print $2}' | cut -d'/' -f1 | grep -q "$R_MASTER_IP"; then
#   rconf "^#?\s*slaveof [^<].*" "slaveof $R_MASTER_IP $R_PORT"
# fi
