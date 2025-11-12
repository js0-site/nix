#!/usr/bin/env bash

DIR=$(realpath $0) && DIR=${DIR%/*}
echo $DIR
cd $DIR
set -e
set -a
CONF=$(dirname $DIR)/nix/vps/disk/etc/kvrocks
cd $CONF
. conf.sh
. sentinel.sh
set +a
set -x

send() {
  $DIR/sh/rsync.sh kvrocks $@
}

cd /tmp
if [ -d "nixos-kvrocks" ]; then
  cd nixos-kvrocks
  git pull
else
  git clone --depth=1 https://github.com/js0-dep/nixos-kvrocks.git
  cd nixos-kvrocks
fi

./build.sh
send result/bin/ /opt/bin

cd /tmp
CONF=kvrocks.conf
rm -rf $CONF

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
rconf "^workers .*" "workers $(nproc)"

send kvrocks.conf /etc/kvrocks
