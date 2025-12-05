#!/usr/bin/env bash

set -e
DIR=$(realpath $0) && DIR=${DIR%/*}
set -a
. $(dirname $DIR)/nix/vps/disk/etc/kvrocks/conf.sh
set +a
set -x

NAME=$(basename $0) && NAME=${NAME%.*}

send() {
  $DIR/sh/rsync.sh $NAME $@
}

TMP=$(mktemp -d)
cleanup() {
  rm -rf $TMP
}
trap cleanup EXIT
mkdir -p $TMP/$NAME
cd $TMP/$NAME

CONF=$TMP/$NAME/$NAME.conf

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

DATA_DIR=/var/lib/kvrocks

rconf '^#?\s*log-dir .*' "log-dir stdout"
rconf '^#?\s*lua-strict-key-accessing no' 'lua-strict-key-accessing yes'
rconf '^#?\s*masterauth .*' "masterauth $R_PASSWORD"
rconf '^#?\s*requirepass .*' "requirepass $R_PASSWORD"
rconf '^#?\s*resp3-enabled\s.*' 'resp3-enabled yes'
rconf '^bind .*' 'bind 0.0.0.0'
rconf '^db-name .*' 'db-name db'
rconf '^dir .*' "dir $DATA_DIR"
rconf '^migrate-type .*' 'migrate-type raw-key-value'
rconf '^port .*' "port $R_PORT"
rconf '^enable-blob-cache .*' "enable-blob-cache yes"
rconf '^repl-namespace-enabled .*' 'repl-namespace-enabled yes'
rconf '^rocksdb.compression .*' 'rocksdb.compression zstd'
rconf '^rocksdb.enable_blob_files .*' 'rocksdb.enable_blob_files yes'
rconf '^rocksdb.read_options.async_io .*' 'rocksdb.read_options.async_io yes'
rconf '^supervised .*' 'supervised systemd'
rconf '^workers .*' "workers $(nproc)"

cd ..
id $NAME &>/dev/null && chown -R $NAME $NAME

$DIR/sh/rsync.sh $NAME $NAME /etc

cd $($DIR/sh/clone_or_pull.sh https://github.com/js0-dep/nixos-$NAME.git)

./build.sh
send result/bin/ /opt/bin
$DIR/sh/restart.sh $NAME
